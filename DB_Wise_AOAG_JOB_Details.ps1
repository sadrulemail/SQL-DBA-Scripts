
$DomainName = 'WCG'
#$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
$ActiveServers = ("DB03VDCA.wcgclinical.com")#,"DB02VDCA.wcgclinical.com","DB01VDCA.wcgclinical.com","DB18VDCA.wcgclinical.com","db17vwfc.wcgclinical.com","DB19VDCA.wcgclinical.com","db01vwfc.wcgclinical.com","WCGLC01VL.wcgclinical.com","dce-t-twdb01.wcgclinical.com","DCA-T-APP02.wcgclinical.com","SEADWDCMDB01.wcgclinical.com","SEAQWDCMDB01.wcgclinical.com","SEAQWDCMDB02.wcgclinical.com","SEAQWDCMCL01.wcgclinical.com","SEAQWDCMLN.wcgclinical.com","SEAQWIRSDB02.wcgclinical.com","SEAQWIRSDB01.wcgclinical.com","SEAQWIRSCL01.wcgclinical.com","PHLDWACIDB01.wcgclinical.com","SEAQWIRSLN.wcgclinical.com","SEANWDCMDB01.wcgclinical.com","SEANWIRSDB01.wcgclinical.com","SEAVWIRSDB01.wcgclinical.com","PHLDWWCGDB04.wcgclinical.com")

$SQL = "with JobMain as (
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
	-- , [sJOBSCH].Occurrence  +'-'+isnull([sJOBSCH].Recurrence,'')+'-'+isnull([sJOBSCH].Frequency,'') as [Backup Schedules]
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
-- where s.enabled = 1
 )
--ORDER BY [JobName]
) jobs
where (jobs.JobName like '%DatabaseBackup%' OR
jobs.JobName like '%full%' OR jobs.JobName like '%diff%' OR jobs.JobName like '%log%' OR jobs.JobName like '%bak%' OR jobs.JobName like '%Backup%')
and  jobs.JobName not like '%delete%' and jobs.JobName not like '%update%' and jobs.JobName not like '%stats%' and jobs.JobName not like '%Recycle%'
 and jobs.JobName not like '%Cleanup%' and jobs.JobName not like '%Monitor%' and jobs.JobName not like '%purge%' and jobs.JobName not like '%logins%' 
 and jobs.JobName not like '%shrink%'  and jobs.JobName not like '%error%' and jobs.JobName not like '%sync%'
 --order by jobs.JobName
 )
 ,jobdetails as (
select 
--jsch.job_id,
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
select sJOB.job_id,name, case when name like '%full%' then 'FULL'  when name like '%diff%' then 'DIFF'  when name like '%log%' then 'LOG'  when name like '%sysdb%' then 'FULL' else 'FULL' end bak_typr,
command,
case when command like '%SmsqlJobLauncher%' then 'SMSQL' 
	when jstep.subsystem = 'SSIS' then 'Maint.Plan'
	when command like '%execute%' or command like '%backup%'  then 'SQL Native'  
	else 'NOT-FOUND' end as [Backup Method]
	--,case when command like '%execute%' then left(right(command, len(command) - CHARINDEX('@CleanupTime',command)+1) ,22 )
	--	when command like '%SmsqlJobLauncher%' then left(right(command, len(command) - CHARINDEX('-RetainBackupDays',command)+1) ,20)
	--else 'NOT-FOUND' end as [Retention] 
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
 ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%' and [sJOB].name not like '%Recycle%'
 and [sJOB].name not like '%Cleanup%' and [sJOB].name not like '%Monitor%' and [sJOB].name not like '%purge%' and [sJOB].name not like '%logins%' 
 and [sJOB].name not like '%shrink%'  and [sJOB].name not like '%error%') jstep on jstep.job_id =jsch.job_id
 ),
 AOAGdetails as (
select  db.database_id,CASE WHEN db.database_id =1 then @@SERVERNAME + isnull( (select distinct ' ('+role_desc+')' from sys.dm_hadr_availability_replica_states where is_local=1),'') else '' end [Database Instance],
db.name as [Database], 
case when drs.database_id is not null OR SERVERPROPERTY('IsClustered')=1 then 'YES' else 'NO' end as [Part of Cluster],
case when drs.database_id is not null then 'Always-On' when SERVERPROPERTY('IsClustered')=1 then 'Clustered' else '' end as [Cluster Type],
CASE WHEN db.database_id =1 then
	case when SERVERPROPERTY('IsClustered')=1 then	
		(select STUFF((select ','+replica_server_name from (SELECT distinct NodeName +case is_current_owner when 1 then '(Owner)' else '' end replica_server_name  FROM sys.dm_os_cluster_nodes  ) a FOR XML PATH (''), type).value('.','nvarchar(max)') , 1, 1, '') ) 
		else (select STUFF((select ','+replica_server_name from (select distinct a.replica_server_name +'('+b.role_desc+')' as replica_server_name  from sys.availability_replicas a inner join  sys.dm_hadr_availability_replica_states b on a.replica_id = b.replica_id  ) a FOR XML PATH (''), type).value('.','nvarchar(max)') , 1, 1, '') ) 
		end
	else '' end as [Cluster Nodes],
CASE WHEN db.database_id =1 then (select top 1 cluster_name from master.sys.dm_hadr_cluster) else '' end as [Cluster Name],
isnull(gl.dns_name,'') as [Listener Name]
from sys.databases db
left join sys.dm_hadr_database_replica_states drs on drs.database_id=db.database_id and  is_local = 1
left join sys.availability_group_listeners gl on gl.group_id = drs.group_id
where  db.database_id <> 2 and db.state_desc = 'online'
 ),
 FinalInfo as (
 select database_id, [Database Instance],[Database],[Part of Cluster],[Cluster Type],isnull([Cluster Nodes],'') [Cluster Nodes],UPPER(isnull([Cluster Name],'')) [Cluster Name],UPPER([Listener Name]) as [Listener Name]
 ,JobName,jd.bak_typr +'-'+Schedule [Backup Schedules],[Backup Method],jd.bak_typr +'-'+[Retention] as [Retention] ,jd.bak_typr +'-'+ jd.LastRunStatus as LastRunStatus,jd.bak_typr,jd.bak_typr +'-'+  jd.BAK_Location BAK_Location
 from AOAGdetails ag
 left join jobdetails jd on  jd.Schedule not like '%No Schedule Found%' and ( jd.[Databases] like  '%'+ag.[Database]+'%' or (jd.[Databases] like '%USER_DATABASES%' and ag.database_id > 4) or (jd.[Databases] like '%AVAILABILITY_GROUP_DATABASES%' and [Cluster Type] = 'Always-On' and ag.database_id > 4) 
			or (jd.[Databases] like '%SYSTEM_DATABASES%' and ag.database_id <= 4) )
 )
 select distinct  database_id,[Database Instance],[Database],[Part of Cluster],[Cluster Type],[Cluster Nodes],[Cluster Name],[Listener Name],
 STUFF([A].query('/JobName').value('/', 'varchar(max)'), 1, 2, '') JobName,
