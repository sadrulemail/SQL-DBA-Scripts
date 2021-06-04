--There are four/4 scripts
--All Log File SPACE
--------- Only Drives used in SQL Server -----
------- ALL Local Driver Space PowerShell----
---- ALL LOCAL DRIVE SPACE - tSQL
------ ALL DRIVES [MOUNTED/ATTACHED] CMD/tSQL --

/*
exec sp_configure 'show advanced option',1
reconfigure
exec sp_configure 'xp_cmdshell',1
reconfigure
exec sp_configure 'show advanced option',0
reconfigure
*/

--All Log File SPACE
DBCC SQLPERF(LOGSPACE)

select db_name(database_id) DBName, name,physical_name,type_desc,size size1,* from sys.master_files
where physical_name like 'H:\%'
order by size desc

--------- Only Drives used in SQL Server -----
SELECT DISTINCT  
		volume_mount_point [Disk Mount Point], 
		file_system_type [File System Type], 
		logical_volume_name as [Logical Drive Name], 
		CONVERT(DECIMAL(18,2),total_bytes/1073741824.0) AS [Total Size in GB], 
		CONVERT(DECIMAL(18,2),available_bytes/1073741824.0) AS [Available Size in GB],  
		CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %]
		--, *
FROM sys.master_files 
CROSS APPLY sys.dm_os_volume_stats(database_id, file_id);

------- ALL Local Driver Space PowerShell from tSQL----
/*
PS Command only 
Get-WmiObject -ComputerName "wrb-d-sql01.wirb.com" -Class Win32_Volume -Filter 'DriveType = 3' | select name,capacity,freespace | foreach{$_.name+'|'+$_.capacity/1048576+'%'+$_.freespace/1048576+'*'}
*/

declare @chkCMDShell as sql_variant
select @chkCMDShell = value from sys.configurations where name = 'xp_cmdshell'
if @chkCMDShell = 0
begin
   EXEC sp_configure 'xp_cmdshell', 1
   RECONFIGURE;
end
else
begin
   Print 'xp_cmdshell is already enabled'
end

declare @svrName varchar(255)
declare @sql varchar(400)
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--creating a temporary table
CREATE TABLE #output
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #output
EXEC xp_cmdshell @sql
--script to retrieve the values in MB from PS Script output
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
   (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) as 'capacity(MB)'
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
   (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) as 'freespace(MB)'
from #output
where line like '[A-Z][:]%'
order by drivename
--script to retrieve the values in GB from PS Script output
select drivename as DRIVE,"capacity(GB)" as 'TotalSpace (GB)',"freespace(GB)" as 'FreeSpace(GB)',round(convert(float,"freespace(GB)")/convert(float,"capacity(GB)")*100,0) as "FreeSpace(%)"
from (
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
   (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0) as "capacity(GB)"
   ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
   (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)as "freespace(GB)"
from #output
where line like '[A-Z][:]%'
) a
order by drivename
--script to drop the temporary table
drop table #output

--------------------------- ALL LOCAL DRIVE SPACE - tSQL
/*
sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Ole Automation Procedures', 1;  
GO  
RECONFIGURE;  
GO 
*/
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveSpace')
	DROP TABLE ##_DriveSpace

IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveInfo')
	DROP TABLE ##_DriveInfo


DECLARE @Result INT
	, @objFSO INT
	, @Drv INT 
	, @cDrive VARCHAR(13) 
	, @Size VARCHAR(50) 
	, @Free VARCHAR(50)
	, @Label varchar(10)

CREATE TABLE ##_DriveSpace 
	(
	 DriveLetter CHAR(1) not null
	, FreeSpace VARCHAR(10) not null

	 )

CREATE TABLE ##_DriveInfo
	(
	DriveLetter CHAR(1)
	, TotalSpace bigint
	, FreeSpace bigint
	, Label varchar(10)
	)

INSERT INTO ##_DriveSpace 
	EXEC master.dbo.xp_fixeddrives


-- Iterate through drive letters.
DECLARE curDriveLetters CURSOR
	FOR SELECT driveletter FROM ##_DriveSpace

DECLARE @DriveLetter char(1)
	OPEN curDriveLetters

FETCH NEXT FROM curDriveLetters INTO @DriveLetter
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		 SET @cDrive = 'GetDrive("' + @DriveLetter + '")' 

			EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @objFSO OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAMethod @objFSO, @cDrive, @Drv OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'TotalSize', @Size OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'FreeSpace', @Free OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'VolumeName', @Label OUTPUT 

				IF @Result <> 0 
 
					EXEC sp_OADestroy @Drv 
					EXEC sp_OADestroy @objFSO 

			SET @Size = (CONVERT(BIGINT,@Size) / 1048576 )

			SET @Free = (CONVERT(BIGINT,@Free) / 1048576 )

			INSERT INTO ##_DriveInfo
				VALUES (@DriveLetter, @Size, @Free, @Label)

	END
	FETCH NEXT FROM curDriveLetters INTO @DriveLetter
