
$LoginUserName = 'sazam-a'

$AutoLogout = 'N' # Y = auto Logout from the server ; N = do not logout from the server
$IgnoreCurrentServer='Y'

$DomainNames = ('wcgclinical.com','eplnet','epsnet')
# $DomainNames = ('medavante')
# $DomainNames = ('dev-ad')

$CurrentServerName=[System.Net.DNS]::GetHostByName('').HostName

$WorkingDirectory= $PSScriptRoot
$OutputFilePath = "$WorkingDirectory\"
$OutputFileName = $OutputFilePath+'LoginServerInfo_'+$LoginUserName+'.csv'
$ServerWiseInfo=@()

"OutputFileName=$OutputFileName"

$DomainNames | foreach-object {

	$DomainName = $_

	'Listing all servers from AD'
	$Servers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
	'Server Count in $DomainName = '+ $Servers.count
	#$ActiveServers = $Servers | ForEach-Object { @{$_=(Test-Connection -ComputerName $_ -Quiet -Count 1)}} | ForEach-Object { IF ( $_.Values -eq 1) {$_.Keys} }


	'Start checking the loged in server'
	# $ActiveServers = ('DCE-D-SQL01.eplnet.wan','DCE-D-SQL02.eplnet.wan')
	$Servers | foreach-object {

		$ServerName = $_
		'Checking Server in $DomainName('+($Servers.IndexOf($ServerName)+1)+'/'+$Servers.count+'): '+$_
		
		IF ($IgnoreCurrentServer -eq 'Y' -and $ServerName -eq $CurrentServerName )
		{
			"`t`t"+"Ignored Current Server: $ServerName"
			Continue
		}
		
		$UserInfo = (quser /server:$ServerName) -replace '\s{2,}', ',' -replace '>','' | Where-Object {$_ -like '*'+$LoginUserName+'*' -OR $_ -like '*USER*'} | ConvertFrom-Csv 

		$UserInfoFinal = ([ordered]@{
		'ServerName' = $ServerName;
		'UserName' = $UserInfo.UserName;
		'UserID' = IF ( $UserInfo.ID -like '*Disc*') {$UserInfo.SESSIONNAME} else {$UserInfo.ID};
		'SessionName' = IF ( $UserInfo.ID -like '*Disc*') {''} else {$UserInfo.SESSIONNAME};
		'SessionStat' = IF ( $UserInfo.ID -like '*Disc*') {$UserInfo.ID} else {$UserInfo.STATE};
		'LoginDateTime' = IF ( $UserInfo.ID -like '*Disc*') {$UserInfo."IDLE TIME"} else {$UserInfo."LOGON TIME"};
		'AutoLogOut' = 'NA';
		})
		
		$ServerWiseInfo+=New-Object -TypeName PSCustomObject -Property $UserInfoFinal | Where-Object -property UserName -eq $LoginUserName
	}
}

$ServerWiseInfo | format-table

$ServerWiseInfo | export-csv -path $OutputFileName -NoTypeInformation
Start-process notepad $OutputFileName




