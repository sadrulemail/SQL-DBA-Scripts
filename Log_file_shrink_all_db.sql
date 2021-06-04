--DCE-D-SQL01 
--db Recovery Model check
SELECT name AS [Database Name],
recovery_model_desc AS [Recovery Model] FROM sys.databases
GO


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
WHERE type IN (0);';--0 for data files,1 for log files
    
SELECT * 
FROM #FileSize
WHERE dbName NOT IN ('distribution', 'master', 'model', 'msdb')
AND FreeSpaceMB > 100;



---Shrink DB files
USE master;
SELECT DB_NAME(database_id) DBName,
       'USE [' + DB_NAME(database_id) + '];' + 'DBCC SHRINKFILE (N''' + name + ''', 0, TRUNCATEONLY)' AS SQLcmd,
       name 'Logical Name',
       physical_name 'File Location'
INTO #T
FROM sys.master_files
WHERE state_desc = 'ONLINE'
      AND type_desc = 'LOG'
AND physical_name LIKE '\\PRD-NETAPP-SMB3\dce_d_sql01_userlog\%';


CREATE TABLE #sErrorLog
(
    dBNAME VARCHAR(255),
    sQLCMD VARCHAR(MAX),
    eRROR VARCHAR(MAX)
);

DECLARE @SQLText NVARCHAR(MAX);
DECLARE @DBName VARCHAR(MAX);
DECLARE Shrink_cursor CURSOR FOR SELECT DISTINCT DBName, SQLcmd FROM #T;
--WHERE FreeMB > 1000

OPEN Shrink_cursor;
FETCH NEXT FROM Shrink_cursor
INTO @DBName,
     @SQLText;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC (@SQLText);
    END TRY
    BEGIN CATCH
        INSERT INTO #sErrorLog
        (
            dBNAME,
            sQLCMD,
            eRROR
        )
        VALUES
        (   @DBName,        -- dBNAME - varchar(255)
            @SQLText,       -- sQLCMD - varchar(max)
            ERROR_MESSAGE() -- eRROR - varchar(max)
            );

        --PRINT @SQLText;
    END CATCH;

    FETCH NEXT FROM Shrink_cursor
    INTO @DBName, @SQLText;
END;

CLOSE Shrink_cursor;
DEALLOCATE Shrink_cursor;

--check error log
SELECT * FROM #sErrorLog

