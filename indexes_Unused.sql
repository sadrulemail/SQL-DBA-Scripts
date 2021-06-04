;WITH Index_Data as (
	SELECT
		   INDEX_DATA.object_id,
		   INDEX_DATA.index_id,
		   QUOTENAME(SCHEMA_DATA.name) +'.'+ QUOTENAME(TABLE_DATA.name) AS Table_Name,
		   INDEX_DATA.name AS Index_Name,
		   INDEX_DATA.type_desc [Type],
		   STUFF((SELECT  ', ' + COLUMN_DATA_KEY_COLS.name + ' ' + CASE WHEN INDEX_COLUMN_DATA_KEY_COLS.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END -- Include column order (ASC / DESC)
					FROM    sys.tables AS T
							INNER JOIN sys.indexes INDEX_DATA_KEY_COLS
											 ON T.object_id = INDEX_DATA_KEY_COLS.object_id
							INNER JOIN sys.index_columns INDEX_COLUMN_DATA_KEY_COLS
											 ON INDEX_DATA_KEY_COLS.object_id = INDEX_COLUMN_DATA_KEY_COLS.object_id
											AND INDEX_DATA_KEY_COLS.index_id = INDEX_COLUMN_DATA_KEY_COLS.index_id
							INNER JOIN sys.columns COLUMN_DATA_KEY_COLS
											 ON T.object_id = COLUMN_DATA_KEY_COLS.object_id
											AND INDEX_COLUMN_DATA_KEY_COLS.column_id = COLUMN_DATA_KEY_COLS.column_id
					WHERE   INDEX_DATA.object_id = INDEX_DATA_KEY_COLS.object_id
							AND INDEX_DATA.index_id = INDEX_DATA_KEY_COLS.index_id
							AND INDEX_COLUMN_DATA_KEY_COLS.is_included_column = 0
					ORDER BY INDEX_COLUMN_DATA_KEY_COLS.key_ordinal
					FOR XML PATH('')), 1, 2, '') AS Key_Column_List ,
	   STUFF(( SELECT  ', ' + COLUMN_DATA_INC_COLS.name
					FROM    sys.tables AS T
							INNER JOIN sys.indexes INDEX_DATA_INC_COLS
											 ON T.object_id = INDEX_DATA_INC_COLS.object_id
							INNER JOIN sys.index_columns INDEX_COLUMN_DATA_INC_COLS
											 ON INDEX_DATA_INC_COLS.object_id = INDEX_COLUMN_DATA_INC_COLS.object_id
							AND INDEX_DATA_INC_COLS.index_id = INDEX_COLUMN_DATA_INC_COLS.index_id
							INNER JOIN sys.columns COLUMN_DATA_INC_COLS
											 ON T.object_id = COLUMN_DATA_INC_COLS.object_id
							AND INDEX_COLUMN_DATA_INC_COLS.column_id = COLUMN_DATA_INC_COLS.column_id
					WHERE   INDEX_DATA.object_id = INDEX_DATA_INC_COLS.object_id
							AND INDEX_DATA.index_id = INDEX_DATA_INC_COLS.index_id
							AND INDEX_COLUMN_DATA_INC_COLS.is_included_column = 1
					ORDER BY INDEX_COLUMN_DATA_INC_COLS.key_ordinal
					FOR XML PATH('')), 1, 2, '') AS Include_Column_List,
			INDEX_DATA.is_primary_key,
			INDEX_DATA.is_unique_constraint,
		   INDEX_DATA.is_disabled isDisabled -- Check if index is disabled before determining which dupe to drop (if applicable)
		  -- ,*
	FROM sys.indexes INDEX_DATA
	INNER JOIN sys.tables TABLE_DATA
	ON TABLE_DATA.object_id = INDEX_DATA.object_id
	INNER JOIN sys.schemas SCHEMA_DATA
	ON SCHEMA_DATA.schema_id = TABLE_DATA.schema_id
	WHERE TABLE_DATA.is_ms_shipped = 0
	--AND INDEX_DATA.type_desc NOT IN ('NONCLUSTERED', 'CLUSTERED')
	--and TABLE_DATA.name = 'PanelMeetingAgendaItemDetail'
	AND INDEX_DATA.name is NOT NULL
) 
SELECT
	indexes.Table_Name,
    indexes.Index_Name,
	indexes.Type,
    dmis.user_seeks,
    dmis.user_scans,
	dmis.user_lookups,
    dmis.user_updates,
	Key_Column_List,
	Include_Column_List,
	isDisabled
FROM
    sys.dm_db_index_usage_stats dmis
    INNER JOIN Index_Data indexes ON indexes.index_id = dmis.index_id AND dmis.OBJECT_ID = indexes.OBJECT_ID
WHERE
    indexes.is_primary_key = 0 --This line excludes primary key constarint
    AND
    indexes.is_unique_constraint = 0 --This line excludes unique key constarint
    AND 
    dmis.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
    AND
    dmis.user_lookups = 0
    AND
    dmis.user_seeks = 0
    AND
    dmis.user_scans = 0
ORDER BY
     indexes.Table_Name,indexes.Index_Name
	 --dmis.user_updates DESC