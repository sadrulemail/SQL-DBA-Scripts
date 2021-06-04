-- IF SQL SRV version is above/equal SQL 2016 RTM CU7
-- version check
--select @@VERSION, SERVERPROPERTY('ProductUpdateLevel') as CU_Version 

BACKUP DATABASE [Test] 
TO  DISK = N'c:\sql\Test.bak'
WITH NOFORMAT,
SKIP, COMPRESSION,  STATS = 10,
MAXTRANSFERSIZE = 131072
GO

-- for others
BACKUP DATABASE [Test] 
TO  DISK = N'c:\sql\Test.bak'
WITH NOFORMAT,
SKIP, COMPRESSION,  STATS = 10
GO