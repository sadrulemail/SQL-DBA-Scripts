IF OBJECT_ID('tempdb.dbo.#FileSize') IS NOT NULL
    DROP TABLE #FileSize

CREATE  TABLE #FileSize
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
FROM sys.database_files;';
    
SELECT @@SERVERNAME InstanceName, dbname [DB_NAME],sum(CurrentSizeMB) DB_SIZE_MB
FROM #FileSize 
where dbname not in ('master','msdb','tempdb','model','dbadmin')
group by dbName
order by 1