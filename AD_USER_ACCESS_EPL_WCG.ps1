
$DomainName = 'AD_USER_ACCESS_EPL_WCG'

$ActiveServers = ("DEVSQL04.eplnet.wan","DCE-D-SQL01.eplnet.wan","DCE-D-SQL02.eplnet.wan","DCE-D-SQL03.eplnet.wan","dce-q-sftdb01.eplnet.wan","dce-q-sftdb02.eplnet.wan","dce-q-sftdb03.eplnet.wan","PHLDWWCGDB03.eplnet.wan","PHLTWAIMDB01.eplnet.wan","PHLTWAIMDB02.eplnet.wan","PHLTWWCGDB01.eplnet.wan","PHLPWWCGDB01.eplnet.wan","PHLPWWCGDB21.eplnet.wan","prodsql23.eplnet.wan","dce-u-rochedb04.EPSNET.WAN","PHLOWWCGDB01.EPSNET.WAN","PHLOWWCGDB03.EPSNET.WAN","dce-u-sftdb03.EPSNET.WAN","COVSQLSPUATCL.EPSNET.WAN","dce-u-rochedb01.EPSNET.WAN","PHLQWSPFDB01.EPSNET.WAN","SFTSQLUATCL.EPSNET.WAN","dce-u-rochedb05.EPSNET.WAN","dce-u-rochedb02.EPSNET.WAN","WCGSQLUATCL.EPSNET.WAN","dce-u-rochedb03.EPSNET.WAN","PHLQWSPFDB03.EPSNET.WAN","PHLQWSPFDB02.EPSNET.WAN","PHLOWWCGDB02.EPSNET.WAN","dce-q-rochedb02.EPSNET.WAN","SFTSQLSPUATCL.EPSNET.WAN","PHLUWSFPDB03CV.EPSNET.WAN","COVSQLUATCL.EPSNET.WAN","PHLUWSFPDB03JN.EPSNET.WAN","dce-q-rochedb03.EPSNET.WAN","dce-q-rochedb01.EPSNET.WAN","COVSQLPRODCL.EPSNET.WAN","COVSQLSPPRODCL.EPSNET.WAN","DCE-P-ROCHEDB01.EPSNET.WAN","DCE-P-ROCHEDB02.EPSNET.WAN","DCE-P-ROCHEDB03.EPSNET.WAN","DCE-P-ROCHEDB04.EPSNET.WAN","DCE-P-ROCHEDB05.EPSNET.WAN","DCE-P-SFTDB03.EPSNET.WAN","JSNSQLPRODCL.EPSNET.WAN","JSNSQLSPPRODCL.EPSNET.WAN","PHLPWAIMDB01.EPSNET.WAN","PHLPWAIMDB02.EPSNET.WAN","PHLPWSFPDB03CV.EPSNET.WAN","PHLPWSFPDB03JN.EPSNET.WAN","PHLPWWCGDB01RC.EPSNET.WAN","PHLPWWCGDB09.EPSNET.WAN","PRODROCHESQL01.epsnet.wan","PRODROCHESQL03.EPSNET.WAN","PRODSQL06.EPSNET.WAN","prodsql16.EPSNET.WAN","PRODSQL17.epsnet.wan ","PRODWEB62.EPSNET.WAN","SFTSQLPRODCL.EPSNET.WAN","SFTSQLSPPRODCL.EPSNET.WAN","WCGSQLPROD02CL.EPSNET.WAN","WCGSQLPRODCL.epsnet.wan")

$SQL = "select @@SERVERNAME as InstanceName,  name as ADGroupAccountName, 'NA' as MemberList from sys.syslogins sl
where sl.isntname = 1
and sl.isntgroup = 0
and sl.name like '%NET\%'
and sl.name not like '%svc%'
and sl.name not like '%dev%'
and sl.name not like '%prod%'
and sl.name not like '%auto%'
and sl.name not like '%[0-9]%'
order by sl.name"

