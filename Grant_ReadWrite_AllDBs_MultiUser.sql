DECLARE @user_names    SYSNAME = 'EPLNET\jolejnik,EPLNET\emccahey'

DECLARE @Users TABLE (
	OrdinalPosition INT
	,[Value] VARCHAR(1000)
	)
DECLARE @privateMethod NVARCHAR(MAX)
SELECT @privateMethod = ';WITH data ([start], [end])  AS (SELECT 0 AS [start],CHARINDEX(@separator, @givenString) AS [end] UNION ALL SELECT [end] + 1, CHARINDEX(@separator, @givenString, [end] + 1) FROM data WHERE [end] > 0 )' + CHAR(10) + 'SELECT ROW_NUMBER() OVER ( ORDER BY OrdinalPosition ) OrdinalPosition, RTRIM(LTRIM(Value)) + ( CASE WHEN @returnSeparator = 1 THEN @separator ELSE '''' END ) Value' + CHAR(10) + 'FROM ( SELECT ROW_NUMBER() OVER (  ORDER BY [start] ) OrdinalPosition,  SUBSTRING(@givenString, [start], COALESCE(NULLIF([end], 0), LEN(@givenString) + 1) - [start]) Value FROM data ) r WHERE RTRIM(Value) <> '''' AND Value IS NOT NULL' + CHAR(10)

INSERT INTO @Users (OrdinalPosition,[Value])
EXEC sp_executesql @privateMethod
	,N'@givenString varchar(8000), @separator varchar(100), @returnSeparator bit'
	,@givenString =  @user_names
	,@separator = ','
	,@returnSeparator = 0

	select * from @Users

declare @userName SYSNAME
declare  usersLoop cursor for select [Value] from @Users
open  usersLoop
FETCH NEXT FROM usersLoop into @userName

WHILE @@FETCH_STATUS = 0  
BEGIN

	DECLARE @SQL varchar(MAX)=''
	SELECT @SQL = @SQL +char(10)+char(10)+
	   + '--'+cast(database_id as varchar) + char(10)+'GO'+ char(10)
	+' USE ' + QUOTENAME(NAME) + char(10)+'GO'+ char(10)
	 +'print db_name() '+ char(10)+'GO'+ char(10)
	   +'CREATE USER '+QUOTENAME(@userName)+' FOR LOGIN '+QUOTENAME(@userName)+ char(10)+'GO'+ char(10)
	  -- +'GRANT CONNECT TO '+QUOTENAME(@userName)+ char(10)+'GO'+ char(10)
	   -- +'ALTER ROLE [db_datareader] ADD MEMBER '+QUOTENAME(@userName)+ char(10)+'GO'+ char(10)
	   -- +'ALTER ROLE [db_datawriter] ADD MEMBER '+QUOTENAME(@userName)+ char(10)+'GO'+ char(10)
		--+'ALTER ROLE [db_executor] ADD MEMBER '+QUOTENAME(@userName)+ char(10)+'GO'+ char(10)
		--+'EXEC sp_addrolemember N''db_owner'', N'''+@userName+''''+ char(10)+'GO'+ char(10)
		+'EXEC sp_addrolemember N''db_datareader'', N'''+@userName+''''+ char(10)+'GO'+ char(10)
		--+'EXEC sp_addrolemember N''db_datawriter'', N'''+@userName+''''+ char(10)+'GO'+ char(10)
		+'if NOT exists(select name from sys.database_principals where name = ''db_executor'' and type = ''R'') BEGIN'+ char(10)
		+'CREATE ROLE db_executor; '+ char(10)
		+'GRANT EXECUTE TO db_executor; END'+ char(10)+'GO'+ char(10)
		+'EXEC sp_addrolemember N''db_executor'', N'''+@userName+''''+ char(10)+'GO'+ char(10)
		--+'GRANT CONTROL TO ['+@userName+']'+ char(10)+'GO'+ char(10)
		--+'GRANT ALTER ON SCHEMA::DBO TO ['+@userName+']'+ char(10)+'GO'+ char(10)
	FROM   sys.databases
	WHERE  database_id > 4
		   AND state_desc = 'ONLINE'
		   and name not in ('DBAdmin') 
	order by database_id

	print ( cast(@SQL as ntext))

	FETCH NEXT FROM usersLoop into @userName
END   
CLOSE usersLoop;  
DEALLOCATE usersLoop;

-----------------
--use MSDB
--exec sp_addrolemember 'SQLAgentUserRole','EPLNET\emuncaciu'
--exec sp_addrolemember 'SQLAgentReaderRole','EPLNET\emuncaciu'
--exec sp_addrolemember 'SQLAgentOperatorRole','EPLNET\emuncaci'

--use SSISDB
--grant connect to [EPLNET\MCotelea]
--exec sp_addrolemember 'ssis_admin','EPLNET\MCotelea'
--exec sp_addrolemember 'db_owner','EPLNET\MCotele

--use master
--create login [EPLNET\MCotelea] from windows
--ALTER SERVER ROLE [sysadmin] ADD MEMBER [EPLNET\MCotelea]

--use master
--exec dbo.sp_msForEachDb 'use [?]; print db_name(); DROP SCHEMA [EPLNET\rnichita]; DROP USER [EPLNET\rnichita];'

/*
USE [SSISDB]
grant connect to [EPLNET\VHoskere]
ALTER ROLE [ssis_admin] ADD MEMBER [EPLNET\VHoskere]
*/

/*
USE [dev_coreUserRepository_01]
GO
CREATE USER [EPLNET\RSanchez] FOR LOGIN [EPLNET\RSanchez]
GO
USE [dev_coreUserRepository_01]
GO
ALTER ROLE [db_datareader] ADD MEMBER [EPLNET\RSanchez]
GO
USE [dev_coreUserRepository_01]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [EPLNET\RSanchez]
GO

use ?
go
 
GRANT CONNECT TO [EPLNET\];
 
ALTER ROLE [db_datareader] ADD MEMBER [EPLNET\]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [EPLNET\]
GO
ALTER ROLE [db_executor] ADD MEMBER [EPLNET\]
GO 


*/