STUFF([A].query('/Backup_Schedule').value('/', 'varchar(max)'), 1, 2, '') [Backup Schedules],
[Backup Method],
replace(replace(STUFF([A].query('/Retention').value('/', 'varchar(max)'), 1, 2, ''),char(10),''),char(13),'')  [Retention],
STUFF([A].query('/LastRunStatus').value('/', 'varchar(max)'), 1, 2, '')  [LastRunStatus],
replace(replace(STUFF([A].query('/BAK_Location').value('/', 'varchar(max)'), 1, 2, ''),char(10),''),char(13),'')  BAK_Location

 from FinalInfo fi
 OUTER APPLY (
select (select ', '+JobName as JobName, ', '+[Backup Schedules] as Backup_Schedule, ', '+[Retention] as [Retention], ', '+LastRunStatus as LastRunStatus, ', '+BAK_Location as BAK_Location from (select top 10 * from FinalInfo fin where fin.database_id=fi.database_id order by fin.bak_typr ) a 
FOR XML PATH (''), type) as a ) a
order by database_id
 
"

"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('SERVER_NAME,database_id,Database Instance,Database,Part of Cluster,Cluster Type,Cluster Nodes,Cluster Name,Listener Name,JobName,Backup Schedules,Backup Method,Retention,LastRunStatus,BAK_Location')
$JobInfoFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_
	$error.clear()
	try{	
		$JobInfo = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		"$_ --> ERROR"
		$JobInfo = $error[$error.count-1]
		$JobInfo = $ServerName+','+$JobInfo+',,,,,,,,,,,,,'
		$JobInfo = ($InfoDetails,$JobInfo)| ConvertFrom-Csv
	}
	
	$JobInfo | foreach-object {
		$JobInfoTmp = ([ordered]@{
		"SERVERNAME"=$ServerName
		"database_id"=$_.database_id
		"Database Instance"=$_."Database Instance"
		"Database"=$_."Database"
		"Part of Cluster"=$_."Part of Cluster"
		"Cluster Type"=$_."Cluster Type"
		"Cluster Nodes"=$_."Cluster Nodes"
		"Cluster Name"=$_."Cluster Name"
		"Listener Name"=$_."Listener Name"
		"JobName"=$_."JobName"
		"Backup Schedules"=$_."Backup Schedules"
		"Backup Method"=$_."Backup Method"
		"Retention"=$_."Retention"
		"LastRunStatus"=$_."LastRunStatus"
		"BAK_Location"=$_."BAK_Location"
		})
		$JobInfoFinal+=New-Object -TypeName PSCustomObject -Property $JobInfoTmp
		#$JobInfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $JobInfo
	}
}
"-----------------> JobInfoFinal"
$JobInfoFinal |  export-csv -path "D:\sazam\DB_Wise_AOAG_JOB_$DomainName.csv" -NoTypeInformation
#$JobInfoFinal