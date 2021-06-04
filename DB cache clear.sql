--clear all cache db instance
DBCC FREEPROCCACHE WITH NO_INFOMSGS;


USE DBNAME;
GO
-- Clear plan cache for the current database
-- New in SQL Server 2016 and SQL Azure
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
--==============================

DECLARE @intDBID INT;
SET @intDBID = (SELECT [dbid] 
                FROM master.dbo.sysdatabases 
                WHERE name = N'tbluserdb');

-- Flush the plan cache for one database only
DBCC FLUSHPROCINDB (@intDBID);