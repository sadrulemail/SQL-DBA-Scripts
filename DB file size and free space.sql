USE [tempdb]
SELECT
[name]
,CONVERT(NUMERIC(10,2),ROUND([size]/128.,2)) AS [Size]
,CONVERT(NUMERIC(10,2),ROUND(FILEPROPERTY([name],'SpaceUsed')/128.,2)) AS [Used]
,CONVERT(NUMERIC(10,2),ROUND(([size]-FILEPROPERTY([name],'SpaceUsed'))/128.,2)) AS [Unused]
FROM [sys].[database_files]

--ALL Dbs size & free space

CREATE TABLE #FileSize
(dbName NVARCHAR(128), 
    FileName NVARCHAR(128), 
    type_desc NVARCHAR(128),
    CurrentSizeMB DECIMAL(10,2), 
    FreeSpaceMB DECIMAL(10,2)
);
    
INSERT INTO #FileSize(dbName, FileName, type_desc, CurrentSizeMB, FreeSpaceMB)
exec sp_msforeachdb 
'use [?]; 
 SELECT DB_NAME() AS DbName, 
        name AS FileName, 
        type_desc,
        size/128.0 AS CurrentSizeMB,  
        size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
where physical_name like ''\\PRD-NETAPP-SMB3\dce_d_sql01_userdb\%'';';
    
SELECT * 
FROM #FileSize order by FreeSpaceMB desc


--------------shrink file----
use tempdb
go
--DBCC FREEPROCCACHE --if required then execute otherwise not
--DBCC SHRINKFILE (TEMPDEV)

---check open transaction of DB-----

DBCC OPENTRAN('tempdb')

select * from sys.dm_db_task_space_usage
where internal_objects_alloc_page_count <> 0

SELECT * FROM sys.dm_tran_active_transactions
  WHERE name = N'worktable';
  
  
  --Query that returned the result set
SELECT session_id,
       SUM(internal_objects_alloc_page_count)/131072.   AS [task_internal_objects_alloc_page_count(GB)],
       SUM(internal_objects_dealloc_page_count)/131072. AS [task_internal_objects_dealloc_page_count(GB)]
FROM   sys.dm_db_task_space_usage
GROUP  BY session_id
HAVING SUM(internal_objects_alloc_page_count) > 0 

---All available connections
Declare @dbName varchar(150)
set @dbName = '[YOURDATABASENAME]'

--Total machine connections
--SELECT  COUNT(dbid) as TotalConnections FROM sys.sysprocesses WHERE dbid > 0

--Available connections
DECLARE @SPWHO1 TABLE (DBName VARCHAR(1000) NULL, NoOfAvailableConnections VARCHAR(1000) NULL, LoginName VARCHAR(1000) NULL)
INSERT INTO @SPWHO1 
    SELECT db_name(dbid), count(dbid), loginame FROM sys.sysprocesses WHERE dbid > 0 GROUP BY dbid, loginame
SELECT * FROM @SPWHO1 
--WHERE DBName = @dbName

--Running connections
DECLARE @SPWHO2 TABLE (SPID VARCHAR(1000), [Status] VARCHAR(1000) NULL, [Login] VARCHAR(1000) NULL, HostName VARCHAR(1000) NULL, BlkBy VARCHAR(1000) NULL, DBName VARCHAR(1000) NULL, Command VARCHAR(1000) NULL, CPUTime VARCHAR(1000) NULL, DiskIO VARCHAR(1000) NULL, LastBatch VARCHAR(1000) NULL, ProgramName VARCHAR(1000) NULL, SPID2 VARCHAR(1000) NULL, Request VARCHAR(1000) NULL)
INSERT INTO @SPWHO2 
    EXEC sp_who2 'Active'
SELECT * FROM @SPWHO2 
--WHERE DBName = @dbName