$AD_GP_ACC_MAP = ("eplnet\aalimov","eplnet\abeno","eplnet\abirtas","eplnet\acilikov","eplnet\aciocoet","eplnet\acseh","eplnet\adesrosiers","eplnet\airimus","eplnet\amangipudi","eplnet\amate","eplnet\amic","eplnet\amihale","eplnet\anegru","eplnet\aosvath","eplnet\arus","eplnet\atarau","eplnet\bcraciun","eplnet\bmascia","eplnet\bpatel","eplnet\candronic","eplnet\charmony","eplnet\cmaisuria","eplnet\cmalantonio","eplnet\crotkiske","eplnet\csabou","eplnet\csingeorzan","eplnet\dbodden","eplnet\dcocis","eplnet\dpop","eplnet\drunceanu","eplnet\emuncaciu","eplnet\etopali","eplnet\fakter","eplnet\fmorari","eplnet\gcostea","eplnet\gmuresan","eplnet\hrahman","eplnet\hxpatel","eplnet\ianisimov","eplnet\icorcinschi","eplnet\ilaszlo","eplnet\inasuizah","eplnet\itambur","eplnet\jhabich-a","eplnet\jrahman","eplnet\jrudics","eplnet\jwilson","eplnet\kpatel","eplnet\lchiorean","eplnet\llifeindt","eplnet\mconstantinescu","eplnet\mcotelea","eplnet\mgherman","eplnet\mquadery","eplnet\msigartau","eplnet\mszekely","eplnet\mwooden","eplnet\nkatooru","eplnet\nkhan","eplnet\ntamas","eplnet\pbahri","eplnet\pciurea","eplnet\rhezmesan","eplnet\rilut","eplnet\rlaszlo","eplnet\rnichita","eplnet\rsanchez","eplnet\rszekely","eplnet\sdumitru","eplnet\sklotz","eplnet\srandolph","eplnet\tburnham","eplnet\tchoudhury","eplnet\tkuchalakanti","eplnet\vhoskere","eplnet\vlungu","eplnet\vmarginean","eplnet\vmosan","eplnet\vplamadeala","eplnet\ychen","eplnet\ymurshed","eplnet\zsurani","eplnet\adminandy","eplnet\cgilliam","eplnet\fbobis","eplnet\igunjo","eplnet\jray","eplnet\abelogolovkin","eplnet\adaniel","eplnet\agrec","eplnet\asalagean","eplnet\asuciu","eplnet\banton","eplnet\dachim","eplnet\fhpop","eplnet\gercsei","eplnet\gilies","eplnet\gpopovici","eplnet\hcalboru","eplnet\ikozma","eplnet\jbarrett","eplnet\jdavey","eplnet\jgeorge","eplnet\malam","eplnet\nkadar","eplnet\ocebotari","eplnet\omuntea","eplnet\ozbanca","eplnet\schawla","eplnet\vholovnov","eplnet\ydeng","eplnet\abirtas-a","eplnet\aosvath-a","eplnet\azaharia","eplnet\banton-a","eplnet\bcraciun-a","eplnet\gpopovici-a","eplnet\mseydur-a","eplnet\mverba","eplnet\nmadupoju-a","eplnet\scibotaru-a","eplnet\thagen-a","eplnet\ameza","eplnet\osheremeta","eplnet\atrigunait","eplnet\avishnyakov","eplnet\dkrutahalou","eplnet\dmarzella","eplnet\pdesai","eplnet\rkhambhati","eplnet\rmarappan","eplnet\srohatgi","eplnet\sspotts","eplnet\ctschumy","eplnet\dcarter","eplnet\otudos","eplnet\sschulman","epsnet\appassure","epsnet\sbeales-a","eplnet\skoppada-a","epsnet\adminandy","epsnet\scibotaru-a","eplnet\bmundy","eplnet\sbeales","eplnet\scibotaru","eplnet\atarau-a","eplnet\mtautan","eplnet\dharper","eplnet\yhnylytskyi","eplnet\ekrajnikovich","eplnet\rnichita-a","eplnet\aievdokymov","eplnet\skoziumynskyi","eplnet\nking","eplnet\cmccabe-a","eplnet\sjackson","eplnet\skhabensky","eplnet\jhabich","eplnet\bworthington-a","eplnet\dhoupt-a","eplnet\mgedeon-a","eplnet\bsharma","eplnet\emccahey","eplnet\emoldovan","eplnet\gpodurean","eplnet\jolejnik","eplnet\jzornick","eplnet\kdeffke","eplnet\lapostol","eplnet\mbortos","eplnet\rfitzgerald","eplnet\smajer","eplnet\therwig","eplnet\kschaard","eplnet\vdobinda","epsnet\vdobinda","eplnet\ttran","eplnet\vdobinda-a","eplnet\cneal","eplnet\edintzis","eplnet\jli","eplnet\akumar","eplnet\ngeorge")

"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('SERVER_NAME,InstanceName,ADGroupAccountName,MemberList')
$AccessDetails=('SERVERNAME,AccessLevel,Login/DBUserName,Role/Access,Command')

