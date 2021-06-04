IF OBJECT_ID('tempdb..#log_info') is not null
	DROP TABLE #log_info

CREATE TABLE #log_info (
	LOGID int IDENTITY(1,1),
		LogDate NVARCHAR(100)
		,ProcessInfo NVARCHAR(100)
		,LogText NVARCHAR(MAX)
		)

DECLARE @LogStartTime NVARCHAR(100) = convert(NVARCHAR, DATEADD(HH, -4, SYSDATETIME()), 120) -- YYYY-MM-DD HH24:MI:SS

	INSERT INTO #log_info (LogDate,ProcessInfo,LogText)
	EXEC master.dbo.xp_readerrorlog 0
		,1
		,N''
		,NULL
		,@LogStartTime
		,NULL
		,N'ASC'

declare @errorMessage nvarchar(MAX)

if (select count(0) from #log_info where LogText LIKE 'Error%') = 0
set @errorMessage = 'NO ERROR'
else 
begin
select @errorMessage = STUFF(
(select ';;' + ErrorMessage
FROM (SELECT distinct top 100  'Date: '+LogDate+';'+'Message: '+[error] as ErrorMessage FROM (
   SELECT LogDate
      ,[processinfo]
      ,LogText AS [MessageText]
      , LAG(LogText, 1, '') OVER (
         ORDER BY LOGID DESC
         )  AS [error]
   FROM #log_info
   ) AS ErrTable
WHERE [MessageText] LIKE 'Error%' ORDER by 1 DESC) a
FOR XML PATH (''), type).value('.','nvarchar(max)')
 , 1, 2, '') 

set @errorMessage = REPLACE (@errorMessage,';','<br>')
end




;with CPU as (
SELECT ProcessUtilization as 'SQL CPU'
    ,100 - SystemIdle AS 'O/S CPU'
FROM (
    SELECT record.value('(./Record/@id)[1]', 'int') AS id
    ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
    ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS ProcessUtilization
    ,TIMESTAMP
    FROM (
        SELECT top 1 TIMESTAMP
            ,convert(XML, record) AS record
        FROM sys.dm_os_ring_buffers 
        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
           AND record LIKE '%<SystemHealth>%'
		   ORDER BY TIMESTAMP DESC
        ) AS sub1
    ) AS sub2
) ,
RAM as (
select round([SQL Server Memory Usage (MB)]/cast([Physical Memory (MB)] as float) * 100.00 , 0) [SQL RAM],
round(([Physical Memory (MB)]-[Available Memory (MB)])/cast([Physical Memory (MB)] as float) * 100.00 , 0) [O/S RAM]
from (
SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       (SELECT physical_memory_in_use_kb/1024 FROM sys.dm_os_process_memory) AS [SQL Server Memory Usage (MB)]
FROM sys.dm_os_sys_memory) a 
),
Resources as (
select @@servername as SERVERNAME, [Page life expectancy], 
round([Buffer cache hit ratio]/cast([Buffer cache hit ratio base] as float) * 100.00 , 0) as [Buffer cache hit ratio], 
round([Cache Hit Ratio]/cast([Cache Hit Ratio Base]  as float)* 100.00, 0) as [Procedure Cache Hit Ratio],
(SELECT count(0) FROM sys.sysprocesses WHERE blocked > 0)  as BlockedSessionCount
--, @errorMessage as ErrorMessage
from
(SELECT counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME in ('SQLServer:Plan Cache', 'SQLServer:Buffer Manager')
and ( ( [counter_name] like 'Cache Hit Ratio%' and instance_name = '_Total') 
OR counter_name like 'Buffer cache hit%' 
OR [counter_name] = 'Page life expectancy') ) as minfo
PIVOT (
 max(cntr_value) FOR counter_name in (
 [Buffer cache hit ratio],
[Buffer cache hit ratio base],
[Page life expectancy],
[Cache Hit Ratio],
[Cache Hit Ratio Base]) ) as pvt
),
DiskSpace as (
select STUFF(
(Select ';' + [Disk Space Free %]+'%'
from (
SELECT DISTINCT  
		volume_mount_point +' - '+
		logical_volume_name  +' - '+
		cast( CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 as VARCHAR) AS [Disk Space Free %]
FROM sys.master_files 
CROSS APPLY sys.dm_os_volume_stats(database_id, file_id)) a
FOR XML PATH (''), type).value('.','nvarchar(max)')
, 1, 1, '') as [Disk Space Free])
SELECT Resources.SERVERNAME,
	   replace(DiskSpace.[Disk Space Free],';','<br>') as [Disk Space Free],
	   CPU.[O/S CPU] [OS_CPU],
	   CPU.[SQL CPU] [SQL_CPU],
	   RAM.[O/S RAM] [OS_RAM],
	   RAM.[SQL RAM] [SQL_RAM],
	   Resources.[Page life expectancy],
	   Resources.[Buffer cache hit ratio],
	   Resources.[Procedure Cache Hit Ratio],
	   Resources.BlockedSessionCount,
	   @errorMessage as [SQL ERROR LOG]
FROM RAM, CPU , Resources, DiskSpace
WITH (NOLOCK) OPTION (RECOMPILE);

