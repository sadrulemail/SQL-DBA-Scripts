DECLARE @user_name    SYSNAME = 'EPLNET\inasuizah'
DECLARE @SQL varchar(MAX)=''
SELECT @SQL = @SQL +char(10)+char(10)+
   + '--'+cast(database_id as varchar) + char(10)+'GO'+ char(10)
+' USE ' + QUOTENAME(NAME) + char(10)+'GO'+ char(10)
 +'print db_name() '+ char(10)+'GO'+ char(10)
   +'CREATE USER '+QUOTENAME(@user_name)+' FOR LOGIN '+QUOTENAME(@user_name)+ char(10)+'GO'+ char(10)
  -- +'GRANT CONNECT TO '+QUOTENAME(@user_name)+ char(10)+'GO'+ char(10)
   -- +'ALTER ROLE [db_datareader] ADD MEMBER '+QUOTENAME(@user_name)+ char(10)+'GO'+ char(10)
   -- +'ALTER ROLE [db_datawriter] ADD MEMBER '+QUOTENAME(@user_name)+ char(10)+'GO'+ char(10)
	--+'ALTER ROLE [db_executor] ADD MEMBER '+QUOTENAME(@user_name)+ char(10)+'GO'+ char(10)
	--+'EXEC sp_addrolemember N''db_owner'', N'''+@user_name+''''+ char(10)+'GO'+ char(10)
	+'EXEC sp_addrolemember N''db_datareader'', N'''+@user_name+''''+ char(10)+'GO'+ char(10)
	+'EXEC sp_addrolemember N''db_datawriter'', N'''+@user_name+''''+ char(10)+'GO'+ char(10)
	+'if NOT exists(select name from sys.database_principals where name = ''db_executor'' and type = ''R'') BEGIN'+ char(10)
	+'CREATE ROLE db_executor; '+ char(10)
	+'GRANT EXECUTE TO db_executor; END'+ char(10)+'GO'+ char(10)
	+'EXEC sp_addrolemember N''db_executor'', N'''+@user_name+''''+ char(10)+'GO'+ char(10)
	--+'GRANT CONTROL TO ['+@user_name+']'+ char(10)+'GO'+ char(10)
	+'GRANT ALTER ON SCHEMA::DBO TO ['+@user_name+']'+ char(10)+'GO'+ char(10)
FROM   sys.databases
WHERE  database_id > 4
       AND state_desc = 'ONLINE'
	   and name in ('DQS_MAIN',
'DQS_PROJECTS',
'DQS_STAGING_DATA',
'SSISDB',
'qa_integration_01',
'qa_ePSIntegration_01',
'qa_Celgene_Integration_01',
'qa_integration_02',
'qa_covanceintegration_01') 
order by database_id

print ( cast(@SQL as ntext))


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
