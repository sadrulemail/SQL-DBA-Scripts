
$ActiveServers = ('DCE-P-ROCHEDB02','PHLPWLYNDB01','PHLTWAIMDB01')
#('DCE-D-SQL01.eplnet.wan','DCE-D-SQL02.eplnet.wan','DCE-D-SQL03.eplnet.wan','DCE-Q-SFTDB01.eplnet.wan','DCE-Q-SFTDB02.eplnet.wan','DCE-Q-SFTDB03.eplnet.wan','DEVSQL01.eplnet.wan','DEVSQL02.eplnet.wan','PHLDWWCGDB01.eplnet.wan','PHLPWWCGDB21.eplnet.wan','PHLTWAIMDB01.eplnet.wan','PHLTWAIMDB02.eplnet.wan','PHLTWAIMLN.eplnet.wan','PRODSQL10.eplnet.wan','PRODSQL14.eplnet.wan','PRODSQL23.eplnet.wan','TESTSQL01.eplnet.wan')

"Total Server Found in $DomainName = "+$ActiveServers.count

$SQL = "
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
DECLARE @LogStartTime NVARCHAR(100) = convert(NVARCHAR, DATEADD(HH, - 5, SYSDATETIME()), 120) -- YYYY-MM-DD HH24:MI:SS
	INSERT INTO #log_info (LogDate,ProcessInfo,LogText)
	EXEC master.dbo.xp_readerrorlog 0
		,1
		,N''
		,NULL
		,@LogStartTime
		,NULL
		,N'ASC'
select @@SERVERNAME SERVER_NAME,QA_Case,Name,Status from (
select 'Service' as [QA_Case] ,servicename as Name, status_desc Status from sys.dm_server_services
Union all
select 'Database' as [QA_Case] ,Name, state_desc collate SQL_Latin1_General_CP1_CI_AS  from sys.databases
where state <> 0
Union all
SELECT 'Cluster' as [QA_Case] ,NodeName,status_description FROM sys.dm_os_cluster_nodes
Union all
SELECT 'AOAG' as [QA_Case] ,
       ag.name  +'-'+ d.name  +'-'+  ar.replica_server_name  +'-'+  ars.role_desc +'-'+  ars.connected_state_desc
	 ,drs.synchronization_state_desc
FROM
       sys.availability_groups ag
       INNER JOIN sys.availability_replicas ar
              ON ar.group_id = ag.group_id
       INNER JOIN sys.dm_hadr_database_replica_states drs
              ON drs.replica_id = ar.replica_id
       INNER JOIN sys.databases d
              ON d.database_id = drs.database_id
		 INNER JOIN sys.dm_hadr_availability_replica_states AS ars on ars.replica_id = ar.replica_id
Union All
SELECT top 5 'SQL Log' as [QA_Case], LogDate, Error
FROM (
   SELECT LogDate
      ,[processinfo]
      ,LogText AS [MessageText]
      , LAG(LogText, 1, '') OVER (
         ORDER BY LOGID DESC
         )  AS [error]
   FROM #log_info
   ) AS ErrTable
WHERE [MessageText] LIKE 'Error%' and error not like '%login failed%'
) a"

$InfoDetails = ('SERVER_NAME,QA_Case,Name,Status')
$QA_Info_Final=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_

	$error.clear()
	try{	
		$QA_Info = Invoke-Sqlcmd -Query "$SQL" -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		$QA_Info = $error[$error.count-1]
		$QA_Info = $ServerName+',,,'+ $QA_Info
		$QA_Info = ($InfoDetails,$QA_Info)| ConvertFrom-Csv
	}
	$QA_Info_Final+= [PSCustomObject] $QA_Info
}
$QA_Info_Final |  export-csv -path "C:\sazam\QA_Info_Final.csv" -NoTypeInformation
