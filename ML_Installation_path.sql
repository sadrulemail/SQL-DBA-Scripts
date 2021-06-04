--Find the full path of R_SERVICES/PYTHON_SERVICES 
--R_SERVICES/PYTHON_SERVICES

SELECT TOP (1) TRIM(REPLACE(B.[value], 'MSSQL\Binn\sqlservr.exe', '')) + 'R_SERVICES\Scripts'
FROM sys.dm_server_registry A
CROSS APPLY STRING_SPLIT(REPLACE(CAST(value_data AS VARCHAR(MAX)), '"', ''), '-') B
WHERE A.registry_key LIKE 'HKLM\SYSTEM\CurrentControlSet\Services\MSSQL%'
AND A.value_name = 'ImagePath'

--select * from sys.dm_server_registry
