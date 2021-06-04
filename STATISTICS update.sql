--update single table single stats
Update STATISTICS schema_name.table_name STATISTICS_Name WITH FULLSCAN

--update single table all stats
Update STATISTICS schema_name.table_name  WITH FULLSCAN

--update all table stats with fullscan (sp_updatetats has no guaranteed way to result in a FULLSCAN for all tables)
EXEC sp_MSForEachTable 'UPDATE STATISTICS ? WITH FULLSCAN;'


-- update all table stats with fullscan
use DataExtraction01;--WCGHD-90712
go

DECLARE @tablename varchar(255),@shemaname varchar(255)
DECLARE @SQL AS NVARCHAR(1000)
DECLARE TblName_cursor CURSOR FOR
SELECT t.name,s.name FROM sys.tables t join sys.schemas s
on s.schema_id=t.schema_id

OPEN TblName_cursor

FETCH NEXT FROM TblName_cursor
INTO @tablename,@shemaname

WHILE @@FETCH_STATUS = 0
BEGIN
SET @SQL = 'UPDATE STATISTICS '+@shemaname+'.[' + @TableName + '] WITH FULLSCAN ' 
print @SQL
EXEC sp_executesql @statement = @SQL


   FETCH NEXT FROM TblName_cursor
   INTO @tablename,@shemaname
END

CLOSE TblName_cursor
DEALLOCATE TblName_cursor


--Find the outdated statistics

SELECT DISTINCT
OBJECT_SCHEMA_NAME(s.[object_id]) AS SchemaName,
OBJECT_NAME(s.[object_id]) AS TableName,
c.name AS ColumnName,
s.name AS StatName,
STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated,
DATEDIFF(d,STATS_DATE(s.[object_id], s.stats_id),getdate()) DaysOld,
dsp.modification_counter,
s.auto_created,
s.user_created,
s.no_recompute,
s.[object_id],
s.stats_id,
sc.stats_column_id,
sc.column_id
FROM sys.stats s
JOIN sys.stats_columns sc
ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id
JOIN sys.columns c ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id
JOIN sys.partitions par ON par.[object_id] = s.[object_id]
JOIN sys.objects obj ON par.[object_id] = obj.[object_id]
CROSS APPLY sys.dm_db_stats_properties(sc.[object_id], s.stats_id) AS dsp
WHERE OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1
-- AND (s.auto_created = 1 OR s.user_created = 1) -- filter out stats for indexes
ORDER BY DaysOld;