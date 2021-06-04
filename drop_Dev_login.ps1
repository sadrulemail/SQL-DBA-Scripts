
$ActiveServers = ("LY01PPCT.wcgclinical.com","DB05PDCA.wcgclinical.com","DB02PDCA.wcgclinical.com","DB01PPCT.wcgclinical.com","db01pwfc.wcgclinical.com","DB08PDCA.wcgclinical.com","db04pwfc.wcgclinical.com","DB09PDCA.wcgclinical.com","FU01PPCT.wcgclinical.com")

$SQLQ="drop login [WCGCLINICAL\WCG_ITS_DBAs_DEV]"

$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_
	$error.clear()
	try{	
		$SrvInfo = Invoke-Sqlcmd -ServerInstance "$_" -Query $SQLQ  -ErrorAction 'Stop'
	} Catch {
		"$_ --> ERROR"		
	}
}
