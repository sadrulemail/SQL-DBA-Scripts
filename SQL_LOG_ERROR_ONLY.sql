if OBJECT_ID('tempdb..#log_info') is not null
begin
	drop table #log_info
end

CREATE TABLE #log_info (
	LOGID int IDENTITY(1,1),
		LogDate NVARCHAR(100)
		,ProcessInfo NVARCHAR(100)
		,LogText NVARCHAR(MAX)
		)

DECLARE @LogStartTime NVARCHAR(100) = convert(NVARCHAR, DATEADD(DD, - 5, SYSDATETIME()), 120) -- YYYY-MM-DD HH24:MI:SS

	INSERT INTO #log_info (LogDate,ProcessInfo,LogText)
	EXEC master.dbo.xp_readerrorlog 0
		,1
		,N''
		,NULL
		,@LogStartTime
		,NULL
		,N'ASC'

--select convert (datetime,logdate) ,* from #log_info

SELECT *
FROM (
   SELECT LogDate
      ,[processinfo]
      ,LogText AS [MessageText]
      , LAG(LogText, 1, '') OVER (
         ORDER BY LOGID DESC
         )  AS [error]
   FROM #log_info
   ) AS ErrTable
WHERE [MessageText] LIKE 'Error%' 
-- you can change the text to filter above.

--DROP TABLE #log_info