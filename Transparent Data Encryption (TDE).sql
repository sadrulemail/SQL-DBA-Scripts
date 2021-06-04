--take backup database where master key enabled in server

select * from sys.master_key_passwords

SELECT d.is_master_key_encrypted_by_server,*
FROM sys.databases AS d

SELECT * FROM sys.symmetric_keys 

USE master

OPEN MASTER KEY DECRYPTION BY PASSWORD = 'pass'

Backup database [StrikeforceDB]
to disk ='\\SCSSQLENT1-14T.MedAvante.net\SQLBackupStg\WCGHD-100206\StrikeforceDB_ewrmedacube-d.medavante.net_20210203.bak'
with compression

--TDE encrypt data at page level that means encrypt which data at rest i.e. data and log files
--============Implementing TDE================================
--Create Master Key
USE Master;
GO
CREATE MASTER KEY ENCRYPTION
BY PASSWORD='Sadrul!!!DBA$';
GO
--Create Certificate protected by master key
USE Master;
GO
CREATE CERTIFICATE TDE_Cert
WITH 
SUBJECT='Database_Encryption';
GO
--Create Database Encryption Key
USE <USER_DB>
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDE_Cert;
GO
--Enable Encryption on User Database Level
ALTER DATABASE <USER_DB>
SET ENCRYPTION ON;
GO
--================Backup & Restoring TDE compoments in Another Instance===================
--Backup Certificate
BACKUP CERTIFICATE TDE_Cert
TO FILE = 'D:\Sadrul\TDE\TDE_Cert'
WITH PRIVATE KEY (file='D:\Sadrul\TDE\TDE_CertKey.pvk',
ENCRYPTION BY PASSWORD='Sadrul!!!DBA$') 
--Restoring a Certificate
--First create a service master key on the secondary
USE Master;
GO
CREATE MASTER KEY ENCRYPTION
BY PASSWORD='Sadrul!!!DBA$';
GO
 
-- Restore certificate in Secondary
USE MASTER
GO
CREATE CERTIFICATE TDECert
FROM FILE = 'C:\Temp\TDE_Cert'
WITH PRIVATE KEY (FILE = 'D:\Sadrul\TDE\TDE_CertKey.pvk',
DECRYPTION BY PASSWORD = 'Sadrul!!!DBA$' );

--Now the Secondary Server is ready to restore the Encrypted backup database