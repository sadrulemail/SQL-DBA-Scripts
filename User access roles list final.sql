CREATE TABLE ##PData
(
    ServerName VARCHAR(255),
    DBname VARCHAR(255),
    UserName VARCHAR(255),
    PermissionLevel VARCHAR(255)
);


DECLARE @dbname VARCHAR(500);
DECLARE @statement NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM master.sys.databases
WHERE name  IN ( 'uat_safetyRepositoryAmgen_01','uat_coreAPIRepository_01' )
--name NOT IN ( 'master', 'msdb', 'model', 'tempdb' )
      AND state_desc = 'online';
OPEN db_cursor;
FETCH NEXT FROM db_cursor
INTO @dbname;
WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT @statement
        = N'use ' + QUOTENAME(@dbname) + N';'
          + N' INSERT INTO ##PData SELECT

 @@servername as ServerName, db_name(db_id()) as dbname,p.name as UserName, pp.name as PermissionLevel

FROM sys.database_role_members roles

JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id

JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id
where p.name in (''EPLNET\Rnichita'',''EPLNET\Icorcinschi'')';

    EXEC sp_executesql @statement ;

    FETCH NEXT FROM db_cursor
    INTO @dbname;
END;
CLOSE db_cursor;
DEALLOCATE db_cursor;

--SELECT * FROM ##PData

--SQL server(2005+)

SELECT DISTINCT p.ServerName,p.dbname,p.UserName,
  STUFF((SELECT distinct ',' + p1.PermissionLevel
         FROM ##PData p1
         WHERE p.ServerName = p1.ServerName AND p.dbname = p1.dbname AND p.UserName = p1.UserName
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
        ,1,1,'') [Permissions]
FROM ##PData p;


--SQL server(2017+)

--SELECT r.ServerName,r.dbname,r.UserName,
--         STRING_AGG(r.PermissionLevel, ',') AS [Permissions]
--    FROM ##PData r
--GROUP BY r.ServerName,r.dbname,r.UserName

drop table ##PData