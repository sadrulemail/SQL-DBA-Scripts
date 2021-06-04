SET NOCOUNT ON;
-- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID('tempdb..#temp_requests') IS NOT NULL
	DROP TABLE #temp_requests

--Capture sessions that are blocked
-- get details
IF OBJECT_ID('tempdb..#session_info') IS NOT NULL
	DROP TABLE #session_info
IF OBJECT_ID('tempdb..#session_full_info') IS NOT NULL
	DROP TABLE #session_full_info

--;with session_info as (
		select spid, CASE STATUS WHEN 0 THEN 'Running' WHEN 1 THEN 'Runnable'   WHEN    2 THEN 'Background' WHEN   3 THEN 'Rollback' WHEN   4 THEN 'Pending' WHEN   5 THEN 'Suspended' WHEN 6 THEN 'Sleeping' WHEN  7 THEN 'Dormant' WHEN  8 THEN 'Spinloop'  ELSE cast(STATUS as varchar(50) )END as STATUS, blocked, lastwaittype, waittime, login_time, cmd, program_name 
	,dbid,loginame,hostname,net_library,cpu,sql_handle
	into #session_info
	from (
		select sp.spid, MAX(CASE rtrim(sp.STATUS) WHEN 'Running' THEN 0 WHEN 'Runnable' THEN 1 WHEN 'Background' THEN  2 WHEN 'Rollback' THEN 3 WHEN 'Pending' THEN 4 WHEN 'Suspended' THEN 5 WHEN 'Sleeping' THEN 6 WHEN 'Dormant' THEN 7 WHEN 'Spinloop' THEN 8 ELSE sp.STATUS END) STATUS, 
		max(case sp.blocked when sp.spid then 0 else  sp.blocked end ) blocked,
		max(sp.lastwaittype) lastwaittype, sum(cast(sp.waittime as numeric(38,2) )) waittime, min(sp.login_time) login_time, max(sp.cmd) cmd, max(sp.program_name) program_name
		,max(dbid) dbid,max(sp.loginame) loginame,max(sp.hostname) hostname,max(sp.net_library) net_library, sum(cast(sp.cpu as numeric(38,2))) cpu, max(sp.sql_handle) sql_handle
		from master.dbo.sysprocesses sp
		group by sp.spid
	) a
-- )
;with session_full_info as (
--select --count(distinct session_id) from (
--session_id ,STATUS ,blocking_session_id ,LastWaitType ,WaitSec ,ElapsSec ,StartTime ,CommandType ,Executions ,DatabaseName ,ObjectName ,statement_text ,program_name ,cpu_time ,IOReads ,IOWrites ,login_name ,host_name ,Protocol ,transaction_isolation ,ConnectionWrites ,ConnectionReads ,ClientAddress ,Authentication  from (
SELECT  distinct session_id = sp.spid
,CASE WHEN isnull(s.status,sp.STATUS) = sp.STATUS THEN sp.STATUS ELSE sp.STATUS +'/'+isnull(s.status,sp.STATUS) END STATUS
,blocking_session_id = CASE WHEN lead_blocker = 1 THEN 'Lead Blocker' ELSE cast(isnull(r.blocking_session_id,sp.blocked) as varchar(10)) END
,blocking_session_id_org = isnull(r.blocking_session_id,sp.blocked)
,LastWaitType   = isnull(r.last_wait_type,sp.lastwaittype )
,cast ( CASE when r.wait_time is not null then r.wait_time else sp.waittime end / (1000.0)  as numeric(38,2)  ) WaitSec
,cast( r.total_elapsed_time / (1000.0)   as numeric(38,2) ) ElapsSec
,StartTime          = isnull(r.start_time,sp.login_time)
,CommandType        = isnull(r.command, sp.cmd)
,Executions         = ec.execution_count  
,DatabaseName		= isnull(Db_name(r.database_id),Db_name(sp.dbid))
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
,program_name = isnull( Case when sp.program_name like 'SQLAgent%' then 'SQLAgent Job - '+( --SQLAgent - TSQL JobStep (Job 0x7EEB7656834CDC4AB1A0F78A36AEB755 : Step 1)
		select sj.name from msdb.dbo.sysjobs sj
		where cast(sj.job_id as varchar(200)) = ( CASE WHEN (CHARINDEX('(Job 0x', sp.program_name) + 7) > 0 THEN CAST(
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 06, 2) + SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 04, 2) +
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 02, 2) + SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 00, 2) + '-' +
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 10, 2) + SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 08, 2) + '-' +
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 14, 2) + SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 12, 2) + '-' +
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 16, 4) + '-' +
		SUBSTRING(sp.program_name, (CHARINDEX('(Job 0x', sp.program_name) + 7) + 20,12) AS varchar(200))
		ELSE NULL
		END )
		) else sp.program_name end ,sp.program_name)
