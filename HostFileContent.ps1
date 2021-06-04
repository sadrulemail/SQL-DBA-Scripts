$DomainName = 'eplnet.wan'

$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName

#$ActiveServers = ("DCE-P-SFTDB03.epsnet.wan","COVSQLPRODCL.epsnet.wan")

"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('IP,ServerName,InstanceName')
$InfoFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server ('+($ActiveServers.IndexOf($ServerName)+1)+'/'+$ActiveServers.count+'): '+$_
	
	try{
	$IP = ([System.Net.Dns]::GetHostAddresses("$ServerName")).IPAddressToString;
	} catch { $IP = "Host Not Found"}
	$IP = (@()+$IP)[$IP.count-1]
	#$error.clear()
	
	$InstanceName = ($ServerName -split '\.')[0]
	
	$Info = $IP+','+$ServerName+','+$InstanceName
	$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
	
	$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	
}

$InfoFinal |  export-csv -path "D:\sazam\HostFileContent\HostFileContent_$DomainName.csv" -NoTypeInformation
