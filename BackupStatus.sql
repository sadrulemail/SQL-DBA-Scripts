-- Any BACKUP & RESTORE Status
SELECT r.session_id , sp.loginame
,DB_NAME(r.database_id) [Database]
    ,r.command 
    ,CONVERT(NUMERIC(32, 2), r.percent_complete)  [Complete (%)]
    ,GETDATE()  [Current Database Time]
    ,CONVERT(NUMERIC(32, 2), r.total_elapsed_time / 1000.0 / 60.0) [Running Time (Minute)]
    ,CONVERT(NUMERIC(32, 2), r.estimated_completion_time / 1000.0 / 60.0) [Required Time (Minute)]
	,(select t.text FROM sys.dm_exec_sql_text(r.sql_handle) t ) 'Statement text'
FROM master.sys.dm_exec_requests r
left join sys.sysprocesses sp on sp.spid = r.session_id and ltrim(sp.loginame) <> ''
WHERE command like 'RESTORE%'
or  command like 'BACKUP%'

-- 
SELECT r.session_id,r.command,CONVERT(NUMERIC(6,2),r.percent_complete)
AS [Percent Complete],CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0) AS [ETA Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours],
CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,r.statement_start_offset/2,
CASE WHEN r.statement_end_offset = -1 THEN 1000 ELSE (r.statement_end_offset-r.statement_start_offset)/2 END)
FROM sys.dm_exec_sql_text(sql_handle)))
FROM sys.dm_exec_requests r WHERE command 
IN ('UPDATE STATISTICS', 'DbccFilesCompact', 'DbccLOBCompact', 'ALTER INDEX', 'DBCC', 'CREATE INDEX', 
'RESTORE DATABASE', 'BACKUP DATABASE')



-- Last Restore History
WITH LastRestores
AS (SELECT
  DatabaseName = [d].[name],
  [d].[create_date],
  [d].[compatibility_level],
  [d].[collation_name],
  r.destination_Database_Name dest_db_name,
  r.Restore_Date,
  r.User_Name,
  r.Original_server_name  org_srv_name,
  r.Original_DB_Name org_db_name,
  r.physical_device_name bak_file_loc,
--  r.*,
  RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN (SELECT
			  b.Backup_name,
			  b.physical_device_name,
			  b.Original_DB_Name,
			  b.Original_Server_Name,
			  r.*
			FROM msdb.dbo.[restorehistory] r
			INNER JOIN (SELECT
						b.backup_set_id,
						b.name Backup_name,
						m.physical_device_name,
						b.[database_name] Original_DB_Name,
						b.server_name Original_Server_Name
					FROM msdb.dbo.backupset b
					INNER JOIN msdb.dbo.backupmediafamily m
						ON m.media_set_id = b.media_set_id) b
			  ON r.backup_set_id = b.backup_set_id) r
  ON r.[destination_database_name] = d.Name)
SELECT
  *
FROM [LastRestores]
--WHERE [RowNum] = 1
ORDER BY restore_date DESC

-- All Backup History

--BACKUP History


select b.name Backup_name,case when b.differential_base_lsn is not null then 'DIFF' when b.type = 'D' then 'FULL' else b.type  END Backup_Type,
b.[database_name] Original_DB_Name,b.server_name Original_Server_Name,m.physical_device_name, b.compressed_backup_size,
first_lsn,last_lsn,checkpoint_lsn,database_backup_lsn,backup_start_date,backup_finish_date,
b.recovery_model, b.user_name
from msdb.dbo.backupset b
left outer join  msdb.dbo.backupmediafamily  m on m.media_set_id = b.media_set_id
where b.database_name = 'IRIS'
order by  b.backup_set_id desc


SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description ,*
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_finish_date