SELECT  'bcp StrikeforceDB.'+s.name+'.['+t.name +'] OUT T:\WCGHD-102286\Data\'+s.name+'_'+t.name+'.bcp -Ssfdatabasetest.medavante.net -T -N -b100000' as data_out,
'bcp StrikeforceDB_PRODCOPY.'+s.name+'.['+t.name +'] IN T:\WCGHD-102286\Data\'+s.name+'_'+t.name+'.bcp -Ssfdatabasetest.medavante.net -T -N -E -b100000' as data_in,
t.name AS TableName,
       s.name AS SchemaName,
       p.rows AS RowCounts,
       SUM(a.total_pages) * 8 AS TotalSpaceKB,
       CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
       SUM(a.used_pages) * 8 AS UsedSpaceKB,
       CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB,
       (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
       CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM sys.tables t
    INNER JOIN sys.indexes i
        ON t.object_id = i.object_id
    INNER JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s
        ON t.schema_id = s.schema_id
WHERE t.name NOT LIKE 'dt%'
      AND t.is_ms_shipped = 0
      AND i.object_id > 255 and p.rows>0
GROUP BY t.name,
         s.name,
         p.rows 
ORDER BY  p.rows desc
