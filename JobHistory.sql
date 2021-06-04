SELECT top 100 
b.instance_id,
  msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime', 
b.step_id,b.step_name,
b.message,
 ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
          as 'RunDurationMinutes'
FROM msdb.dbo.sysjobhistory  b
INNER JOIN msdb.dbo.sysjobs a
ON a.job_id = b.job_id  
WHERE a.name = 'DBAdmin-Maint-DatabaseBackup - LOG'
ORDER BY b.instance_id DESC