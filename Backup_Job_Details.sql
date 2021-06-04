select name,command,
case when command like '%SmsqlJobLauncher%' then 'SMSQL' 
	when jstep.subsystem = 'SSIS' then 'Maint.Plan'
	when command like '%execute%' or command like '%backup%'  then 'SQL Native'  
	else 'NOT-FOUND' end as "Backup Method"
	,case when command like '%execute%' then right(command, len(command) - CHARINDEX('@CleanupTime',command)+1) 
		when command like '%SmsqlJobLauncher%' then left(right(command, len(command) - CHARINDEX('-RetainBackupDays',command)+1) ,30)
	else 'NOT-FOUND' end as "Retention" 
from msdb.dbo.sysjobs sJOB
join msdb.dbo.sysjobsteps jstep on sJOB.job_id = jstep.job_id
where sJOB.enabled = 1 
and ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%' and [sJOB].name not like '%Recycle%'
 and [sJOB].name not like '%Cleanup%' and [sJOB].name not like '%Monitor%' and [sJOB].name not like '%purge%' and [sJOB].name not like '%logins%' 
 and [sJOB].name not like '%shrink%'  and [sJOB].name not like '%error%'
 
 
 ;with jobSCH as (
SELECT  [sJOB].job_id,
     [sJOB].[name] AS [JobName]
	-- ,[sJOB].enabled IsEnabled
	 , [sJOBSCH].Occurrence  +'-'+isnull([sJOBSCH].Recurrence,'')+'-'+isnull([sJOBSCH].Frequency,'') as "Backup Schedule/s"
	 ,[sJOBSCH].Occurrence ,[sJOBSCH].Recurrence,[sJOBSCH].Frequency
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
        WHEN 4 THEN 'every ' + CAST([freq_interval] AS VARCHAR(3)) + ' day(s)'
        WHEN 8 THEN 'every ' + CAST([freq_recurrence_factor] AS VARCHAR(3)) 
                    + ' week(s) on '
                    + CASE WHEN [freq_interval] & 1 = 1 THEN 'Sunday' ELSE '' END
                    + CASE WHEN [freq_interval] & 2 = 2 THEN ', Monday' ELSE '' END
                    + CASE WHEN [freq_interval] & 4 = 4 THEN ', Tuesday' ELSE '' END
                    + CASE WHEN [freq_interval] & 8 = 8 THEN ', Wednesday' ELSE '' END
                    + CASE WHEN [freq_interval] & 16 = 16 THEN ', Thursday' ELSE '' END
                    + CASE WHEN [freq_interval] & 32 = 32 THEN ', Friday' ELSE '' END
                    + CASE WHEN [freq_interval] & 64 = 64 THEN ', Saturday' ELSE '' END
        WHEN 16 THEN 'on Day ' + CAST([freq_interval] AS VARCHAR(3)) 
                     + ' of every '
                     + CAST([freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
        WHEN 32 THEN 'on '
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
        WHEN 1 THEN 'once at ' 
                    + STUFF(
                 STUFF(RIGHT('000000' + CAST([active_start_time] AS VARCHAR(6)), 6)
                                , 3, 0, ':')
                            , 6, 0, ':')
        WHEN 2 THEN 'every ' 
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
        WHEN 4 THEN 'every ' 
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
        WHEN 8 THEN 'every ' 
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
where sJOB.enabled = 1 and [sJOBSCH].Occurrence is not null and [sJOBSCH].Occurrence <> 'One Time'
--and ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
--and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%'
)
select jsch.job_id,jsch.JobName,jsch.[Backup Schedule/s],jstep.command,jstep.[Backup Method],jstep.Retention from jobSCH jsch
left join (
select sJOB.job_id,name,command,
case when command like '%SmsqlJobLauncher%' then 'SMSQL' 
	when jstep.subsystem = 'SSIS' then 'Maint.Plan'
	when command like '%execute%' or command like '%backup%'  then 'SQL Native'  
	else 'NOT-FOUND' end as "Backup Method"
	,case when command like '%execute%' then left(right(command, len(command) - CHARINDEX('@CleanupTime',command)+1) ,100 )
		when command like '%SmsqlJobLauncher%' then left(right(command, len(command) - CHARINDEX('-RetainBackupDays',command)+1) ,30)
	else 'NOT-FOUND' end as "Retention" 
from msdb.dbo.sysjobs sJOB
join msdb.dbo.sysjobsteps jstep on sJOB.job_id = jstep.job_id
where sJOB.enabled = 1 
and ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%' and [sJOB].name not like '%Recycle%'
 and [sJOB].name not like '%Cleanup%' and [sJOB].name not like '%Monitor%' and [sJOB].name not like '%purge%' and [sJOB].name not like '%logins%' 
 and [sJOB].name not like '%shrink%'  and [sJOB].name not like '%error%') jstep on jstep.job_id =jsch.job_id
 
