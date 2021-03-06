--Tempdb used space ,free space, free percent
use tempdb 
GO 
select DbName,FileName,cast(CurrentSizeMB as decimal(8,2)) as CurrentSizeMB 
,cast(SpaceUsedMB as decimal(8,2)) as SpaceUsedMB  ,cast(FreeSpaceMB as decimal(8,2)) as FreeSpaceMB ,
cast(FreeSpaceMB*100/CurrentSizeMB as decimal(8,2)) as FreePercent 
from(SELECT DB_NAME() AS DbName,
name AS FileName, 
size/128.0 AS CurrentSizeMB,  CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 as SpaceUsedMB,
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
FROM sys.database_files)t1

-- number of pages allocated session wise

use tempdb
go
select session_id,NumOfPagesAllocatedInTempDBforUserTask as Total_Pages from
(SELECT session_id,
    SUM(internal_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforInternalTask,
    SUM(internal_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforInternalTask,
    SUM(user_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforUserTask,
    SUM(user_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforUserTask
FROM sys.dm_db_task_space_usage where session_id>50
GROUP BY session_id
--ORDER BY NumOfPagesAllocatedInTempDBforInternalTask DESC, NumOfPagesAllocatedInTempDBforUserTask DESC
)t1
where NumOfPagesAllocatedInTempDBforUserTask>0