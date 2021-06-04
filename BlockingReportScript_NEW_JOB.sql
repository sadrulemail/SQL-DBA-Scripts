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
		max(sp.lastwaittype) lastwaittype, sum(cast(sp.waittime as numeric(20,4) )) waittime, min(sp.login_time) login_time, max(sp.cmd) cmd, max(sp.program_name) program_name
		,max(dbid) dbid,max(sp.loginame) loginame,max(sp.hostname) hostname,max(sp.net_library) net_library, sum(cast(sp.cpu as numeric(20,4))) cpu, max(sp.sql_handle) sql_handle
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
,cast ( isnull(r.wait_time,sp.waittime) / (1000.0)  as numeric(20,4) ) WaitSec
,cast( r.total_elapsed_time / (1000.0)   as numeric(20,4) ) ElapsSec
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
,cast( (isnull(r.cpu_time,sp.cpu) /1000.00)   as numeric(20,4) ) AS cpu_time
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
LEFT JOIN (select con.session_id, max(con.net_transport) net_transport, sum(cast(con.num_writes as numeric(20,4))) num_writes, sum(cast(con.num_reads as numeric(20,4))) num_reads, 
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

--select * from #temp_requests

--Remove long running query records that are not blockers
DELETE FROM #temp_requests
WHERE blocking_session_id = '0'
	--AND cast ( session_id as varchar(250)) NOT IN (SELECT DISTINCT blocking_session_id FROM #temp_requests)

--Build blocking report 
IF (
	SELECT COUNT(1)
	FROM #temp_requests
	--WHERE (blocking_session_id > 0
	--	OR session_id IN (SELECT DISTINCT blocking_session_id FROM #temp_requests))
	--	AND ElapsSec > 15
   ) <> 0
BEGIN   

    DECLARE @itr                INT,
            @RecCount           INT,
            @session_id         VARCHAR(20),
            @status             VARCHAR(50),
            @blocked_by         VARCHAR(50),
            @wait_type          VARCHAR(50),
            @wait_sec           VARCHAR(50),
            @elapsed_sec        VARCHAR(50),
            @cpu_time           VARCHAR(2000) = '',
			@cmd_type			VARCHAR(100) = '',
            @query              VARCHAR(MAX) ='',
			@object				VARCHAR(500) = '',
			@execution			VARCHAR(100) = '',
            @login_name         VARCHAR(100),
            @host               VARCHAR(50),
            @app_name           VARCHAR(1000) ='',
            @final_html_msg     VARCHAR(MAX) = '',
            @tr_msg             VARCHAR(MAX) = '',
			@blk_session_count INT = 0,
			@lead_blk_sessions VARCHAR(MAX)= '',
			@blk_msg			VARCHAR(MAX) = ''

	select @blk_session_count = count(1)
	from #temp_requests tr
	where tr.blocking_session_id not like '%Lead Blocker%'

	select @lead_blk_sessions = @lead_blk_sessions + ',' + cast(tr.session_id as varchar(100))
	from #temp_requests tr
	where tr.blocking_session_id like '%Lead Blocker%'

	SET @blk_msg = '<br>Total Blocked Session: ' + cast(@blk_session_count as varchar(100)) + '<br>'+ 'Lead Blocker Session(s): '+ @lead_blk_sessions +'<br>'

	DECLARE curSession CURSOR FOR 
	SELECT session_id 
	FROM #temp_requests
	--WHERE (blocking_session_id > 0
	--	OR session_id IN (SELECT DISTINCT blocking_session_id FROM #temp_requests))
	--	AND ElapsSec > 15

	OPEN curSession

	FETCH NEXT FROM curSession INTO @itr

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @session_id		 = CAST(s.session_id AS VARCHAR(100)),
			@status          = STATUS,
			@blocked_by      = isnull(CAST(blocking_session_id AS VARCHAR(100)),''),
			@wait_type       = rtrim(isnull(LastWaitType,'')), --wait_type,
			@wait_sec        = isnull(CAST(WaitSec AS VARCHAR(100)),''),
			@elapsed_sec     = isnull(CAST(ElapsSec AS VARCHAR(100)),''),
			@cpu_time        =isnull( CAST(cpu_time AS VARCHAR(100)),''),
			@cmd_type		= rtrim(isnull(s.CommandType,'')),
			@query           = isnull(statement_text,''),
			@object			= isnull(s.DatabaseName,'') +isnull('.'+s.ObjectName, ''),
			@execution		= cast(isnull(s.Executions,0) as varchar(100)),
			@login_name      = isnull(s.login_name,''),
			@host            = isnull(s.host_name,''),
			@app_name        = rtrim(isnull(s.program_name,''))
		FROM #temp_requests AS s
		WHERE s.session_id = @itr

		DECLARE @condTd VARCHAR(500) =''				
					
		SET @condTd='<td></td>'
				
		-- > 30 sec to 1 min: Follow Up
		IF cast(@elapsed_sec AS FLOAT)  >= 30 AND CAST(@elapsed_sec AS FLOAT) <= 60 
			SET @condTd ='<td bgcolor = "#BAAF07"> Follow Up </td>'
		-- > 1 min to 1 min 30 sec: Warning 
		IF CAST(@elapsed_sec AS FLOAT) > 60 AND CAST(@elapsed_sec AS FLOAT) <= 90 
			SET @condTd ='<td bgcolor = "#FBDB0C"> Warning! </td>'
		-- > 1 min 30 sec: Kill	
		IF CAST(@elapsed_sec AS FLOAT) > 90 
			SET @condTd ='<td bgcolor = "#CD0000" style="color: white"> KILL </td>'					
		SET @tr_msg= @tr_msg + '<tr>' + @condTd + '										
									<td>' + @session_id + '</td>
									<td>' + @status + '</td>
									<td>' + @blocked_by + '</td>
									<td>' + @wait_type + '</td>
									<td>' + @wait_sec + '</td>
									<td>' + @elapsed_sec + '</td>
									<td>' + @cpu_time + '</td>
									<td>' + @cmd_type + '</td>
									<td>' + @query + '</td>
									<td>' + @object + '</td>
									<td>' + @execution + '</td>
									<td>' + @login_name + '</td>
									<td>' + @host + '</td>
									<td>' + @app_name + '</td>
								</tr>'   + CHAR(13)
		FETCH NEXT FROM curSession INTO @itr
	END

	--Clean up objects
	CLOSE curSession
	DEALLOCATE curSession
	DROP TABLE #temp_requests

	--Send the alert
	SET @final_html_msg=
	'<html> 			
		<body> 
			<h3>Blocking Query</h3> '+@blk_msg+
			'<table table border="1">
				<tbody>' +
					'<tr>' + 
					'<th>Recommendation</th>' +
					'<th>Session Id</th>' + 
					'<th>Status</th>' + 
					'<th>Blocked by</th>' +
					'<th>Wait Type</th>' + 					
					'<th>Wait Sec</th>' +                     
					'<th>Elapsed Sec</th>' + 
					'<th>CPU Time</th>' + 
					'<th>CMD Type</th>' + 
					'<th>Query</th>' +
					'<th>DB/Object Name</th>' + 
					'<th>Executions</th>' + 
					'<th>Login Name</th>' + 
					'<th>Host</th>' +                     
					'<th>Application</th>' + '</tr>' + @tr_msg + '
				</tbody>
			</table>
		</body>
	</html>'
    
	IF @final_html_msg <> ''
	BEGIN
		DECLARE @Subject VARCHAR(200) = '(TEST) - IRIS Server(' + @@SERVERNAME + ')' + ' - Blocking Query Detected!'
		EXEC msdb.dbo.sp_send_dbmail 
	  	@profile_name='SQL Job Alerts',
	 	 @copy_recipients =null,
	  	--@recipients='vvelusami@wcgclinical.com;itdba@wcgclinical.com',
		 --@recipients='relisourceits@wcgclinical.com;itdba@wcgclinical.com',
		 @recipients='sazam@medavante.com',
	 	 @subject= @Subject,
	 	 @body=@final_html_msg ,
	 	 @body_format = 'HTML' ;
	END
END
