--Find full backup missing DBs name
declare @BDate date

select @BDate=cast(getdate() as date)

select name from sys.databases db where db.name not in(select b.database_name
from  msdb.dbo.backupset b where cast(backup_start_date as date)=@BDate and b.type = 'D')



