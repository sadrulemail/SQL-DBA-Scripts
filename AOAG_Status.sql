

SELECT name, database_id, log_reuse_wait_desc FROM sys.databases


SELECT
       ag.name AS [availability_group_name]
       , d.name AS [database_name]
       , ar.replica_server_name AS [replica_instance_name],
	   ars.role_desc,
	 ars.connected_state_desc
	 ,drs.synchronization_state_desc
       , drs.truncation_lsn
       , drs.log_send_queue_size
       , drs.redo_queue_size
FROM
       sys.availability_groups ag
       INNER JOIN sys.availability_replicas ar
              ON ar.group_id = ag.group_id
       INNER JOIN sys.dm_hadr_database_replica_states drs
              ON drs.replica_id = ar.replica_id
       INNER JOIN sys.databases d
              ON d.database_id = drs.database_id
		 INNER JOIN sys.dm_hadr_availability_replica_states AS ars on ars.replica_id = ar.replica_id
--WHERE drs.is_local=0
--AND d.name IN ('prod_rocheXML_02', 'prod_rocheCoreUserRepository_02')
ORDER BY
       ag.name ASC, d.name ASC, drs.truncation_lsn ASC, ar.replica_server_name ASC

	   
-- AOAG FailOver log
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('AlwaysOn*.xel', null, null, null)
WHERE object_name = 'error_reported'
)
SELECT data.value('(/event/@timestamp)[1]','datetime') AS [timestamp],
       data.value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
       data.value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
FROM cte_HADR
WHERE data.value('(/event/data[@name=''error_number''])[1]','int') = 1480

--Check Primary OR Secondary
DECLARE @ServerName NVARCHAR(256)  = @@SERVERNAME 
DECLARE @RoleDesc NVARCHAR(60)

SELECT @RoleDesc = a.role_desc
    FROM sys.dm_hadr_availability_replica_states AS a
    JOIN sys.availability_replicas AS b
        ON b.replica_id = a.replica_id
WHERE b.replica_server_name = @ServerName

IF @RoleDesc = 'PRIMARY'
BEGIN
	exec DBAdmin.dbo.p_shrinklog
END

	   