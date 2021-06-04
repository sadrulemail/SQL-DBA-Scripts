DECLARE @Status_toEscalate VARCHAR(500) = 'DISCONNECTED,SUSPENDED,UNSYNCHRONIZED,PENDING_FAILOVER'
DECLARE @Status_toCheck TABLE (
	OrdinalPosition INT
	,[Value] VARCHAR(1000)
	)
DECLARE @privateMethod NVARCHAR(MAX)

SELECT @privateMethod = ';WITH data ([start], [end])  AS (SELECT 0 AS [start],CHARINDEX(@separator, @givenString) AS [end] UNION ALL SELECT [end] + 1, CHARINDEX(@separator, @givenString, [end] + 1) FROM data WHERE [end] > 0 )' + CHAR(10) + 'SELECT ROW_NUMBER() OVER ( ORDER BY OrdinalPosition ) OrdinalPosition, RTRIM(LTRIM(Value)) + ( CASE WHEN @returnSeparator = 1 THEN @separator ELSE '''' END ) Value' + CHAR(10) + 'FROM ( SELECT ROW_NUMBER() OVER (  ORDER BY [start] ) OrdinalPosition,  SUBSTRING(@givenString, [start], COALESCE(NULLIF([end], 0), LEN(@givenString) + 1) - [start]) Value FROM data ) r WHERE RTRIM(Value) <> '''' AND Value IS NOT NULL' + CHAR(10)

INSERT INTO @Status_toCheck (OrdinalPosition,[Value])
EXEC sp_executesql @privateMethod
	,N'@givenString varchar(8000), @separator varchar(100), @returnSeparator bit'
	,@givenString = @Status_toEscalate
	,@separator = ','
	,@returnSeparator = 0

	select * from @Status_toCheck