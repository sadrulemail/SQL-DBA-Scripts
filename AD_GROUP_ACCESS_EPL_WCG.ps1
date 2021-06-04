
$DomainName = 'EPPNET-P-Temp'

$ActiveServers = ("epssqla.eplnet.wan")

$SQL = "select @@SERVERNAME as InstanceName,  name as ADGroupAccountName, 'NA' as MemberList from sys.syslogins sl
where sl.isntname = 1
and sl.isntgroup = 1
and sl.name like '%NET%'
and sl.name = 'EPLNET\eventmanagement application'
order by sl.name"

$AD_GP_ACC_MAP = ([ordered]@{
	"EPLNET\Dev_Role_Dev_DBO"="EPL_Dev_Role_Dev_DBO"
	"EPLNET\Dev_Role_SA"="EPL_Dev_Role_SA"
	"EPLNET\Dev_Role_SP_SA"="EPL_Dev_Role_SP_SA"
	"EPLNET\Dev_Role_SSIS_SA"="EPL_Dev_Role_SSIS_SA"
	"EPLNET\developers"="Epl_Developers"
	"EPLNET\epl_all_prod_fbappd_readonly"="epl_all_prod_fbappd_readonly"
	"EPLNET\ePL_HR_HROffice"="ePL_HR_HROffice"
	"EPLNET\ePL_IT_Demo_DB_Admins"="ePL_IT_Demo_DB_Admins"
	"EPLNET\ePL_IT_Demo_DB_Users"="ePL_IT_Demo_DB_Users"
	"EPLNET\ePL_IT_Dev_DB_Admins"="ePL_IT_Dev_DB_Admins"
	"EPLNET\ePL_IT_Dev_DB_AdminsWebparts360"="ePL_IT_Dev_DB_AdminsWebparts360"
	"EPLNET\ePL_IT_Dev_DB_Users"="ePL_IT_Dev_DB_Users"
	"EPLNET\ePL_IT_Dev_DB_Users_ReadOnly"="ePL_IT_Dev_DB_Users_ReadOnly"
	"EPLNET\ePL_IT_Dev_SP_Admins"="ePL_IT_Dev_SP_Admins"
	"EPLNET\ePL_IT_PERF_DB_Users"="ePL_IT_PERF_DB_Users"
	"EPLNET\ePL_IT_Prod_DB_Admins"="ePL_IT_Prod_DB_Admins"
	"EPLNET\ePL_IT_Prod_DB_DefinitionViewers"="ePL_IT_Prod_DB_DefinitionViewers"
	"EPLNET\ePL_IT_Prod_DB_Users"="ePL_IT_Prod_DB_Users"
	"EPLNET\ePL_IT_Prod_DB_Users_ReadOnly"="ePL_IT_Prod_DB_Users_ReadOnly"
	"EPLNET\ePL_IT_Prod_Net_Admins"="ePL_IT_Prod_Net_Admins"
	"EPLNET\ePL_IT_Prod_RDMUsers"="ePL_IT_Prod_RDMUsers"
	"EPLNET\ePL_IT_Prod_SP_Admins"="ePL_IT_Prod_SP_Admins"
	"EPLNET\ePL_IT_Prod_TFS_Admins"="ePL_IT_Prod_TFS_Admins"
	"EPLNET\ePL_IT_Prod_Workstation_Admins"="ePL_IT_Prod_Workstation_Admins"
	"EPLNET\ePL_IT_QA_Covance_Access"="ePL_IT_QA_Covance_Access"
	"EPLNET\epl_IT_QA_DB_TestHarness"="epl_IT_QA_DB_TestHarness"
	"EPLNET\ePL_IT_QA_DB_Users"="ePL_IT_QA_DB_Users"
	"EPLNET\ePL_IT_QA_DB_Users_ReadOnly"="ePL_IT_QA_DB_Users_ReadOnly"
	"EPLNET\ePL_IT_Stag_DB_Admins"="ePL_IT_Stag_DB_Admins"
	"EPLNET\ePL_IT_Stag_DB_ReadOnly"="ePL_IT_Stag_DB_ReadOnly"
	"EPLNET\ePL_IT_UAT_DB_Admins"="ePL_IT_UAT_DB_Admins"
	"EPLNET\ePL_IT_UAT_DB_Users"="ePL_IT_UAT_DB_Users"
	"EPLNET\ePL_IT_UAT_DB_Users_Execute"="ePL_IT_UAT_DB_Users_Execute"
	"EPLNET\ePL_IT_UAT_DB_Users_Read_Execute"="ePL_IT_UAT_DB_Users_Read_Execute"
	"EPLNET\ePL_IT_UAT_DB_Users_ReadOnly"="ePL_IT_UAT_DB_Users_ReadOnly"
	"EPLNET\ePL_IT_UAT_SP_Admins"="ePL_IT_UAT_SP_Admins"
	"EPLNET\ePL_Rater_Prod_RDMUsers"="ePL_Rater_Prod_RDMUsers"
	"EPLNET\EPS_ACI_Developers"="EPS_ACI_Developers"
	"EPLNET\ePS_Dev_Covance_DB_Read"="ePS_Dev_Covance_DB_Read"
	"EPLNET\ePS_Dev_Covance_DB_ReadWrite"="ePS_Dev_Covance_DB_ReadWrite"
	"EPLNET\eventmanagement application"="EPL_EventManagement Application"
	"EPLNET\Global_RO"="EPL_Global_RO"
	"EPLNET\RO_EPLLearn"="EPL_RO_EPLLearn"
	"EPLNET\RO_ePLLearnExtension"="EPL_RO_ePLLearnExtension"
	"EPLNET\Role_Dev_SqlAgentOperator"="EPL_Role_Dev_SqlAgentOperator"
	"EPLNET\Role_Global_DBADMINS"="EPL_Role_Global_DBADMINS"
	"EPLNET\Role_Int_SDE_Reports"="EPL_Role_Int_SDE_Reports"
	"EPLNET\Role_Perf_SurveysDB_Owner"="EPL_Role_Perf_SurveysDB_Owner"
	"EPLNET\Role_Prod_HD_RocheSupport"="EPL_Role_Prod_HD_RocheSupport"
	"EPLNET\Role_Prod_SDE_Reports"="EPL_Role_Prod_SDE_Reports"
	"EPLNET\Role_Prod_Sift_Reports"="EPL_Role_Prod_SIFT_Reports"
	"EPLNET\Role_Prod_SIFTConfiguration"="EPL_Role_Prod_SIFTConfiguration"
	"EPLNET\Role_Prod_SSO"="EPL_Role_Prod_SSO"
	"EPLNET\Role_QA_SFA_Reports"="EPL_Role_QA_SFA_Reports"
	"EPLNET\Role_QA_SurveysDB_Owner"="EPL_Role_QA_SurveysDB_Owner"
	"EPLNET\Role_UAT_CTP_Reports"="EPL_Role_UAT_CTP_Reports"
	"EPLNET\Role_UAT_SDE_Reports"="EPL_Role_UAT_SDE_Reports"
	"EPLNET\Role_UAT_SSO"="EPL_Role_UAT_SSO"
	"EPLNET\RW_ePLLearnExtension"="EPL_RW_ePLLearnExtension"
	"EPLNET\RW_Surveys"="EPL_RW_Surveys"
	"eplnet\SQLLevel3Support"="EPL_SQLLevel3Support"
	"EPLNET\WCG_IT_Prod_DB_Admins_Domain_Local"="EPL_WCG_IT_Prod_DB_Admins_Domain_Local"
		})

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
		$Info = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		"$_ --> ERROR"
		$Info = $error[$error.count-1]
		$Info = $ServerName+','+$Info+',,'
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
	}

	"`t"+'Group Acc Found: '+$Info.count

	IF ($Info.count -eq 0)
	{
		$Info = $ServerName+','+$ServerName+','+'NoGroupAccountFound'+','
		$Info = ($InfoDetails,$Info)| ConvertFrom-Csv
		#$InfoFinal+=New-Object -TypeName PSCustomObject -ArgumentList $Info
	}

	$Info | foreach-object {

		IF ($_.MemberList -eq 'NA')
		{
			$AD_GP_NAME = $_.ADGroupAccountName
			$AD_GP_NAME_NEW=$AD_GP_ACC_MAP.$AD_GP_NAME
			"`t"+'Checking Group Acc: '+$AD_GP_NAME
			IF ( $AD_GP_ACC_MAP.$AD_GP_NAME -ne $null )
			{
				$AD_GP_NAME_NEW = "WCGCLINICAL\$AD_GP_NAME_NEW"
				$SQL_Var = ("login_PSv='$AD_GP_NAME'","DBName_PSv=NULL")
				$error.clear()
				try {
					$Access=Invoke-Sqlcmd -InputFile "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AD_GROUP_ACCESS_EPL_WCG.sql" -Variable $SQL_Var -ServerInstance $ServerName -ErrorAction 'Stop'
				} Catch {
					"$_ --> ERROR"
					$Access = $error[$error.count-1]
					$Access = $ServerName+',,'+$AD_GP_NAME+',,'+$Access
					$Access = ($AccessDetails,$Access)| ConvertFrom-Csv
				}
				
				"`t"+"`t"+'Access Row Count: '+$Access.count
				IF ($Access.count -eq 0)
				{
					$Access = $ServerName+','+'NoAccessFound,'+$AD_GP_NAME+',,'
					$Access = ($AccessDetails,$Access)| ConvertFrom-Csv
				}
			}
			else {
				$AD_GP_NAME_NEW = "Not Found"
				$Access = $ServerName+','+'Server,'+$AD_GP_NAME+',,'
				$Access = ($AccessDetails,$Access)| ConvertFrom-Csv
			}
			#$Access | export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\Access.csv" -NoTypeInformation

			$Access | %{
				IF ($AD_GP_NAME_NEW -ne "Not Found")
				{
					$Command = $_.Command -replace ($AD_GP_NAME -replace '\\','\\'),$AD_GP_NAME_NEW
					$error.clear()
					try{
						Invoke-Sqlcmd -Query $Command -ServerInstance $ServerName -ErrorAction 'Stop'
						$Status="DONE"
					} catch {
						$Status=$error[$error.count-1]
					}
				}
				else {
					$Command = ""
					$Status="PENDING"
				}
				
				$AccessTmp = ([ordered]@{
					"SERVERNAME"=$_.SERVERNAME
					"AccessLevel"=$_.AccessLevel
					"Login/DBUserName"=$_."Login/DBUserName"
					"NEW_AD_GROUP"=$AD_GP_NAME_NEW
					"Role/Access"=$_."Role/Access"
					"Command"=$Command
					"Status"=$Status
				})
				
				$AccessFinal+=New-Object -TypeName PSCustomObject -Property $AccessTmp
			}
			
			IF ($AD_GP_NAME_NEW -ne "Not Found")
			{
				$SQL_Var = ("login_PSv='$AD_GP_NAME_NEW'","DBName_PSv=NULL")
				$error.clear()
				try {
					$Access=Invoke-Sqlcmd -InputFile "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AD_GROUP_ACCESS_EPL_WCG.sql" -Variable $SQL_Var -ServerInstance $ServerName -ErrorAction 'Stop'
					"`t"+"`t"+'NEW Access Row Count: '+ $Access.count+"($AD_GP_NAME_NEW)"
				} Catch {
					"`t"+"`t"+"NEW Access Row Count: ERROR"+$error[$error.count-1]+"($AD_GP_NAME_NEW)"
				}
				
			}
			else {
				"`t"+"`t"+'NEW AD Group Acc Not Found!'
			}
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
$InfoFinal |  export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\InfoFinal_$DomainName.csv" -NoTypeInformation
$AccessFinal | export-csv -path "D:\sazam\AD_GROUP_ACCOUNT\AD_GROUP_ACCESS_EPS_WCG\AccessFinal_$DomainName.csv" -NoTypeInformation
#$InfoFinal