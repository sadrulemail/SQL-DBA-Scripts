--WCGHD-73011
USE master;
GO

DECLARE @dbname VARCHAR(50);
DECLARE @username VARCHAR(250)='EPLNET\atarau'
DECLARE @statement NVARCHAR(MAX);

----Login create
--DECLARE @login_create VARCHAR(max)

--SET @login_create='CREATE LOGIN ['+@username+'] FROM WINDOWS'; 
--PRINT @login_create
--EXEC (@login_create)

----End login create


DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM master.dbo.sysdatabases
WHERE name NOT IN ( 'master', 'model', 'msdb', 'tempdb', 'DBAdmin' );
OPEN db_cursor;
FETCH NEXT FROM db_cursor
INTO @dbname;
WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT
	--@statement=
         N'use ' + @dbname + N';'
          + N'CREATE USER ['+@username+'] FOR LOGIN ['+@username+']; EXEC sp_addrolemember N''db_owner'', ''['+@username+']''';--EXEC sp_addrolemember N''db_datareader'', ''['+@username+']'''

		  --PRINT @statement
    EXEC sp_executesql @statement;

    FETCH NEXT FROM db_cursor
    INTO @dbname;
END;
CLOSE db_cursor;
DEALLOCATE db_cursor;

