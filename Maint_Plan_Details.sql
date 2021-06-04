
declare @job_name varchar(1000) = 'DB BACKUP.FULL BACKUP'
declare @pid varchar (1000) = ''-- '23D6F9E8-8F4D-4426-95E8-15EB39C67FC9'
declare @spid varchar(1000) = '' --'6C3A4E84-0669-4BE1-A6E7-68D2B45672E9'
declare @pkg xml

select @spid = ss.subplan_id, @pid = ss.plan_id --,ss.subplan_name 
from msdb.dbo.sysmaintplan_subplans ss
join msdb.dbo.sysjobs jobs on jobs.job_id = ss.job_id
where jobs.name = @job_name


SELECT @pkg = CAST(CAST(a.[packagedata] as varbinary(max)) as xml) 
FROM msdb.dbo.sysssispackages  a
WHERE id = @pid

select @pkg = cast(replace(replace(cast(@pkg as nvarchar(MAX)),'DTS:',''),'SQLTask:','') as xml) 


declare @XQuery varchar(1000) =
'/Executable/Executables/Executable[@DTSID="{'+@spid+'}"]/Executables/Executable[fn:contains(@CreationName,"DbMaintenanceBackupTask")]/ObjectData/SqlTaskData';
declare @XQuery_Clean varchar(1000) =
'/Executable/Executables/Executable[@DTSID="{'+@spid+'}"]/Executables/Executable[fn:contains(@CreationName,"DbMaintenanceFileCleanupTask")]/ObjectData/SqlTaskData';
print @XQuery

declare @SQL NVARCHAR(MAX) =  'select @pkg
.query('''+@XQuery+''')
.value(
''(/SqlTaskData/@BackupDestinationAutoFolderPath)[1]''
,''varchar(max)''
) as BackupDestinationAutoFolderPath
,@pkg
.query('''+@XQuery+''')
.value(
''(/SqlTaskData/@RetainDays)[1]''
,''varchar(max)''
) as RetainDays
,(select STUFF(a.a.query(''/abc'').value(''/'',''varchar(max)'') , 1, 2, '''') as abc
from (
select (
select '', ''+abc as abc
from (
select X.Y.query(''.'').value(''(/SelectedDatabases/@DatabaseName)[1]'',''varchar(MAX)'') as abc
from @pkg.nodes('''+@XQuery+'/SelectedDatabases'') as X(Y)
) a for xml path (''''), type) a ) a) as DB_Names'
+',
@pkg
.query('''+@XQuery+''')
.value(
''(/SqlTaskData/@DatabaseSelectionType)[1]''
,''varchar(max)''
) as DatabaseSelectionType
,
@pkg
.query('''+@XQuery_Clean+''')
.value(
''(/SqlTaskData/@RemoveOlderThan)[1]''
,''varchar(max)''
) as RemoveOlderThan
'


print @SQL

if (object_id('tempdb..#Tmp_maint_plan') is not null)
 drop table #Tmp_maint_plan

create table #Tmp_maint_plan (BackupDestinationAutoFolderPath varchar(1000), RetainDays varchar(10), DB_Names varchar(MAX), DatabaseSelectionType varchar(10), RemoveOlderThan varchar(10))

insert into #Tmp_maint_plan
EXEC sp_executesql @SQL, N'@pkg xml', @pkg


select 
BackupDestinationAutoFolderPath,
case DatabaseSelectionType 
	when 4 
	then DB_Names
	when 1
		then 'ALL_DATABASES'
	when 2
		then 'SYS_DATABASES'
	when 3
		then 'USER_DATABASES'
	else ''
	END DB_Names,
ISNULL(RemoveOlderThan,RetainDays) RemoveOlderThan
from #Tmp_maint_plan



