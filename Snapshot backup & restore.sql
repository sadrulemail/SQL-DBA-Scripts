
-- Create Snapshot Database
USE master
GO
CREATE DATABASE Test_snapshot ON (name='Test', filename='C:\test.ss') AS SNAPSHOT OF Test;
Go

-- restore from Snapshot 
USE master
GO
ALTER DATABASE Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE 
go
RESTORE DATABASE Test FROM DATABASE_SNAPSHOT = 'Test_snapshot';
go
ALTER DATABASE Test SET MULTI_USER WITH ROLLBACK IMMEDIATE
Go
