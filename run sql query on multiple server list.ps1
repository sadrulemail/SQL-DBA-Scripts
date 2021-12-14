
$query = "Your SQL Query"
$queryPath="c:\Scripts\test.sql"
 
$csvFilePath = "c:\Scripts\queryresults.csv"
 

$instanceNameList = get-content c:\serverlist.txt
 $results=@()
  
foreach($instanceName in $instanceNameList)
{
        write-host "Executing query against server: " $instanceName
		try
		{
			$results += Invoke-Sqlcmd -Query $query -ServerInstance $instanceName -ErrorAction Stop
			#$results += Invoke-Sqlcmd -InputFile $queryPath -ServerInstance $instanceName
		}
		catch
		{
			Write-Output "Something threw an exception"
		}
}
 
# Output to CSV
 
write-host "Saving Query Results in CSV format..."
$results | export-csv  $csvFilePath   -NoTypeInformation
