
-- OS Last Rebooted
SELECT sqlserver_start_time FROM sys.dm_os_sys_info

EXEC sys.xp_cmdShell 'wmic os get CSName,lastbootuptime'

get-eventlog System | where-object {$_.EventID -eq "6005"} | sort -desc TimeGenerated

-- SQL Server Service last reboot

exec sp_readerrorlog 0,1,'Copyright (c)'

SELECT @SQLServiceLastRestrartDT = CONVERT(NVARCHAR (11), create_date, 23) + ' ' + CONVERT(VARCHAR (8), create_date, 108)
FROM sys.databases
WHERE rtrim(ltrim(upper([name]))) = 'TEMPDB'

SELECT login_time FROM sys.dm_exec_sessions WHERE session_id = 1

-- Event ID 17162