,cast( ( CASE when r.cpu_time is not null then r.cpu_time else sp.cpu end /1000.00)   as numeric(38,2)  ) AS cpu_time
    ,IOReads            = r.logical_reads + r.reads
    ,IOWrites           = r.writes
,login_name = isnull(s.login_name,sp.loginame) 
,host_name = isnull(s.host_name,sp.hostname)
    ,Protocol           = isnull(con.net_transport,sp.net_library)
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
FROM #session_info sp
LEFT JOIN sys.dm_exec_sessions AS s on sp.spid = s.session_id
LEFT JOIN sys.dm_exec_requests AS r ON r.session_id = sp.spid
LEFT JOIN (select con.session_id, max(con.net_transport) net_transport, sum(cast(con.num_writes as numeric(38,2))) num_writes, sum(cast(con.num_reads as numeric(38,2))) num_reads, 
		max(con.client_net_address) client_net_address, max(con.auth_scheme) auth_scheme
		from sys.dm_exec_connections con
		group by con.session_id) con ON con.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS st
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
    FROM #session_info spi
    WHERE spi.spid IN (SELECT blocked FROM #session_info)
    AND spi.blocked = 0
    AND spi.spid = sp.spid
) lb
WHERE sp.spid <> @@SPID
)
select * 
into #session_full_info
from session_full_info

;with block_sessions as (
	select session_id,sfi.blocking_session_id_org, session_id OriginalID, 0 blk_Order from #session_full_info sfi
	union all
	select sfi.session_id session_id, sfi.blocking_session_id_org blocked_by , bs.OriginalID OriginalID , blk_Order+1
	from block_sessions bs
	inner join #session_full_info sfi on bs.blocking_session_id_org = sfi.session_id and sfi.blocking_session_id_org <> 0
)
, block_chain as (
	select session_id,STUFF(
	(select ' > ' + cast ( dd.blocking_session_id_org as varchar(200))
	FROM (
	select top 10000 * from block_sessions dd where d.session_id = dd.OriginalID
	order by dd.blk_Order
	) dd
	FOR XML PATH (''), type).value('.','nvarchar(max)')
	 , 1, 3, '') as blocks
	 from block_sessions d
	 where session_id=OriginalID
 )
select sfi.session_id ,STATUS , 
	CASE when blocking_session_id='Lead Blocker' then cast ( blocking_session_id_org as varchar(200)) + '<br>('+blocking_session_id+')' else blocks end blocking_session_id, 
	LastWaitType ,WaitSec ,ElapsSec ,StartTime ,CommandType ,Executions ,DatabaseName ,ObjectName ,statement_text ,program_name ,cpu_time ,IOReads ,IOWrites ,login_name ,host_name ,Protocol ,transaction_isolation ,ConnectionWrites ,ConnectionReads ,ClientAddress ,Authentication 
INTO #temp_requests
from #session_full_info sfi
left join block_chain bc on sfi.session_id = bc.session_id
order by sfi.session_id
;

select * from #temp_requests

/* -- for Blocked sessions only
select * from #temp_requests
WHERE blocking_session_id <> '0'
*/