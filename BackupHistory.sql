select b.name Backup_name,case when b.differential_base_lsn is not null then 'DIFF' when b.type = 'D' then 'FULL' else b.type  END Backup_Type,
b.[database_name] Original_DB_Name,b.server_name Original_Server_Name,m.physical_device_name, b.compressed_backup_size,
first_lsn,last_lsn,checkpoint_lsn,database_backup_lsn,backup_start_date,backup_finish_date,
b.recovery_model, b.user_name
from msdb.dbo.backupset b
left outer join  msdb.dbo.backupmediafamily  m on m.media_set_id = b.media_set_id
where b.database_name = 'IRIS'
order by backup_start_date desc