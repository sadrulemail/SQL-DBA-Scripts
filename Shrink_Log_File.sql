USE master;
SELECT DB_NAME(database_id) DBName,
       'USE ' + QUOTENAME(DB_NAME(database_id)) + ';' + 'DBCC SHRINKFILE (N''' + name + ''', 0, TRUNCATEONLY)' AS SQLcmd,
       name 'Logical Name',
       physical_name 'File Location'
INTO #T
FROM sys.master_files
WHERE state_desc = 'ONLINE'
      AND type_desc = 'LOG'
      AND physical_name LIKE '\\PRD-NETAPP-SMB3\dce_d_sql01_userlog\%';



DECLARE @SQLText NVARCHAR(MAX);

DECLARE Shrink_cursor CURSOR FOR SELECT DISTINCT SQLcmd FROM #T;
--WHERE FreeMB > 1000

OPEN Shrink_cursor;
FETCH NEXT FROM Shrink_cursor
INTO @SQLText;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC (@SQLText);
    END TRY
    BEGIN CATCH
        PRINT @SQLText;
    END CATCH;

    FETCH NEXT FROM Shrink_cursor
    INTO @SQLText;
END;

CLOSE Shrink_cursor;
DEALLOCATE Shrink_cursor;
