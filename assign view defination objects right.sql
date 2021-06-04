--Ref. Ticket#WCGHD-79631
--https://www.sqlshack.com/an-overview-of-a-view-definition-permission-in-sql-server/
---for single DB
USE dev_safetyRepositoryClient01_01
GO 
GRANT VIEW DEFINITION TO [EPLNET\cRotkiske]
--for all DBs & all users
USE master 
GO 
GRANT VIEW ANY DEFINITION TO PUBLIC
-- all dbs & single user
USE master 
GO 
GRANT VIEW ANY DEFINITION TO [EPLNET\cRotkiske]
-- single db & all users
USE DBname
GO 
GRANT VIEW ANY DEFINITION TO PUBLIC
-- single user & single object
GRANT VIEW DEFINITION on [Support].[usp_getDocumentDistributionParameters] TO [EPLNET\cRotkiske]


 

