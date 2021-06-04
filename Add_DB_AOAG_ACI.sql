-- PRIMARY -- PHLPWAIMDB01
declare @baklocation varchar(1000) = '\\phl-svm-cifs-01.wcgclinical.com\phl_sql_non_prod_backup\WCGHD-69972'
declare @dbname varchar(1000) = 'AIMSDashboard'
declare @secondaryNode varchar(50) = 'PHLTWAIMDB02'

declare @todate varchar(10) = (select convert( varchar ,getdate(),112))
declare @fullbackuploc varchar(1000) = @baklocation +'\'+@dbname + '_FULL_'+@todate+'.bak'
declare @logbackuploc varchar(1000) = @baklocation +'\'+@dbname + '_LOG_'+@todate+'.trn'

declare @sql_fullbak varchar(4000) = '
backup database '+@dbname+'
to disk = '''+@fullbackuploc+'''
with compression'

declare @sql_logbak varchar(4000) = '
backup log '+@dbname+'
to disk = '''+@logbackuploc+''''

--print @sql_fullbak
--print @sql_logbak

exec(@sql_fullbak)
exec(@sql_logbak)
		-- Ad to AOAG - Primary
declare @AOAGGROUP varchar(50) = (select name from sys.availability_groups)
declare @AOAGSQL varchar(1000) = 'ALTER AVAILABILITY GROUP ['+@AOAGGROUP+'] MODIFY REPLICA ON N'''+@secondaryNode+''' WITH (SEEDING_MODE = MANUAL)'
	exec(@AOAGSQL)
set @AOAGSQL =  'ALTER AVAILABILITY GROUP ['+@AOAGGROUP+'] ADD DATABASE '+@dbname;
	exec(@AOAGSQL)
--ALTER AVAILABILITY GROUP [PHLPWAIMAG] MODIFY REPLICA ON N'PHLPWAIMDB02' WITH (SEEDING_MODE = MANUAL)
--ALTER AVAILABILITY GROUP [PHLPWAIMAG] ADD DATABASE AIMSDashboard

/* 
select b.name Backup_name,case when b.differential_base_lsn is not null then 'DIFF' when b.type = 'D' then 'FULL' else b.type  END Backup_Type,
b.[database_name] Original_DB_Name,b.server_name Original_Server_Name,m.physical_device_name, b.compressed_backup_size,
first_lsn,last_lsn,checkpoint_lsn,database_backup_lsn,backup_start_date,backup_finish_date,
b.recovery_model, b.user_name
from msdb.dbo.backupset b
left outer join  msdb.dbo.backupmediafamily  m on m.media_set_id = b.media_set_id
where b.database_name = 'Sanofi01'
order by  b.backup_set_id desc
*/

----------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------------

--- SECONDARY ---- PHLPWAIMDB02

declare @baklocation varchar(1000) = '\\phl-svm-cifs-01.wcgclinical.com\phl_sql_non_prod_backup\WCGHD-82093'
declare @dbname varchar(1000) = 'Sanofi01'

declare @todate varchar(10) = (select convert( varchar ,getdate(),112))
declare @fullbackuploc varchar(1000) = @baklocation +'\'+@dbname + '_FULL_'+@todate+'.bak'
declare @logbackuploc varchar(1000) = @baklocation +'\'+@dbname + '_LOG_'+@todate+'.trn'

declare @datapath varchar(1000) =  (select cast(SERVERPROPERTY('instancedefaultdatapath') as varchar(1000)))
declare @logpath varchar(1000)  = (select cast(SERVERPROPERTY('instancedefaultlogpath') as varchar(1000)))

declare @logicalFileList table (LogicalName		Varchar(1000), PhysicalName		Varchar(1000), Type		Varchar(1000), FileGroupName		Varchar(1000), Size		Varchar(1000), MaxSize		Varchar(1000), FileId		Varchar(1000), CreateLSN		Varchar(1000), DropLSN		Varchar(1000), UniqueId		Varchar(1000), ReadOnlyLSN		Varchar(1000), ReadWriteLSN		Varchar(1000), BackupSizeInBytes		Varchar(1000), SourceBlockSize		Varchar(1000), FileGroupId		Varchar(1000), LogGroupGUID		Varchar(1000), DifferentialBaseLSN		Varchar(1000), DifferentialBaseGUID		Varchar(1000), IsReadOnly		Varchar(1000), IsPresent		Varchar(1000), TDEThumbprint		Varchar(1000), SnapshotUrl		Varchar(1000))
declare @logicalFileListSQL varchar(1000)  = 'restore filelistonly from disk = '''+@fullbackuploc+''''

insert into @logicalFileList
EXEC (@logicalFileListSQL)

--select * from @logicalFileList

declare @restoreBAKSql varchar(MAX) = 'restore database '+@dbname+' from disk = '''+@fullbackuploc+''' with norecovery'
declare @restoreLOGSql varchar(MAX) = 'restore log '+@dbname+' from disk = '''+@logbackuploc+''' with norecovery'
print @datapath
select @restoreBAKSql = @restoreBAKSql +' ,MOVE '''+a.LogicalName+''' TO '''
+CASE 
WHEN a.Type = 'D' THEN @datapath+a.LogicalName+ CASE WHEN a.FileGroupName = 'PRIMARY' THEN '.mdf' ELSE '.ndf' END
WHEN a.Type = 'L' THEN @logpath++a.LogicalName+'.ldf' END
+''''
from @logicalFileList a 

print @restoreBAKSql
print @restoreLOGSql

exec(@restoreBAKSql)
exec(@restoreLOGSql)

declare @AOAGSQL varchar(1000) = ' ALTER DATABASE ['+@dbname+'] SET HADR AVAILABILITY GROUP = ['+(select name from sys.availability_groups)+'];'
 print @AOAGSQL
 -- exec (@AOAGSQL)
 -- ALTER DATABASE [Sanofi01] SET HADR AVAILABILITY GROUP = [PHLPWAIMAG];

/*
restore filelistonly
from disk = @fullbackuploc

Madrigal01	\\PRD-NETAPP-SMB3\phlpwaimdb01_userdb\Madrigal01.mdf
Madrigal01_log	\\PRD-NETAPP-SMB3\phlpwaimdb01_userlog\Madrigal01_log.ldf
*/
--select * from sys.availability_groups
--select * from  master.sys.availability_replicas
--select * from master.sys.dm_hadr_availability_replica_states