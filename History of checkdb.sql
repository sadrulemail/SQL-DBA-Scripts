DECLARE @curr_tracefilename VARCHAR(500); 
DECLARE @base_tracefilename VARCHAR(500); 
DECLARE @indx INT; 
SELECT @curr_tracefilename = path FROM sys.traces WHERE is_default = 1; 
SET @curr_tracefilename = REVERSE(@curr_tracefilename); 
SELECT @indx  = PATINDEX('%\%', @curr_tracefilename) ; 
SET @curr_tracefilename = REVERSE(@curr_tracefilename); 
SET @base_tracefilename = LEFT( @curr_tracefilename,LEN(@curr_tracefilename) - @indx) + '\log.trc'; 
SELECT  SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),36, PATINDEX('%executed%',TEXTData)-36) AS command 
,       LoginName 
,       StartTime 
,       CONVERT(INT,SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%found%',TEXTData)+6,PATINDEX('%errors %',TEXTData)-PATINDEX('%found%',TEXTData)-6)) AS errors 
,       CONVERT(INT,SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%repaired%',TEXTData)+9,PATINDEX('%errors.%',TEXTData)-PATINDEX('%repaired%',TEXTData)-9))  
 
repaired 
,       SUBSTRING(CONVERT(NVARCHAR(MAX),TEXTData),PATINDEX('%time:%',TEXTData)+6,PATINDEX('%hours%',TEXTData)-PATINDEX('%time:%',TEXTData)-6)+':'+SUBSTRING(CONVERT 
 
(NVARCHAR(MAX),TEXTData),PATINDEX('%hours%',TEXTData)+6,PATINDEX('%minutes%',TEXTData)-PATINDEX('%hours%',TEXTData)-6)+':'+SUBSTRING(CONVERT(NVARCHAR 
 
(MAX),TEXTData),PATINDEX('%minutes%',TEXTData)+8,PATINDEX('%seconds.%',TEXTData)-PATINDEX('%minutes%',TEXTData)-8) AS time 
FROM::fn_trace_gettable( @base_tracefilename, DEFAULT) 
WHERE EventClass = 22  
AND SUBSTRING(TEXTData,36,12) = 'DBCC CHECKDB'