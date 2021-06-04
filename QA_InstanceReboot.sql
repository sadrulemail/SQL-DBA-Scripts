
if OBJECT_ID('tempdb..#log_info') is not null
begin
	drop table #log_info
end

CREATE TABLE #log_info (
	LOGID int IDENTITY(1,1),
		LogDate NVARCHAR(100)
		,ProcessInfo NVARCHAR(100)
		,LogText NVARCHAR(MAX)
		)

DECLARE @LogStartTime NVARCHAR(100) = convert(NVARCHAR, DATEADD(HH, - 10, SYSDATETIME()), 120) -- YYYY-MM-DD HH24:MI:SS

	INSERT INTO #log_info (LogDate,ProcessInfo,LogText)
	EXEC master.dbo.xp_readerrorlog 0
		,1
		,N''
		,NULL
		,@LogStartTime
		,NULL
		,N'ASC'

select @@SERVERNAME SERVER_NAME,QA_Case,Name,Status from (
select 'Service' as [QA_Case] ,servicename as Name, status_desc Status from sys.dm_server_services
Union all
select 'Database - State' as [QA_Case] ,(select cast( count(0) as varchar(10)) from sys.databases where  state = 0  )+' out of ' + cast (count(0) as varchar(10)), state_desc collate SQL_Latin1_General_CP1_CI_AS  from sys.databases
group by state_desc
Union all
select 'Database' as [QA_Case] ,Name, state_desc collate SQL_Latin1_General_CP1_CI_AS  from sys.databases
where state <> 0
Union all
SELECT 'Cluster' as [QA_Case] ,NodeName,status_description + CASE is_current_owner WHEN 1 THEN ' - Current Node' ELSE '' END status_description  FROM sys.dm_os_cluster_nodes
Union all
select 'AOAG - Group' [QA_Case], ag.name,ars.role_desc
from sys.availability_groups  ag
inner join sys.availability_replicas ar on ag.group_id = ar.group_id
inner join sys.dm_hadr_availability_replica_states ars on ars.replica_id = ar.replica_id
where ar.replica_server_name = @@SERVERNAME
union all
SELECT top 1000 'AOAG - DB' as [QA_Case] ,
       d.name  +'-'+ ag.name  +'-'+  ar.replica_server_name  +'-'+  ars.role_desc +'-'+  ars.connected_state_desc
	 ,drs.synchronization_state_desc
FROM
       sys.availability_groups ag
       INNER JOIN sys.availability_replicas ar
              ON ar.group_id = ag.group_id
       INNER JOIN sys.dm_hadr_database_replica_states drs
              ON drs.replica_id = ar.replica_id
       INNER JOIN sys.databases d
              ON d.database_id = drs.database_id
		INNER JOIN sys.dm_hadr_availability_replica_states AS ars on ars.replica_id = ar.replica_id
WHERE ar.replica_server_name = @@SERVERNAME
Order by ag.name,d.name
union all
select * from (
select 'Jobs' [QA_Case], sJOB.name, 
case sJOBH.run_status
	 when 0 then 'Failed'
	 when 1 then 'Succeeded'
	 when 2 then 'Retry'
	 when 3 then 'Canceled'
	 when 4 then 'In Progress'
	 else 'Unknown' end +' - '+ cast(sJOBH.run_date as varchar(15)) +'-'+ cast( sJOBH.run_time as varchar(15))
	  AS [LastRunStatus]
FROM 
    [msdb].[dbo].[sysjobs] AS [sJOB]
     JOIN (
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
	where sJOB.enabled =1) a
	where a.LastRunStatus not like 'Succeeded%'
Union All
SELECT top 5 'SQL Log' as [QA_Case], LogDate, Error
FROM (
   SELECT LogDate
      ,[processinfo]
      ,LogText AS [MessageText]
      , LAG(LogText, 1, '') OVER (
         ORDER BY LOGID DESC
         )  AS [error]
   FROM #log_info
   ) AS ErrTable
WHERE [MessageText] LIKE 'Error%' and error not like '%login failed%'
) a



