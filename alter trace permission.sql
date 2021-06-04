--WCGHD-79764
-- To Grant access to a Windows Login
USE Master;
GO
GRANT ALTER TRACE TO [[EPLNET\mcotelea]
GO
-- REVOKE access FROM a Windows Login
USE master;
GO
REVOKE ALTER TRACE FROM [EPLNET\mcotelea]
GO