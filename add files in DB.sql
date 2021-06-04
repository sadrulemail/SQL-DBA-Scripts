
USE [master]
GO
ALTER DATABASE [CSWP] ADD FILE ( NAME = N'CSWPData2', FILENAME = N'F:\DataFiles\CSWPData2.ndf' , SIZE = 4096KB , FILEGROWTH = 1024KB ) TO FILEGROUP [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [CSWP] MODIFY FILE ( NAME = N'CSWP', MAXSIZE = 2011867136KB )
GO

USE [master]
GO
ALTER DATABASE [CSWP] MODIFY FILE ( NAME = N'CSWPData2', SIZE = 104857600KB )
GO
