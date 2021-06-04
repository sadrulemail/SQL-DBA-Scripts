---------------------------------------------------------------------------------------------------------------------
-- Query to show information about missing indexes
-- 
SELECT 
mdb.name as DatabaseName,
d.[statement] as DB_TableName,
gs.avg_user_impact,
gs.user_seeks,
 'use ['+replace(replace(left(d.statement,charindex('.',d.statement)-1),'[',''),']','')+'] '+
	replace
	(
	'create index IX_'
	+

	left(replace(
	replace(
	replace(replace(replace(d.statement ,'[',''),']','_'),'.','')
	+replace(replace(isnull(d.equality_columns + 
	isnull(',' + d.inequality_columns,''),d.inequality_columns)
	,'[',''),']',''),', ','')
	+'_' + convert(varchar,ROW_NUMBER() OVER(order by gs.avg_user_impact desc)) 
	,',','_')
	,125)
	+ ' on ' + replace(d.statement,left(d.statement,charindex('.',d.statement)),'') + ' (' + isnull(d.equality_columns + 
	isnull(',' + d.inequality_columns,''),d.inequality_columns) + ')' + isnull(' include (' + d.included_columns + ')','')
	,replace(replace(left(d.statement,charindex('.',d.statement)-1),'[',''),']','')
	,replace(replace(left(d.statement,charindex('.',d.statement)-1),'[',''),']',''))+char(10) as Create_Index

FROM sys.dm_db_missing_index_groups g
	JOIN sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle
	JOIN sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
	JOIN sys.databases mDB ON mDB.database_id = d.database_id
WHERE 
	gs.avg_user_impact >= 80 and
	gs.user_seeks >= 100
ORDER BY 
	gs.avg_user_impact desc

	