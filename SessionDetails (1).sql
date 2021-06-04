-- get details
select --count(distinct session_id) from (
session_id ,STATUS ,blocking_session_id ,wait_type ,WaitSec ,ElapsSec ,StartTime ,CommandType ,Executions ,DatabaseName ,ObjectName ,statement_text ,program_name ,cpu_time ,IOReads ,IOWrites ,login_name ,host_name ,Protocol ,transaction_isolation ,ConnectionWrites ,ConnectionReads ,ClientAddress ,Authentication  from (
SELECT   s.session_id
,r.STATUS
,blocking_session_id = CASE WHEN lead_blocker = 1 THEN 'Lead Blocker' ELSE cast(r.blocking_session_id as varchar(10)) END
,r.wait_type
,r.wait_time / (1000.0) 'WaitSec'
,r.total_elapsed_time / (1000.0) 'ElapsSec'
,StartTime          = r.start_time
,CommandType        = r.command
,Executions         = ec.execution_count  
,DatabaseName		= Db_name(r.database_id)
,ObjectName			= OBJECT_SCHEMA_NAME(st.objectid,st.dbid) + '.' + OBJECT_NAME(st.objectid, st.dbid)
,statement_text = Substring(st.TEXT, (r.statement_start_offset / 2) + 1, (
		(
		CASE r.statement_end_offset
		WHEN - 1
		THEN Datalength(st.TEXT)
		ELSE r.statement_end_offset
		END - r.statement_start_offset
		) / 2
		) + 1) 
--,s.program_name
,program_name = Case when s.program_name like 'SQLAgent%' then 'SQLAgent Job - '+( --SQLAgent - TSQL JobStep (Job 0x7EEB7656834CDC4AB1A0F78A36AEB755 : Step 1)
		select sj.name from msdb.dbo.sysjobs sj
		where cast(sj.job_id as varchar(200)) = ( CASE WHEN (CHARINDEX('(Job 0x', program_name) + 7) > 0 THEN CAST(
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 06, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 04, 2) +
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 02, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 00, 2) + '-' +
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 10, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 08, 2) + '-' +
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 14, 2) + SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 12, 2) + '-' +
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 16, 4) + '-' +
		SUBSTRING(s.program_name, (CHARINDEX('(Job 0x', program_name) + 7) + 20,12) AS varchar(200))
		ELSE NULL
		END )
		) else s.program_name end 
,(r.cpu_time /1000.00) AS cpu_time
    ,IOReads            = r.logical_reads + r.reads
    ,IOWrites           = r.writes
,s.login_name
,s.host_name
    ,Protocol           = con.net_transport
    ,transaction_isolation =
        CASE s.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'Read Uncommitted'
            WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
        END
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads
    ,ClientAddress      = con.client_net_address
    ,Authentication     = con.auth_scheme
	--select * 
FROM sys.dm_exec_sessions AS s
LEFT JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
LEFT JOIN sys.dm_exec_connections con ON con.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
OUTER APPLY
(
    SELECT execution_count = MAX(cp.usecounts)
    FROM sys.dm_exec_cached_plans cp
    WHERE cp.plan_handle = r.plan_handle
) ec
OUTER APPLY
(
    SELECT
        lead_blocker = 1
    FROM master.dbo.sysprocesses sp
    WHERE sp.spid IN (SELECT blocked FROM master.dbo.sysprocesses)
    AND sp.blocked = 0
    AND sp.spid = r.session_id
) lb
WHERE s.session_id <> @@SPID
--ORDER BY s.session_id
) a
--where a.blocking_session_id <> '0'
ORDER BY session_id
