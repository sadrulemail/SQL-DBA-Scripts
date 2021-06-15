USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_Send_DiskSpace_SMB3]    Script Date: 5/20/2020 12:03:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE proc [dbo].[USP_Send_DiskSpace_SMB3] 
--
(
	@To  varchar(200) ,   
	@CRITICAL	int	 = 30	-- if the freespace(%) is less than @alertvalue, it will send message
)
as
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


SELECT DISTINCT 
		volume_mount_point [Disk Mount Point], 
		file_system_type [File System Type], 
		logical_volume_name as [Logical Drive Name], 
		CONVERT(DECIMAL(18,2),total_bytes/1073741824.0) AS [Total Size in GB], 
		CONVERT(DECIMAL(18,2),available_bytes/1073741824.0) AS [Available Size in GB],  
		CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 
INTO #DISKSPACE
FROM sys.master_files 
CROSS APPLY sys.dm_os_volume_stats(database_id, file_id) ;



SET @TITLE = 'DISK SPACE (SMB) REPROT : '+ @@SERVERNAME

SET @HTML = '<HTML><TITLE>'+@TITLE+'</TITLE>
<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2>
 <TR BGCOLOR=#0070C0 ALIGN=CENTER STYLE=''FONT-SIZE:8.0PT;FONT-FAMILY:"TAHOMA","SANS-SERIF";COLOR:WHITE''>
  <TD WIDTH=40><B>Disk Mount Point</B></TD>
  <TD WIDTH=40><B>File System Type</B></TD>
  <TD WIDTH=40><B>Logical Drive Name</B></TD>
  <TD WIDTH=250><B>Total Size in GB</B></TD>
  <TD WIDTH=150><B>Available Size in GB</B></TD>
  <TD WIDTH=150><B>Space Free %</B></TD>
</TR>'

DECLARE	RECORDS CURSOR 
FOR SELECT CAST([Disk Mount Point] AS VARCHAR(100)) AS 'DRIVE',
[File System Type],
[Logical Drive Name],
cast( [Total Size in GB]  AS VARCHAR(10)) as [Total Size in GB],
cast([Available Size in GB] AS VARCHAR(10)) as [Available Size in GB],
--[Space Free %], 
CONVERT(VARCHAR(2000),'<TABLE BORDER=0 ><TR><TD BORDER=0 BGCOLOR='+ CASE WHEN [Space Free %] < @CRITICAL  
    THEN 'RED'
WHEN [Space Free %] > 70  
    THEN '66CC00'
   ELSE  
    '0033FF'
   END +'><IMG SRC=''/GIFS/S.GIF'' WIDTH='+CAST(CAST([Space Free %]*2 AS INT) AS CHAR(10) )+' HEIGHT=5></TD>
     <TD><FONT SIZE=1>'+CAST(CAST([Space Free %] AS INT) AS CHAR(10) )+'%</FONT></TD></TR></TABLE>') AS 'CHART' 
	FROM #DISKSPACE ORDER BY [Space Free %]

OPEN RECORDS

declare @File_System_Type varchar(10),@Logical_Drive_Name varchar(400)


FETCH NEXT FROM RECORDS INTO @DRIVE, @File_System_Type,@Logical_Drive_Name,@TOTAL, @FREE, @CHART 
		
WHILE @@FETCH_STATUS = 0

BEGIN

	SET @HTMLTEMP = 
		'<TR BORDER=0 BGCOLOR="#E8E8E8" STYLE=''FONT-SIZE:8.0PT;FONT-FAMILY:"TAHOMA","SANS-SERIF";COLOR:#0F243E''>
		<TD ALIGN = CENTER>'+@DRIVE+'</TD>
		<TD ALIGN = CENTER>'+@File_System_Type+'</TD>
		<TD ALIGN = CENTER>'+@Logical_Drive_Name+'</TD>
		<TD ALIGN=CENTER>'+@TOTAL+'</TD>
		<TD ALIGN=CENTER>'+@FREE+'</TD>
		<TD  VALIGN=MIDDLE>'+@CHART+'</TD>
		</TR>'
		
		SET @HTML = @HTML +	@HTMLTEMP
		
	FETCH NEXT FROM RECORDS INTO @DRIVE, @File_System_Type,@Logical_Drive_Name,@TOTAL, @FREE, @CHART 

END
CLOSE RECORDS
DEALLOCATE RECORDS


--SET @HTML = @HTML + '</TABLE><BR>
--<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>FREE PERCENT - RED NEEDS TO BE ADDRESS ASAP.</B></SPAN></P>
--<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>THANKS,</B></SPAN></P>
--<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>DBA TEAM</B></SPAN></P>
--</HTML>'


SET @HTML = @HTML + '</TABLE><BR>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B> SUBJECT: Disk Alert for Database Server </B></SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>GENERAL INFORMATION: </B></SPAN></P>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>ESCALATION: DBA (itdba@wcgclinical.com) </B></SPAN></P>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>SYSTEM: Database server   </B></SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>DEVELOPER: N/A    </B></SPAN></P>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>APPLICATION NAME: N/A   </B></SPAN></P>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>URGENCY: High, Please Contact DBA Team.   </B></SPAN></P>
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>AFFECTED BUSINESS UNIT:    </B></SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''> Applications will be impacted that connect to SQL Databases  </SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''>Disk Space is low on drives seen above  </SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>TROUBLESHOOTING STEPS: 
</B></SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''>
There are no predetermined troubleshooting steps for this alert. The database administrator needs to analyze the server environment to identify what caused the storage issue at the time of the alert

</SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B> 
Thank you,

</B></SPAN></P>

<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B> 
Database Support 

</B></SPAN></P>
</HTML>'


set @head = 'Disk Space(SMB) report: '+@@servername

--SELECT * FROM #DISKSPACE

IF EXISTS(SELECT * FROM #DISKSPACE WHERE CAST([Space Free %] AS INT) <= @CRITICAL)
	BEGIN
		SET @PRIORITY = 'HIGH'
		
		print @head
		exec msdb.dbo.sp_send_dbmail    
		@profile_name = @EmailProfile,    
		@recipients = @To,   
		@subject = @head,
		@importance =  @Priority,  
		@body = @HTML,    
		@body_format = 'HTML'

	END	
	ELSE
	BEGIN	
		print''
	END

DROP TABLE #DISKSPACE

END






GO

