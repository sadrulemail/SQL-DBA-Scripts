
$DomainName = 'EPLNET'
#$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
$ActiveServers = ("DEVSQL07.eplnet.wan","DEVWEB32.eplnet.wan","DEVSQL04.eplnet.wan","DCE-D-SQL01.eplnet.wan","DCE-D-SQL02.eplnet.wan","DCE-D-SQL03.eplnet.wan","dce-q-sftdb01.eplnet.wan","dce-q-sftdb02.eplnet.wan","dce-q-sftdb03.eplnet.wan","PHLDWWCGDB03.eplnet.wan","PHLTWAIMDB01.eplnet.wan","PHLTWAIMDB02.eplnet.wan","PHLTWAIMCL01.eplnet.wan","PHLTWWCGDB01.eplnet.wan")#,"DB02VDCA.wcgclinical.com","DB01VDCA.wcgclinical.com","DB18VDCA.wcgclinical.com","db17vwfc.wcgclinical.com","DB19VDCA.wcgclinical.com","db01vwfc.wcgclinical.com","WCGLC01VL.wcgclinical.com","dce-t-twdb01.wcgclinical.com","DCA-T-APP02.wcgclinical.com","SEADWDCMDB01.wcgclinical.com","SEAQWDCMDB01.wcgclinical.com","SEAQWDCMDB02.wcgclinical.com","SEAQWDCMCL01.wcgclinical.com","SEAQWDCMLN.wcgclinical.com","SEAQWIRSDB02.wcgclinical.com","SEAQWIRSDB01.wcgclinical.com","SEAQWIRSCL01.wcgclinical.com","PHLDWACIDB01.wcgclinical.com","SEAQWIRSLN.wcgclinical.com","SEANWDCMDB01.wcgclinical.com","SEANWIRSDB01.wcgclinical.com","SEAVWIRSDB01.wcgclinical.com","PHLDWWCGDB04.wcgclinical.com")

$SQL = "select @@SERVERNAME as InstanceName,  name as ADGroupAccountName, 'NA' as MemberList from sys.syslogins sl
where sl.isntname = 1
and sl.isntgroup = 1
and sl.name like '%NET%'
order by sl.name"

"Total Server Found in $DomainName = "+$ActiveServers.count

$InfoDetails = ('SERVER_NAME,InstanceName,ADGroupAccountName,MemberList')
$InfoFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_
	$error.clear()
	try{
		$Info = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		"$_ --> ERROR"
		$Info = $error[$error.count-1]
		$Info = $ServerName+','+$Info+',,'
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
	}

	'Group Acc Found: '+$Info.count

	IF ($Info.count -eq 0)
	{
		$Info = $ServerName+','+$ServerName+','+'NoGroupAccountFound'+','
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
		#$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	}

	$Info | foreach-object {

		IF ($_.MemberList -eq 'NA')
		{
			$ADGroupAccountName = $_.ADGroupAccountName
			$ADGroupDomain = ($ADGroupAccountName -split '\\')[0]
			$ADGroupNameOnly = ($ADGroupAccountName -split '\\')[1]
			$members = ''
			try {
				$members = Get-ADGroupMember -Identity $ADGroupNameOnly -server $ADGroupDomain | Select-Object SamAccountName, objectClass , distinguishedName
				$members = $members | foreach-object {
					($_.distinguishedName -split ',DC=')[1]+'\'+$_.SamAccountName+' ('+$_.objectClass+')'
					}
				$members = $members -join '|'
			}
			catch {
				try {
					#$members = $ADGroupAccountName+' not found in '+$ADGroupDomain+' domain!'
					$members =	(Get-ADGroup -Identity $ADGroupNameOnly -Properties Member -server $ADGroupDomain | Select-Object Member).Member
					$userInfoFinal = @()
					$members | foreach-object {
							$member = $_
							$name = ($member -split 'CN=' -split ',')[1]
							$ADTrust = Get-ADTrust -Filter  * -server $ADGroupDomain | select-object Name
							$userInfo = Get-ADObject $member -server $ADGroupDomain  -properties * | select-object SamAccountName, objectClass , distinguishedName
							#$name +' --> '+$userInfo.objectClass
							IF ($userInfo.objectClass -eq 'foreignSecurityPrincipal')
							{
								$ADTrust | foreach-object {
									IF ($userInfo.objectClass -eq 'foreignSecurityPrincipal' -or $userInfo.count -eq 0)
									{
										$userInfo = Get-ADUser -Filter * -server $_.Name | Where-Object -Property SID -like "$name" | select-object SamAccountName, objectClass , distinguishedName
										#$name +' --> '+$userInfo.objectClass
									}	
								}
							}
							#$userInfo
							$userInfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $userInfo
					}
					$members = $userInfoFinal | foreach-object {
						($_.distinguishedName -split ',DC=')[1]+'\'+$_.SamAccountName+' ('+$_.objectClass+')'
						}
					$members = $members -join '|'
				}
				catch {
					$members = $ADGroupAccountName+' not found in '+$ADGroupDomain+' domain!'	
				}
			}

			IF ($members -eq '') {
				$members = 'No Members added yet!'
			}

			$_.MemberList = $members
			#$_.ADGroupAccountName+' -- '+$_.MemberList
		}

		$InfoTmp = ([ordered]@{
		"SERVERNAME"=$ServerName
		"InstanceName"=$_.InstanceName
		"ADGroupAccountName"=$_.ADGroupAccountName
		"MemberList"=$_.MemberList
		})
		$InfoFinal+=New-Object -TypeName PSCustomObject -Property $InfoTmp
		#$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	}

	# IF ( $UserInfo.ID -like '*Disc*') {''} else {$UserInfo.SESSIONNAME}

}
"-----------------> InfoFinal"
$InfoFinal |  export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACC_DETAILS_$DomainName.csv" -NoTypeInformation
#$InfoFinal