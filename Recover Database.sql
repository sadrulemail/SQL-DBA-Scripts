DBCC CHECKDB ([StrikeforceDB], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS


10.21.64.75

use master
go
select * from sys.certificate
--select * from sys.symmetric_keys catalog
USE master;   
GO  
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'sfj5300osdVdgwdfkli7';   

BACKUP MASTER KEY TO FILE = 'c:\temp\exportedmasterkey'   
    ENCRYPTION BY PASSWORD = 'sd092735kjn$&adsg';  

USE SSISDB
RESTORE MASTER KEY FROM FILE = 'C:\DBADMIN\SSISDBkey_AIMS31-Report'
DECRYPTION BY PASSWORD = 'SS1SC@talogMKBKUP'
ENCRYPTION BY PASSWORD = 'XvcamcMWQvK2bnNh'
FORCE	
GO  

alter database [StrikeforceDB] set offline
alter database [StrikeforceDB] set online


-- Method 1
ALTER DATABASE [DBName] SET EMERGENCY;
GO
ALTER DATABASE [DBName] set single_user
GO
DBCC CHECKDB ([DBName], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS;
GO
ALTER DATABASE [DBName] set multi_user

GO


-- Method 2
ALTER DATABASE [DBName] SET EMERGENCY;

ALTER DATABASE [DBName] set multi_user

EXEC sp_detach_db '[DBName]'

EXEC sp_attach_single_file_db @DBName = '[DBName]', @physname = N'[mdf path]'

-- Method 3

ALTER DATABASE 'DATBASE NAME' SET OFFLINE WITH ROLLBACK IMMEDIATE

ALTER DATABASE 'DATBASE NAME' SET ONLINE WITH ROLLBACK IMMEDIATE