if (object_id('tempdb..#jobDetails') is not null)
 drop table #jobDetails

;with JobMain as (
select 
jobs.job_id,
jobs.JobName, 
case when jobs.IsEnabled=1 then 'YES' ELSE 'NO' END Enabled,
jobs.Occurrence + ' - ' + isnull(jobs.Recurrence,'') + ' - ' + isnull(jobs.Frequency,'') as Schedule,
jobs.LastRunDateTime,
jobs.[LastRunDuration (HH:MM:SS)],
jobs.LastRunStatus,
jobs.NextRunDateTime,
jobs.EmailAddress
from (
SELECT 
     [sJOB].[name] AS [JobName],sjob.job_id
	 ,l.name as Woner
	 ,[sJOB].enabled IsEnabled
	 , ISNULL([sJOBSCH].Occurrence,'No Schedule Found') Occurrence
	  ,[sJOBSCH].Recurrence
	  ,[sJOBSCH].Frequency
	  , CASE 
        WHEN [sJOBH].[run_date] IS NULL OR [sJOBH].[run_time] IS NULL THEN NULL
        ELSE CAST(
                CAST([sJOBH].[run_date] AS CHAR(8))
                + ' ' 
                + STUFF(
                    STUFF(RIGHT('000000' + CAST([sJOBH].[run_time] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                    , 6, 0, ':')
                AS DATETIME)
      END AS [LastRunDateTime]
    , STUFF(
            STUFF(RIGHT('000000' + CAST([sJOBH].[run_duration] AS VARCHAR(6)),  6)
                , 3, 0, ':')
            , 6, 0, ':') 
        AS [LastRunDuration (HH:MM:SS)]
	, case sJOBH.run_status
	 when 0 then 'Failed'
	 when 1 then 'Succeeded'
	 when 2 then 'Retry'
	 when 3 then 'Canceled'
	 when 4 then 'In Progress'
	 else 'Unknown' end
	  AS [LastRunStatus]
    , CASE [sJOBSCH].[NextRunDate]
        WHEN 0 THEN NULL
        ELSE CAST(
                CAST([sJOBSCH].[NextRunDate] AS CHAR(8))
                + ' ' 
                + STUFF(
                    STUFF(RIGHT('000000' + CAST([sJOBSCH].[NextRunTime] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                    , 6, 0, ':')
                AS DATETIME)
      END AS [NextRunDateTime] 
	  ,o.name EmailOperatorName,o.email_address EmailAddress
FROM 
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN (
                SELECT 
    [schedule_uid] AS [ScheduleID]
    , [name] AS [ScheduleName]
    , CASE [enabled]
        WHEN 1 THEN 'Yes'
        WHEN 0 THEN 'No'
      END AS [IsEnabled]
    , CASE 
        WHEN [freq_type] = 64 THEN 'Start automatically when SQL Server Agent starts'
        WHEN [freq_type] = 128 THEN 'Start whenever the CPUs become idle'
        WHEN [freq_type] IN (4,8,16,32) THEN 'Recurring'
        WHEN [freq_type] = 1 THEN 'One Time'
      END [ScheduleType]
    , CASE [freq_type]
        WHEN 1 THEN 'One Time'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly - Relative to Frequency Interval'
        WHEN 64 THEN 'Start automatically when SQL Server Agent starts'
        WHEN 128 THEN 'Start whenever the CPUs become idle'
      END [Occurrence]
    , CASE [freq_type]
        WHEN 4 THEN 'Occurs every ' + CAST([freq_interval] AS VARCHAR(3)) + ' day(s)'
        WHEN 8 THEN 'Occurs every ' + CAST([freq_recurrence_factor] AS VARCHAR(3)) 
                    + ' week(s) on '
                    + CASE WHEN [freq_interval] & 1 = 1 THEN 'Sunday' ELSE '' END
                    + CASE WHEN [freq_interval] & 2 = 2 THEN ', Monday' ELSE '' END
                    + CASE WHEN [freq_interval] & 4 = 4 THEN ', Tuesday' ELSE '' END
                    + CASE WHEN [freq_interval] & 8 = 8 THEN ', Wednesday' ELSE '' END
                    + CASE WHEN [freq_interval] & 16 = 16 THEN ', Thursday' ELSE '' END
                    + CASE WHEN [freq_interval] & 32 = 32 THEN ', Friday' ELSE '' END
                    + CASE WHEN [freq_interval] & 64 = 64 THEN ', Saturday' ELSE '' END
        WHEN 16 THEN 'Occurs on Day ' + CAST([freq_interval] AS VARCHAR(3)) 
                     + ' of every '
                     + CAST([freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
        WHEN 32 THEN 'Occurs on '
                     + CASE [freq_relative_interval]
                        WHEN 1 THEN 'First'
                        WHEN 2 THEN 'Second'
                        WHEN 4 THEN 'Third'
                        WHEN 8 THEN 'Fourth'
                        WHEN 16 THEN 'Last'
                       END
                     + ' ' 
                     + CASE [freq_interval]
                        WHEN 1 THEN 'Sunday'
                        WHEN 2 THEN 'Monday'
                        WHEN 3 THEN 'Tuesday'
                        WHEN 4 THEN 'Wednesday'
                        WHEN 5 THEN 'Thursday'
                        WHEN 6 THEN 'Friday'
                        WHEN 7 THEN 'Saturday'
                        WHEN 8 THEN 'Day'
                        WHEN 9 THEN 'Weekday'
                        WHEN 10 THEN 'Weekend day'
                       END
                     + ' of every ' + CAST([freq_recurrence_factor] AS VARCHAR(3)) 
                     + ' month(s)'
      END AS [Recurrence]
    , CASE [freq_subday_type]
        WHEN 1 THEN 'Occurs once at ' 
                    + STUFF(
                 STUFF(RIGHT('000000' + CAST([active_start_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
        WHEN 2 THEN 'Occurs every ' 
                    + CAST([freq_subday_interval] AS VARCHAR(3)) + ' Second(s) between ' 
                    + STUFF(
                   STUFF(RIGHT('000000' + CAST([active_start_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
                    + ' & ' 
                    + STUFF(
                    STUFF(RIGHT('000000' + CAST([active_end_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
        WHEN 4 THEN 'Occurs every ' 
                    + CAST([freq_subday_interval] AS VARCHAR(3)) + ' Minute(s) between ' 
                    + STUFF(
                   STUFF(RIGHT('000000' + CAST([active_start_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
                    + ' & ' 
                    + STUFF(
                    STUFF(RIGHT('000000' + CAST([active_end_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
        WHEN 8 THEN 'Occurs every ' 
                    + CAST([freq_subday_interval] AS VARCHAR(3)) + ' Hour(s) between ' 
                    + STUFF(
                    STUFF(RIGHT('000000' + CAST([active_start_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
                    + ' & ' 
                    + STUFF(
                    STUFF(RIGHT('000000' + CAST([active_end_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
      END [Frequency]
    , STUFF(
            STUFF(CAST([active_start_date] AS VARCHAR(8)), 5, 0, '-')
                , 8, 0, '-') AS [ScheduleUsageStartDate]
    , STUFF(
            STUFF(CAST([active_end_date] AS VARCHAR(8)), 5, 0, '-')
                , 8, 0, '-') AS [ScheduleUsageEndDate]
    , [date_created] AS [ScheduleCreatedOn]
    , [date_modified] AS [ScheduleLastModifiedOn]
	, b.job_id
	,b.next_run_date [NextRunDate]
	,b.next_run_time [NextRunTime]
FROM [msdb].[dbo].[sysschedules] a
inner join [msdb].[dbo].[sysjobschedules] b
 on a.schedule_id = b.schedule_id
 where a.enabled = 1
            ) AS [sJOBSCH]
        ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN (
                SELECT 
                    [job_id]
                    , [run_date]
                    , [run_time]
                    , [run_status]
                    , [run_duration]
                    , [message]
                    , ROW_NUMBER() OVER (
                                            PARTITION BY [job_id] 
                                            ORDER BY [run_date] DESC, [run_time] DESC
                      ) AS RowNumber
                FROM [msdb].[dbo].[sysjobhistory]
                WHERE [step_id] = 0
            ) AS [sJOBH]
        ON [sJOB].[job_id] = [sJOBH].[job_id]
        AND [sJOBH].[RowNumber] = 1
	left join master.sys.syslogins l on sJOB.owner_sid = l.sid
	 left join msdb..sysoperators o on [sJOB].notify_email_operator_id = o.id
where sJOB.name in (select s.name--,l.name--,s.enabled
 from  msdb..sysjobs s 
 left join master.sys.syslogins l on s.owner_sid = l.sid
 )
) jobs
where (jobs.JobName like '%DatabaseBackup%' OR
jobs.JobName like '%full%' OR jobs.JobName like '%diff%' OR jobs.JobName like '%log%' OR jobs.JobName like '%bak%' OR jobs.JobName like '%Backup%')
and  jobs.JobName not like '%delete%' and jobs.JobName not like '%update%' and jobs.JobName not like '%stats%' and jobs.JobName not like '%Recycle%'
 and jobs.JobName not like '%Cleanup%' and jobs.JobName not like '%Monitor%' and jobs.JobName not like '%purge%' and jobs.JobName not like '%logins%' 
 and jobs.JobName not like '%shrink%'  and jobs.JobName not like '%error%' and jobs.JobName not like '%sync%'
 )
 ,jobdetails as (
select 
jsch.JobName, jstep.bak_typr,
jsch.Enabled,
jsch.Schedule,
jsch.LastRunDateTime,
jsch.[LastRunDuration (HH:MM:SS)],
jsch.LastRunStatus,
jsch.NextRunDateTime,
jsch.EmailAddress,
jstep.[Backup Method],
jstep.Retention as [Retention] ,
jstep.BAK_Location,
jstep.[Databases],
jstep.command as Step_Command
from JobMain jsch
left join (
select sJOB.job_id, name, case when name like '%full%' then 'FULL'  when name like '%diff%' then 'DIFF'  when name like '%log%' then 'LOG' when name like '%tran%' then 'LOG'  when name like '%trn%' then 'LOG' when name like '%sysdb%' then 'FULL' else 'FULL' end as bak_typr,
command,
case when command like '%SmsqlJobLauncher%' then 'SMSQL' 
	when jstep.subsystem = 'SSIS' then 'Maint.Plan'
	when command like '%execute%' or command like '%backup%'  then 'SQL Native'  
	else 'NOT-FOUND' end as [Backup Method]
	,case 
	when command like '%execute%' and command like '%@CleanupTime%'
		then left(right(command, len(command) - CHARINDEX('@CleanupTime',command)) , 
					CASE
						WHEN CHARINDEX('@',right(command, len(command) - CHARINDEX('@CleanupTime',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX('@CleanupTime',command))) + 1
							ELSE 
								CHARINDEX('@',right(command, len(command) - CHARINDEX('@CleanupTime',command)))
						END - 1
				)
	when command like '%SmsqlJobLauncher%' and command like '% -RetainBackupDays %'
		then left(right(command, len(command) - CHARINDEX(' -RetainBackupDays',command)) , 
					CASE
						WHEN CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -RetainBackupDays',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX(' -RetainBackupDays',command))) + 1
							ELSE 
								CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -RetainBackupDays',command)))
						END - 1
				)
	else 'NOT-FOUND' end as [Retention] 
	,case 
	when command like '%execute%' and command like '%@Directory%'
		then left(right(command, len(command) - CHARINDEX('@Directory',command)) , 
					CASE
						WHEN CHARINDEX('@',right(command, len(command) - CHARINDEX('@Directory',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX('@Directory',command))) + 1
							ELSE 
								CHARINDEX('@',right(command, len(command) - CHARINDEX('@Directory',command)))
						END - 1
				)
	when command like '%SmsqlJobLauncher%' and command like '%mpdir%'
		then left(right(command, len(command) - CHARINDEX('mpdir',command)) , 
					CASE
						WHEN CHARINDEX(' -',right(command, len(command) - CHARINDEX('mpdir',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX('mpdir',command))) + 1
							ELSE 
								CHARINDEX(' -',right(command, len(command) - CHARINDEX('mpdir',command)))
						END - 1
				)
	else 'NOT-FOUND' END as BAK_Location
	,case 
	when command like '%execute%' and command like '%@Databases%'
		then left(right(command, len(command) - CHARINDEX('@Databases',command)) , 
					CASE
						WHEN CHARINDEX('@',right(command, len(command) - CHARINDEX('@Databases',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX('@Databases',command))) + 1
							ELSE 
								CHARINDEX('@',right(command, len(command) - CHARINDEX('@Databases',command)))
						END - 1
				)
	when command like '%SmsqlJobLauncher%' and command like '% -d %'
		then left(right(command, len(command) - CHARINDEX(' -d',command)) , 
					CASE
						WHEN CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -d',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX(' -d',command))) + 1
							ELSE 
								CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -d',command)))
						END - 1
				)
	when command like '%SmsqlJobLauncher%' and command like '% -ag %'
		then left(right(command, len(command) - CHARINDEX(' -ag',command)) , 
					CASE
						WHEN CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -ag',command))) = 0
							THEN
								len(right(command, len(command) - CHARINDEX(' -ag',command))) + 1
							ELSE 
								CHARINDEX(' -',right(command, len(command) - CHARINDEX(' -ag',command)))
						END - 1
				)
	else 'NOT-FOUND' end as [Databases]
from msdb.dbo.sysjobs sJOB
join ( select job_id	,step_id	,step_name	,subsystem	,ltrim(rtrim(command))	as command,flags	,additional_parameters	,cmdexec_success_code	,on_success_action	,on_success_step_id	,on_fail_action	,on_fail_step_id	,server	,database_name	,database_user_name	,retry_attempts	,retry_interval	,os_run_priority	,output_file_name	,last_run_outcome	,last_run_duration	,last_run_retries	,last_run_date	,last_run_time	,proxy_id	,step_uid from  msdb.dbo.sysjobsteps ) jstep on sJOB.job_id = jstep.job_id
where sJOB.enabled = 1 and
 ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%tran%' OR [sJOB].name like '%trn%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%' and [sJOB].name not like '%Recycle%'
 and [sJOB].name not like '%Cleanup%' and [sJOB].name not like '%Monitor%' and [sJOB].name not like '%purge%' and [sJOB].name not like '%logins%' 
 and [sJOB].name not like '%shrink%'  and [sJOB].name not like '%error%') jstep on jstep.job_id =jsch.job_id
 )
 select * 
 into #jobDetails
 from jobdetails j
 --where j.Enabled = 'YES'
	--and j.Schedule not like '%No Schedule Found%'

declare @v_job_name varchar (1000) =''

declare C_jobDetails cursor for	
	select jd.JobName  from #jobDetails jd
	where jd.[Backup Method] = 'Maint.Plan'

open c_jobdetails
FETCH NEXT FROM c_jobdetails   
INTO @v_job_name

while @@FETCH_STATUS = 0
begin

declare @BackupDestinationAutoFolderPath varchar(1000), @RetainDays varchar(10), @DB_Names varchar(MAX)

--------------------------------------------------------------------------------

declare @job_name varchar(1000) = @v_job_name -- 'DB BACKUP.TRANS BACKUP'
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
@BackupDestinationAutoFolderPath = BackupDestinationAutoFolderPath,
@DB_Names = case DatabaseSelectionType 
	when 4 
	then DB_Names
	when 1
		then 'ALL_DATABASES'
	when 2
		then 'SYSTEM_DATABASES'
	when 3
		then 'USER_DATABASES'
	else ''
	END ,
@RetainDays = ISNULL(RemoveOlderThan,RetainDays)
from #Tmp_maint_plan

-----------------------------------------------------------------

update #jobDetails
set Retention = @RetainDays + ' Days',
	BAK_Location = @BackupDestinationAutoFolderPath,
	Databases = @DB_Names
where JobName = @v_job_name;

FETCH NEXT FROM c_jobdetails   
INTO @v_job_name
end

CLOSE c_jobdetails;  
DEALLOCATE c_jobdetails;  

select jd.*  from #jobDetails jd
