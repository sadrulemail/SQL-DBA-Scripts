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
--WHERE DatabaseName = 'IRIS'
ORDER BY restore_date DESC