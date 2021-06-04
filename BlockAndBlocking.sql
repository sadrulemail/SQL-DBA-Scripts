--Get the processes that are currently blocked
SELECT * FROM sys.sysprocesses WHERE blocked > 0

sp_lock @process_id

--Get SQL of SPID
DBCC inputbuffer  (74)

--Get the blocked and blocking statements
SELECT
  db.name DBName,
  tl.request_session_id,
  wt.blocking_session_id,
  OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
  tl.resource_type,
  h1.TEXT AS RequestingText,
  h2.TEXT AS BlockingText,
  tl.request_mode
 FROM sys.dm_tran_locks AS tl
  INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
  INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
  INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
  INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
  INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
  CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
  CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2
 
 
 -- get details
  SELECT s.session_id
    ,r.STATUS
    ,r.blocking_session_id
    ,r.wait_type    
    ,r.wait_time / (1000.0) 'WaitSec'    
    ,r.total_elapsed_time / (1000.0) 'ElapsSec'
    ,Substring(st.TEXT, (r.statement_start_offset / 2) + 1, (
            (
                CASE r.statement_end_offset
                    WHEN - 1
                        THEN Datalength(st.TEXT)
                    ELSE r.statement_end_offset
                    END - r.statement_start_offset
                ) / 2
            ) + 1) AS statement_text
    ,Db_name(r.database_id) as DatabaseName
    ,s.login_name
    ,s.host_name
    --,s.program_name
		,Case when s.program_name like 'SQLAgent%' then 'SQLAgent Job - '+( --SQLAgent - TSQL JobStep (Job 0x7EEB7656834CDC4AB1A0F78A36AEB755 : Step 1)
	select sj.name from msdb.dbo.sysjobs sj
	where   sj.job_id = ( CASE WHEN (CHARINDEX('(Job 0x', program_name) + 7) > 0 THEN CAST(
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 06, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 04, 2) +
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 02, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 00, 2) + '-' +
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 10, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 08, 2) + '-' +
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 14, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 12, 2) + '-' +
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 16, 4) + '-' +
			SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 20,12) AS varchar(200))
		ELSE NULL
		END )
	) else s.program_name end program_name
	,(r.cpu_time /1000.00) AS cpu_time
	--,IDENTITY(INT, 1,1) AS ID	   
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.session_id != @@SPID
ORDER BY r.cpu_time DESC
    ,r.STATUS
    ,r.blocking_session_id
    ,s.session_id
    
-- 

--Top Queries
SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1),
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time,
qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_logical_reads DESC -- logical reads
-- ORDER BY qs.total_logical_writes DESC -- logical writes
-- ORDER BY qs.total_worker_time DESC -- CPU time


  
  --- check below which will create a block path
  --- 56 <- 59 <- 89
CREATE TABLE #connections (
    spid         int NOT NULL,
    blockedBy    int NULL,
    PRIMARY KEY CLUSTERED (spid)
);
--- Example data:
INSERT INTO #connections (spid, blockedBy)
VALUES (53, NULL),
       (54, NULL),
       (55, NULL),
       (56,   64),
       (57, NULL),
       (59,   56),
       (60, NULL),
       (61, NULL),
       (62, NULL),
       (63,   64),
       (64,   53),
       (65, NULL),
       (66,   56);
	   
  
WITH list (spid, blockedBy, [level], list)
AS (--- The anchor of the recursive CTE is the first-level relation
    --- from the SPID to the blocking SPID.
    --- The "list" column is a varchar(100) column that contains an
    --- ordered path of all the blocking relations.
    SELECT spid, blockedBy, 1, CAST(blockedBy AS varchar(100)) AS list
    FROM #connections
    WHERE blockedBy IS NOT NULL

    UNION ALL

    --- From here, we'll recurse the blocking SPID's own blocking
    --- SPIDs, and increment the "level" counter by one.
    SELECT list.spid, conn.blockedBy, list.[level]+1,
        --- Suffix the new level's SPID to the end of the "list" string.
        CAST(list+' <- '+CAST(conn.blockedBy AS varchar(100)) AS varchar(100)) AS list
    FROM list
    INNER JOIN #connections AS conn ON list.blockedBy=conn.spid
    WHERE conn.blockedBy IS NOT NULL)

SELECT spid, list AS blockedByChain
FROM list
WHERE [level]=(SELECT MAX(sub.[level]) FROM list AS sub WHERE sub.spid=list.spid)
ORDER BY spid, [level], blockedBy;