$InfoFinal=@()
$AccessFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server ('+($ActiveServers.IndexOf($ServerName)+1)+'/'+$ActiveServers.count+'): '+$_
	$error.clear()
	try{
		$Info = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop' -QueryTimeout 65535
	} Catch {
		"$_ --> ERROR"
		$Info = $error[$error.count-1]
		$Info = $ServerName+','+$Info+',,'
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
	}

	"`t"+'User Acc Found: '+$Info.count

	IF ($Info.count -eq 0)
	{
		$Info = $ServerName+','+$ServerName+','+'NoUserAccountFound'+','
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
		#$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	}

	$Info | foreach-object {
		
		$AD_GP_NAME = $_.ADGroupAccountName
		$isUserFound = $AD_GP_ACC_MAP.IndexOf($AD_GP_NAME)
		

		IF ($_.MemberList -eq 'NA' -and $isUserFound -ne -1)
		{
			
			"`t"+'Checking User Acc : '+$AD_GP_NAME
			
			$AD_GP_NAME_NEW='WCGCLINICAL\'+$AD_GP_NAME -replace 'EPLNET\\',''
			
			$SQL_Var = ("login_PSv='$AD_GP_NAME'","DBName_PSv=NULL")
			$error.clear()
			try {
				$Access=Invoke-Sqlcmd -InputFile "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AD_GROUP_ACCESS_EPL_WCG.sql" -Variable $SQL_Var -ServerInstance $ServerName -ErrorAction 'Stop' -QueryTimeout 65535
			} Catch {
				"$_ --> ERROR"
				$Access = $error[$error.count-1]
				$Access = $ServerName+',NoAccessFound,'+$AD_GP_NAME+',,'+$Access
				$Access = ($AccessDetails,$Access)| ConvertFrom-Csv
			}
			
			"`t"+"`t"+'Access Row Count: '+$Access.count
			$AccessCountOLD=$Access.count
			IF ($Access.count -eq 0)
			{
				$Access = $ServerName+','+'NoAccessFound,'+$AD_GP_NAME+',,'
				$Access = ($AccessDetails,$Access)| ConvertFrom-Csv
			}
		
			#$Access | export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\Access.csv" -NoTypeInformation

			$Access | %{
				$Status=""
				$Command=""
				if ($_.AccessLevel -ne 'NoAccessFound')
				{
					$Command = $_.Command -replace ($AD_GP_NAME -replace '\\','\\'),$AD_GP_NAME_NEW
					$error.clear()
					try{
						Invoke-Sqlcmd -Query $Command -ServerInstance $ServerName -ErrorAction 'Stop' -QueryTimeout 65535
						$Status="DONE"
					} catch {
						$Status=$error[$error.count-1]
					}
				}
				else 
				{
					$Status="NoAccessFound"
					$Command=$_.Command				
				}
				$AccessTmp = ([ordered]@{
					"SERVERNAME"=$_.SERVERNAME
					"AccessLevel"=$_.AccessLevel
					"Login/DBUserName"=$_."Login/DBUserName"
					"NEW_AD_USER"=$AD_GP_NAME_NEW
					"Role/Access"=$_."Role/Access"
					"Status"=$Status
					"Command"=$Command
				})
				
				$AccessFinal+=New-Object -TypeName PSCustomObject -Property $AccessTmp
			}
			
			$SQL_Var = ("login_PSv='$AD_GP_NAME_NEW'","DBName_PSv=NULL")
			$error.clear()
			try {
				$Access=Invoke-Sqlcmd -InputFile "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AD_GROUP_ACCESS_EPL_WCG.sql" -Variable $SQL_Var -ServerInstance $ServerName -ErrorAction 'Stop' -QueryTimeout 65535
				"`t"+"`t"+'NEW Access Row Count: '+ $Access.count+"($AD_GP_NAME_NEW)"
			} Catch {
				"`t"+"`t"+"NEW Access Row Count: ERROR"+$error[$error.count-1]+"($AD_GP_NAME_NEW)"
			}
			$AccessCountNEW=$Access.count

		}
		else
		{
			"`t"+'User Not Found in the List '+$AD_GP_NAME	
		}

		$InfoTmp = ([ordered]@{
		"SERVERNAME"=$ServerName
		"InstanceName"=$_.InstanceName
		"ADUserAccountName"=$_.ADGroupAccountName
		"Comments"=IF($isUserFound -ne -1) {IF ($AccessCountOLD -ne $AccessCountNEW) {"ERROR"} else {"DONE"}} else {"User Not Found in the List"}
		})
		$InfoFinal+=New-Object -TypeName PSCustomObject -Property $InfoTmp
		#$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	}

	# IF ( $UserInfo.ID -like '*Disc*') {''} else {$UserInfo.SESSIONNAME}

}
"-----------------> InfoFinal"
$InfoFinal |  export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\InfoFinal_$DomainName.csv" -NoTypeInformation
$AccessFinal | export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AccessFinal_$DomainName.csv" -NoTypeInformation
# $InfoFinal