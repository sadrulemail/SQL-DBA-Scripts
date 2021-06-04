
$DomainName = 'eplnet.wan'
$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
#$ActiveServers = ("LY01PPCT.wcgclinical.com","DB000VDCA.wcgclinical.com","SEAPWIRSDB02","DCA-T-APP02")

$SQL = "select @@SERVERNAME SERVER_NAME, ss.servertype,servername, ss.last_mod_datetime, ss.last_mod_user from msdb.dbo.sysmail_server ss"

"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('SERVER_NAME,servertype,servername,last_mod_datetime,last_mod_user')
$SMTPInfoFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_
	$error.clear()
	try{	
		$SMTPInfo = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		"$_ --> ERROR"
		$SMTPInfo = $error[$error.count-1]
		$SMTPInfo = $ServerName+',,,,'+ $SMTPInfo
		$SMTPInfo = ($InfoDetails,$SMTPInfo)| ConvertFrom-Csv
	}
	
	$SMTPInfo | foreach-object {
		$SMTPInfoTmp = ([ordered]@{
		"SERVER_NAME"= $ServerName
		"servertype"=$_.servertype
		"servername"=$_.servername
		"last_mod_datetime"=$_.last_mod_datetime
		"last_mod_user"=$_.last_mod_user
		})
		$SMTPInfoFinal+=New-Object -TypeName PSCustomObject -Property $SMTPInfoTmp
		#$JobInfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $SMTPInfo
		#$SMTPInfoTmp
	}
}
"-----------------> SMTPInfoFinal"
$SMTPInfoFinal |  export-csv -path "C:\sazam\SMTP\SMTPInfoFinal_$DomainName.csv" -NoTypeInformation
#$SMTPInfoFinal