USE [master];

SELECT session_id ,login_name
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('uat_sp2013_chilternCTP_01')

--before kill run select script
USE [master];

DECLARE @kill varchar(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('uat_sp2013_chilternCTP_01')

EXEC(@kill);


--- rename DB--WCGHD-95943
USE [master];
GO
ALTER DATABASE StrikeforceDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
EXEC sp_renamedb 'StrikeforceDB', 'Strikeforce_2020.6'

ALTER DATABASE [Strikeforce_2020.6] SET MULTI_USER WITH ROLLBACK IMMEDIATE;

