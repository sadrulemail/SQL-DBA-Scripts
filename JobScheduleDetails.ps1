
$DomainName = "CGRIB"
#$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
#$ActiveServers = ("DB03VDCA.wcgclinical.com","DB02VDCA.wcgclinical.com","DB01VDCA.wcgclinical.com","DB18VDCA.wcgclinical.com","db17vwfc.wcgclinical.com","DB19VDCA.wcgclinical.com","db01vwfc.wcgclinical.com","WCGLC01VL.wcgclinical.com","dce-t-twdb01.wcgclinical.com","DCA-T-APP02.wcgclinical.com","SEADWDCMDB01.wcgclinical.com","SEAQWDCMDB01.wcgclinical.com","SEAQWDCMDB02.wcgclinical.com","SEAQWDCMCL01.wcgclinical.com","SEAQWDCMLN.wcgclinical.com","SEAQWIRSDB02.wcgclinical.com","SEAQWIRSDB01.wcgclinical.com","SEAQWIRSCL01.wcgclinical.com","PHLDWACIDB01.wcgclinical.com","SEAQWIRSLN.wcgclinical.com","SEANWDCMDB01.wcgclinical.com","SEANWIRSDB01.wcgclinical.com","SEAVWIRSDB01.wcgclinical.com","PHLDWWCGDB04.wcgclinical.com")

#$ActiveServers = ("DCE-Q-ROCHEAPP01.EPSNET.WAN","dce-u-rochecl01.EPSNET.WAN","dce-u-rochedb04.EPSNET.WAN","PHLOWWCGDB01.EPSNET.WAN","PHLOWWCGDB03.EPSNET.WAN","dce-u-sftdb03.EPSNET.WAN","COVSQLSPUATCL.EPSNET.WAN","dce-u-rochedb01.EPSNET.WAN","ROCHESQLUAT.EPSNET.WAN","PHLQWSPFDB01.EPSNET.WAN","SFTSQLUATCL.EPSNET.WAN","dce-u-rochedb05.EPSNET.WAN","dce-u-rochedb02.EPSNET.WAN","WCGSQLUATCL.EPSNET.WAN","dce-u-rochedb03.EPSNET.WAN","PHLQWSPFDB03.EPSNET.WAN","PHLQWSPFDB02.EPSNET.WAN","PHLOWWCGDB02.EPSNET.WAN","dce-q-rochedb02.EPSNET.WAN","SFTSQLSPUATCL.EPSNET.WAN","PHLUWSFPDB03CV.EPSNET.WAN","COVSQLUATCL.EPSNET.WAN","dce-u-rochecl02.EPSNET.WAN","DCE-DR-SQL01.EPSNET.WAN","PHLUWSFPDB03JN.EPSNET.WAN","dce-q-rochedb03.EPSNET.WAN","dce-q-rochedb01.EPSNET.WAN")

#$ActiveServers = ("DEVSQL07.eplnet.wan","DEVWEB32.eplnet.wan","DEVSQL04.eplnet.wan","DCE-D-SQL01.eplnet.wan","DCE-D-SQL02.eplnet.wan","DCE-D-SQL03.eplnet.wan","dce-q-sftdb01.eplnet.wan","dce-q-sftdb02.eplnet.wan","dce-q-sftdb03.eplnet.wan","PHLDWWCGDB03.eplnet.wan","PHLTWAIMDB01.eplnet.wan","PHLTWAIMDB02.eplnet.wan","PHLTWAIMCL01.eplnet.wan","PHLTWWCGDB01.eplnet.wan")

#$ActiveServers = ("FOUNDATIONVM.WIRB.COM","DYNAMICSDB.WIRB.com","TFS2012VM.WIRB.com","DEVSQL.WIRB.com","LYNCMONDB.WIRB.com","IRISDB64N2.WIRB.com","IRISDB64N1.WIRB.com","IRISREPV3.WIRB.com","TFS2.WIRB.COM")

