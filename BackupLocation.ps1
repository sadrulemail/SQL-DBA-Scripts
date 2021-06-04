
#$DomainName = 'eplnet.wan'
#$ActiveServers = Get-ADComputer -Server $DomainName -Filter { OperatingSystem -Like '*Windows Server*' } -Properties OperatingSystem | select -ExpandProperty DNSHostName
$ActiveServers = ("EWRSPPWD.MedAvante.net","EWRSPDB1.MedAvante.net","EWR-DBOX1-P.MedAvante.net","EWRSMARTDB1.MedAvante.net","EWRQCDBUAT.MedAvante.net","EWRMEDACUBE.MedAvante.net","EWRSYSAID.MedAvante.net","EWRREPORT2.MedAvante.net","EWRMEDACUBE-D.MedAvante.net","EWRSFWEB-TSTI.MedAvante.net","EWRTFS.MedAvante.net","MEDAVC1.MedAvante.net","SCSSFWEB1-QAI.MedAvante.net","SCSSQLDEV1-14T.MedAvante.net","SCSSQLSTD1-14I.MedAvante.net","SCSSQLENT1-14T.MedAvante.net","SCSSQLENT1-14P.MedAvante.net","DLSSQLQCDB-14M.MedAvante.net","EWRSFWEB-TSTFI.MedAvante.net","SCSSQLDEV1-14PT.MedAvante.net","SCSSFDB01-PT.MedAvante.net","SCSSFDB02-PT.MedAvante.net","SCSSFDBCLU-PT.MedAvante.net","SCSSFDB01-P.MedAvante.net","SCSSFDB02-P.MedAvante.net","SCSSFDBCLU-P.MedAvante.net","SCSSFDB01-TR.MedAvante.net","SCSDWSFDB01.MedAvante.net","SCSSWSFDB01.MedAvante.net","SCSTWSFDB01.MedAvante.net","DLSPWSFDB01-P.MedAvante.net","SCSTWSFDB02.MedAvante.net","SCSPWITSDB01.MedAvante.net","SCSPWCNDB02.MedAvante.net","SCSPWCNDB01.MedAvante.net","SCSPWCNDBCL.MedAvante.net","SCSPWCNDBLN.MedAvante.net")

$SQL = "select Backup_Type,backup_path,max(back_date) back_date
from(
select case when b.differential_base_lsn is not null then 'DIFF' when b.type = 'D' then 'FULL' else b.type  END Backup_Type,
left(m.physical_device_name, len(m.physical_device_name)-charindex('\',reverse(m.physical_device_name))) backup_path,
convert(varchar,backup_start_date ,112) back_date
from msdb.dbo.backupset b
left outer join  msdb.dbo.backupmediafamily  m on m.media_set_id = b.media_set_id
--order by backup_start_date desc
) a
where back_date like '2020%'
group by Backup_Type,backup_path
order by 3 desc"

"Total Server Found in $DomainName = "+$ActiveServers.count

#$InfoDetails = ('SERVER_NAME,SQLVersion,ProductUpdateLevel,ProductVersion,Product_Build_Date,COPYRIGHT,Edition,OS_INFO,Comment')
$JobInfoFinal=@()
$ActiveServers | foreach-object {
	$ServerName = $_
	'Checking Server : '+$_
	$error.clear()
	try{	
		$JobInfo = Invoke-Sqlcmd -Query $SQL -ServerInstance "$_" -ErrorAction 'Stop'
	} Catch {
		$JobInfo = $error[$error.count-1]
		$JobInfo = $ServerName+',,,'+ $JobInfo | ConvertFrom-Csv
	}
	
	$JobInfo | foreach-object {
		$JobInfoTmp = ([ordered]@{
		"ServerName"=$ServerName
		"Backup_Type"=$_.Backup_Type
		"backup_path"=$_.backup_path
		"back_date"=$_.back_date
		})
		$JobInfoFinal+=New-Object -TypeName PSCustomObject -Property $JobInfoTmp
	}
}
"-----------------> JobInfoFinal"
$JobInfoFinal |  export-csv -path "C:\sazam\BackupLocation_Medavante.csv" -NoTypeInformation
