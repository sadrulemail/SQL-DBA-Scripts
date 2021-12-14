

$SQLInstances = Import-Csv C:\server_test.csv |% { Invoke-Command -ComputerName $_.ServerName {
 (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
 }
 }
    foreach ($sql in $SQLInstances) {
       [PSCustomObject]@{
           ServerName = $sql.PSComputerName
           InstanceName = $sql
       }
   }
   
$SQLInstances = Invoke-Command -ComputerName hqdbt01,hqdbsp17 {
 (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
 }
    foreach ($sql in $SQLInstances) {
       [PSCustomObject]@{
           ServerName = $sql.PSComputerName
           InstanceName = $sql
       } |  export-csv  C:\results.csv   -NoTypeInformation -Append 
   }
   