#$ActiveServers = ("DB3DCA.cgirb.com","DB7DCA.cgirb.com","DB2RTP.cgirb.com","DB2DCA.cgirb.com")

$ActiveServers = ("SCSDWSFDB01.medavante.net","SCSQWSFDB02.medavante.net","SCSSFDB01-PT.medavante.net","SCSSFDB01-TR.medavante.net","SCSSFDB02-PT.medavante.net","SCSSQLDEV1-14T.medavante.net","SCSSQLENT1-14T.medavante.net","SCSTWSFDB01.medavante.net","SCSTWSMRDB01.medavante.net","SFDATABASEDEV.medavante.net","SFDATABASEFORMS.medavante.net","SFDATABASEQA.medavante.net","SFDATABASETEST.medavante.net","SFDATABASETRN.medavante.net")


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
jsch.JobName, 
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
select sJOB.job_id,name, case when name like '%full%' then 'FULL'  when name like '%diff%' then 'DIFF'  when name like '%log%' then 'LOG' end bak_typr,
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
where --sJOB.enabled = 1 and
 ([sJOB].name like '%full%' OR [sJOB].name like '%diff%' OR [sJOB].name like '%log%' OR [sJOB].name like '%bak%' OR [sJOB].name like '%Backup%'  )
and  [sJOB].name not like '%delete%' and [sJOB].name not like '%update%' and [sJOB].name not like '%stats%' and [sJOB].name not like '%Recycle%'
 and [sJOB].name not like '%Cleanup%' and [sJOB].name not like '%Monitor%' and [sJOB].name not like '%purge%' and [sJOB].name not like '%logins%' 
 and [sJOB].name not like '%shrink%'  and [sJOB].name not like '%error%') jstep on jstep.job_id =jsch.job_id
 )
 select * from jobdetails j
 --where j.Enabled = 'YES'
	--and j.Schedule not like '%No Schedule Found%'"
	
"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('SERVER_NAME,JobName,Enabled,Schedule,LastRunDateTime,LastRunDuration (HH:MM:SS),LastRunStatus,NextRunDateTime,EmailAddress,BackupMethod,Retention,BAK_Location,Databases,Step_Command')
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
		$JobInfo = $ServerName+','+$JobInfo+',,,,,,,,,,,'
		$JobInfo = ($InfoDetails,$JobInfo)| ConvertFrom-Csv
	}
	
	if ($JobInfo.count -eq 0)
	{
		$JobInfo = "No Maintenance job found."
		$JobInfo = $ServerName+','+$JobInfo+',,,,,,,,,,,'
		$JobInfo = ($InfoDetails,$JobInfo)| ConvertFrom-Csv
	}
	#$JobInfo
	$JobInfo | foreach-object {
		$JobInfoTmp = ([ordered]@{
		"SERVER_NAME"= $ServerName
		"JobName"=$_.JobName
		"Enabled"=$_.Enabled
		"Schedule"=$_.Schedule
		"LastRunDateTime"=$_.LastRunDateTime
		"LastRunDuration (HH:MM:SS)"=$_."LastRunDuration (HH:MM:SS)"
		"LastRunStatus"=$_.LastRunStatus
		"NextRunDateTime"=$_.NextRunDateTime
		"BackupMethod"=$_."Backup Method"
		"Retention"=$_.Retention
		"Databases"=$_.Databases
		"BAK_Location"=$_.BAK_Location
		"EmailAddress"=$_.EmailAddress
		})
		$JobInfoFinal+=New-Object -TypeName PSCustomObject -Property $JobInfoTmp
		#$JobInfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $JobInfo
		#$JobInfoTmp
	}
}
"-----------------> JobInfoFinal"
$JobInfoFinal |  export-csv -path "C:\sazam\Jobs\JobInfoFinal_$DomainName.csv" -NoTypeInformation
#$JobInfoFinal