--Total server RAM including OS
SELECT physical_memory_kb/1024
FROM sys.dm_os_sys_info;

--SQL server RAM
SELECT name, value, value_in_use, [description] 
FROM sys.configurations
WHERE name like '%server memory%'
ORDER BY name OPTION (RECOMPILE);

--CPU/COres count
SELECT @@servername as ServerName, 
ConnectionProperty('local_net_address') [IP],
SERVERPROPERTY('ProductVersion') [Version],
SERVERPROPERTY('Edition') [Edition],
CPU=(SELECT cpu_count FROM sys.dm_os_sys_info ),
Memory=(SELECT CAST((physical_memory_in_bytes /1073741824) AS DECIMAL(3,0)) FROM sys.dm_os_sys_info)

--VV shared scripts
SELECT @@servername as ServerName, 
ConnectionProperty('local_net_address') [IP],
SERVERPROPERTY('ProductVersion') [Version],
SERVERPROPERTY('Edition') [Edition],
CPU=(SELECT cpu_count FROM sys.dm_os_sys_info ),
Memory=(SELECT CAST((physical_memory_kb /1024.0/1024.0) AS DECIMAL(3,0)) FROM sys.dm_os_sys_info)

