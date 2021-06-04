--WCGHD-97785
BACKUP DATABASE CSWPLOCAL TO  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_1.bak',  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_2.bak',  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_3.bak',  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_4.bak' 
WITH NOFORMAT, compression,
NOINIT,  
NAME = N'CSWPLOCAL-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

USE [master]
go
RESTORE DATABASE [CSWP3] FROM 
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_1.bak',  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_2.bak',  
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_3.bak', 
DISK = N'D:\backups\WCGHD-97785\CSWPLOCAL_4.bak' WITH  FILE = 1, 
MOVE N'AUDITS' TO N'\\sea-svm-smb3-01\devsql_userdb\DATA\CSWP3_Audit_Log.ndf', 
MOVE N'Audits2' TO N'\\sea-svm-smb3-01\devsql_userdb\DATA\CSWP3_Audit2_Log.ndf', 
MOVE N'INDEXES' TO N'\\sea-svm-smb3-01\devsql_userdb\DATA\CSWP3_Indexes.ndf', 
MOVE N'CSWP' TO N'\\sea-svm-smb3-01\devsql_userdb\DATA\CSWP3.mdf', 
MOVE N'CSWP_log' TO N'D:\MSSQL11.MSSQLSERVER\MSSQL\DATA\CSWP3_1.ldf', 
MOVE N'CSWP_log2' TO N'D:\MSSQL11.MSSQLSERVER\MSSQL\DATA\CSWP3_2.ldf',  NOUNLOAD,  STATS = 5

GO