END

CLOSE curDriveLetters
DEALLOCATE curDriveLetters

PRINT 'Drive information for server ' + @@SERVERNAME + '.'
PRINT ''

-- Produce report.
SELECT DriveLetter
	, Label
	, cast(TotalSpace as decimal(10,2))/1024 AS [TotalSpace GB]
	,cast( (TotalSpace - FreeSpace) as decimal(10,2))/1024 AS [UsedSpace GB]
	,cast( FreeSpace as decimal(10,2))/1024 AS [FreeSpace GB]
	, ((CONVERT(NUMERIC(9,0),FreeSpace) / CONVERT(NUMERIC(9,0),TotalSpace)) * 100) AS [Percentage Free]

FROM ##_DriveInfo
ORDER BY [DriveLetter] ASC	
GO

DROP TABLE ##_DriveSpace
DROP TABLE ##_DriveInfo
--------------------------------

------ ALL DRIVES [MOUNTED/ATTACHED] CMD/tSQL --
declare
	@To  varchar(200) ,   
	@CRITICAL	int	 = 30	-- if the freespace(%) is less than @alertvalue, it will send message

Begin
DECLARE 	@HOSTNAME 	VARCHAR(20), 
				@HEAD		VARCHAR(100),
				@BGCOLOR	VARCHAR(50),
				@REC		VARCHAR(50),
				@PRIORITY	VARCHAR(10),
				@FREE VARCHAR(20),
				@TOTAL VARCHAR(20),
				@FREE_PER VARCHAR(20),
				@CHART VARCHAR(2000),
				@HTML VARCHAR(MAX),
				@HTMLTEMP VARCHAR(MAX),
				@TITLE VARCHAR(100),
				@DRIVE VARCHAR(100),
				@SQL VARCHAR(MAX),
				@EmailProfile NVARCHAR(100) 

SET @EmailProfile = (select top 1 name from msdb.dbo.sysmail_profile)
CREATE TABLE #MOUNTVOL (COL1 VARCHAR(500))

INSERT INTO #MOUNTVOL
EXEC XP_CMDSHELL 'MOUNTVOL'

--select * from #MOUNTVOL

DELETE #MOUNTVOL WHERE COL1 NOT LIKE '%:%'
--DELETE #MOUNTVOL WHERE COL1 LIKE '%VOLUME%'

DELETE #MOUNTVOL WHERE COL1 IS NULL
DELETE #MOUNTVOL WHERE COL1 NOT LIKE '%:%'
--DELETE #MOUNTVOL WHERE COL1 LIKE '%MOUNTVOL%'
DELETE #MOUNTVOL WHERE COL1 LIKE '%RECYCLE%'
--DELETE #MOUNTVOL WHERE COL1 LIKE '%H:\'

--SELECT LTRIM(RTRIM(COL1)) FROM #MOUNTVOL

CREATE TABLE #DRIVES
	(
		DRIVE VARCHAR(500),
		INFO VARCHAR(80)
	)

DECLARE CUR CURSOR FOR SELECT LTRIM(RTRIM(COL1)) FROM #MOUNTVOL
OPEN CUR
FETCH NEXT FROM CUR INTO @DRIVE
WHILE @@FETCH_STATUS=0 
BEGIN
	   SET	@SQL = 'EXEC XP_CMDSHELL ''FSUTIL VOLUME DISKFREE ' + @DRIVE +''''
		
		INSERT	#DRIVES
			(
				INFO
			)
		EXEC	(@SQL)

		UPDATE	#DRIVES
		SET	DRIVE = @DRIVE
		WHERE	DRIVE IS NULL
         
FETCH NEXT FROM CUR INTO @DRIVE
END         
CLOSE CUR         
DEALLOCATE CUR       

-- SHOW THE EXPECTED OUTPUT
SELECT		DRIVE,
		SUM(CASE WHEN INFO LIKE 'TOTAL # OF BYTES             : %' THEN CAST(REPLACE(SUBSTRING(INFO, 32, 48), CHAR(13), '') AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS TOTALSIZE,
		SUM(CASE WHEN INFO LIKE 'TOTAL # OF FREE BYTES        : %' THEN CAST(REPLACE(SUBSTRING(INFO, 32, 48), CHAR(13), '') AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS FREESPACE
INTO #DISKSPACE FROM		(
			SELECT	DRIVE,
				INFO
			FROM	#DRIVES
			WHERE	INFO LIKE 'TOTAL # OF %'
		) AS D
GROUP BY	DRIVE
ORDER BY	DRIVE

select *,((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 as "FREE(%)" from #DISKSPACE

select DRIVE,(TOTALSIZE/1024/1024/1024) TOTALSIZE,(FREESPACE/1024/1024/1024) FREESPACE ,((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 as "FREE(%)" from #DISKSPACE

DROP TABLE #MOUNTVOL
DROP TABLE #DRIVES
DROP TABLE #DISKSPACE

END