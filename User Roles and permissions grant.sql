-- grant all users roles like an DB into another DB

--put source DB name in use
use devoffshore02_SafetyRepositoryCro01_01
go
declare @Destdbname varchar(255)='prod_janssenSafetyRepository_01' --destination server name

--finding the DB level roles for reference user
if object_id('dbo.##PData') is not null
Drop table dbo.##PData
CREATE TABLE ##PData
(
    UserName VARCHAR(255),
    PermissionLevel VARCHAR(255)
);

DECLARE @statement NVARCHAR(MAX);

    SELECT @statement
        = N' INSERT INTO ##PData SELECt p.name as UserName, pp.name as PermissionLevel
FROM sys.database_role_members roles
JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id
JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id';

    --print @statement
	EXEC sp_executesql @statement ;

	select  
	N'use ' + QUOTENAME(@Destdbname) + N';'+
	+'if not exists(select * from sys.database_principals where name = '''+UserName+''')'
	+ N'CREATE USER '+QUOTENAME(UserName)+' FOR LOGIN '+QUOTENAME(UserName)+N';'
	+'ALTER ROLE '+QUOTENAME(PermissionLevel)+' ADD MEMBER '+QUOTENAME(UserName)+N';' 
	from ##PData

drop table ##PData
===================================End========================




declare @DBuser varchar(500)='eplnet\ikozma'
declare @dbname varchar(500)='devoffshore02_coreAPIRepository_01'

--Check login
IF SUSER_ID (@DBuser) IS NULL
begin
declare @SqlStatementLogin nvarchar(max)=''
Select @SqlStatementLogin = 'CREATE LOGIN ' + QUOTENAME(@DBuser) + ' 
    FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]'
    EXEC sp_executesql @SqlStatementLogin
	print 'Login Created'
end
else 
begin
	print 'Login Exist'
end
--Check user
declare @SqlStatementUser nvarchar(max)=''
Select @SqlStatementUser =N'use ' + QUOTENAME(@dbname) + N';'
+'IF USER_ID('''+@DBuser+''') IS NULL' +char(13)+ N'Begin' +char(13)
+ N'CREATE USER '+QUOTENAME(@DBuser)+' FOR LOGIN '+QUOTENAME(@DBuser)+N';'
+'print ''user Created'''+';'
+char(13)+'End'+char(13)
+ 'Else'+char(13)+ 'Begin'+char(13)
+ 'EXEC sp_change_users_login ''update_one'', '''+@DBuser+''', '''+@DBuser+''''
++char(13)+'print ''User Exist'';'+char(13)+'End'
    EXEC sp_executesql @SqlStatementUser
	--print @SqlStatementUser
--Grant Roles
declare @statement nvarchar(max)=''
SELECT @statement
        = N'use ' + QUOTENAME(@dbname) + N';'         
		  +'ALTER ROLE [db_datareader] ADD MEMBER '+QUOTENAME(@DBuser)+N';'
		  +'ALTER ROLE [db_datawriter] ADD MEMBER '+QUOTENAME(@DBuser)+N';'
		  +'ALTER ROLE [db_executor] ADD MEMBER '+QUOTENAME(@DBuser)+N';';
		  --print @statement
    EXEC sp_executesql @statement ;
	
	
=============================================
USE qa_safetyReportingCro02_01
	
GO
CREATE USER [EPLNET\aosvath] FOR LOGIN [EPLNET\aosvath]
GO
ALTER ROLE [db_datareader] ADD MEMBER [EPLNET\aosvath]
ALTER ROLE [db_datawriter] ADD MEMBER [EPLNET\aosvath]
ALTER ROLE [db_executor] ADD MEMBER [EPLNET\aosvath]

--GRANT SHOWPLAN ON DATABASE::qaext_SafetyReportingAmgen_01 TO [WCGCLINICAL\zsurani]
GO

==============Multile Permissions==============

DECLARE @dbname VARCHAR(250);
DECLARE @statement NVARCHAR(MAX);
declare @DBuser nvarchar(50)=N'EPLNET\aosvath'
declare @DBRole1 nvarchar(50)=N'SharePoint_Shell_Access'
declare @DBRole2 nvarchar(50)=N'SPDataAccess'

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM master.sys.databases
WHERE name like 'dev_sp2013_devoffshore02_%'--IN ( 'dev_sp2013_devoffshore02_CentralAdmin_01' )
--name NOT IN ( 'master', 'msdb', 'model', 'tempdb' )
      AND state_desc = 'online';
OPEN db_cursor;
FETCH NEXT FROM db_cursor
INTO @dbname;
WHILE @@FETCH_STATUS = 0
BEGIN
set @statement='';
    SELECT @statement
        = N'use ' + QUOTENAME(@dbname) + N';'
          + N'CREATE USER '+QUOTENAME(@DBuser)+' FOR LOGIN '+QUOTENAME(@DBuser)+N';'
		  +'ALTER ROLE '+QUOTENAME(@DBRole1)+' ADD MEMBER '+QUOTENAME(@DBuser)+N';'
		  +'ALTER ROLE '+QUOTENAME(@DBRole2)+' ADD MEMBER '+QUOTENAME(@DBuser)+N';';
		  print @statement
    --EXEC sp_executesql @statement ;

    FETCH NEXT FROM db_cursor
    INTO @dbname;
END;
CLOSE db_cursor;
DEALLOCATE db_cursor;

==============Granting all access like an user====================

DECLARE @PrimaryUser VARCHAR(100)='EPLNET\vdobinda';-- reference user 
declare @DBuser nvarchar(100)=N'EPLNET\gpodurean' --permission needed user

-- finding the server level permissions
-- execute one by one/all
select 
 case when sp.state_desc='GRANT_WITH_GRANT_OPTION' then 'grant '+sp.permission_name+' to '+ QUOTENAME(@DBuser) +' with grant option ; '
 else sp.state_desc +' '+sp.permission_name+' to '+QUOTENAME(@DBuser)+';' end script
 ,
srp.name,sp.permission_name,state,state_desc from sys.server_permissions sp inner join 
sys.server_principals srp on sp.grantee_principal_id=srp.principal_id 
where srp.name=''+@PrimaryUser+''  and sp.type not in ('COSQ','CO'); 

--end server level permissions

--finding the DB level roles for reference user
if object_id('dbo.##PData') is not null
Drop table dbo.##PData
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
WHERE-- name  IN (' )
--name like 'dev%'
--name NOT IN ( 'master', 'msdb', 'model', 'tempdb' )
     -- AND 
	  state_desc = 'online';
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
where p.name in ('''+@PrimaryUser+''')';

    --print @statement
	EXEC sp_executesql @statement ;

    FETCH NEXT FROM db_cursor
    INTO @dbname;
END;
CLOSE db_cursor;
DEALLOCATE db_cursor;
-- End finding the DB level roles for reference user

-- granting DB level roles to user  EPLNET\gpodurean
if exists(select * from ##PData)
begin
	
	--DECLARE @dbname2 VARCHAR(250);
	--DECLARE @statement2 NVARCHAR(MAX);
	--declare @DBuser nvarchar(50)=N'EPLNET\gpodurean'
	declare @DBRole nvarchar(50)=N'db_reader'

	DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR

	select dbname,PermissionLevel from ##pdata
	OPEN db_cursor;
	FETCH NEXT FROM db_cursor
	INTO @dbname,@DBRole;
	WHILE @@FETCH_STATUS = 0
	BEGIN
	set @statement='';
		SELECT @statement
			= N'use ' + QUOTENAME(@dbname) + N';'
			+'if not exists(select * from sys.database_principals where name = '''+@DBuser+''')'
			  + N'CREATE USER '+QUOTENAME(@DBuser)+' FOR LOGIN '+QUOTENAME(@DBuser)+N';'
			  +'ALTER ROLE '+QUOTENAME(@DBRole)+' ADD MEMBER '+QUOTENAME(@DBuser)+N';'
			 
			  print @statement
		--EXEC sp_executesql @statement ;

		FETCH NEXT FROM db_cursor
		INTO @dbname,@DBRole;
	END;
	CLOSE db_cursor;
	DEALLOCATE db_cursor;
end



-- DB level permissions 

if object_id('dbo.tempPermissions') is not null
Drop table dbo.tempPermissions

Create table tempPermissions(ID int identity , Queries Varchar(255))

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM master.sys.databases
WHERE-- name  IN (' )
--name like 'dev%'
--name NOT IN ( 'master', 'msdb', 'model', 'tempdb' )
     -- AND 
	  state_desc = 'online';
OPEN db_cursor;
FETCH NEXT FROM db_cursor
INTO @dbname;
WHILE @@FETCH_STATUS = 0
BEGIN
	
select @statement
	=N'USE ' + QUOTENAME(@dbname)+N';' +N'Insert into tempPermissions(Queries)
	select dp.state_desc + ' ' 
		   + dp.permission_name collate latin1_general_cs_as
		   + ISNULL(('' ON '' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name)),'')
		   + '' TO '' + QUOTENAME(@DBuser)+';'
	   FROM sys.database_permissions AS dp
	   INNER JOIN sys.objects AS o ON dp.major_id=o.object_id
	   INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
	   INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id=dpr.principal_id
	   WHERE dpr.name NOT IN (''public'',''guest'') and dpr.name='''+@PrimaryUser+''' and dp.type not in ('COSQ','CO')';
	   print @statement
	   EXEC sp_executesql @statement
	   
FETCH NEXT FROM db_cursor
    INTO @dbname;
END;
CLOSE db_cursor;
DEALLOCATE db_cursor;

select * from tempPermissions