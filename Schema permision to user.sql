
--WCGHD-74224
USE [qaext_CoreReporting_01]
GO
GRANT EXECUTE ON SCHEMA::[CoreLMSReport] TO [qaext_reporting01]
GO


/* CREATE A NEW ROLE */
CREATE ROLE db_executor

/* GRANT EXECUTE TO THE ROLE */
GRANT EXECUTE  TO db_executor

--for global permission(all schema)
REVOKE EXECUTE  TO db_executor

--for specific schema permission(all schema)
GRANT EXECUTE ON SCHEMA::dbo TO db_executor
