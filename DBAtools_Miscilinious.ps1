#Update the installed version of the SqlServer module
Install-Module -Name SqlServer -AllowClobber #always install latest version

Install-Module -Name SqlServer -RequiredVersion 21.1.18245 #specific version

Install-Module -Name DBATools -Force #to override previous version if already installed

 set-executionpolicy remotesigned #DBATools PowerShell Module is installed, run the following command to enable remote execution of PowerShell scripts.
 
 #Full backup of AdventureWorksDW2019,tt database
 Backup-DbaDatabase -SqlInstance localhost -Database AdventureWorksDW2019,tt -ExcludeDatabase SS -BackupDirectory C:\backups -CreateFolder -Type Full -CopyOnly -CompressBackup
 
 #full backup all databases
 Backup-DbaDatabase -SqlInstance localhost -BackupDirectory C:\backups -CreateFolder -Type Full -CopyOnly -CompressBackup
 
 # stripped backup with Checksum and Verify
 Backup-DbaDatabase -SqlInstance localhost -Database tt  -BackupDirectory C:\backups  -CreateFolder -FileCount 2 -Checksum -Verify -Type Full -CopyOnly -CompressBackup
 # taking backup exclude systemdb
 Backup-DbaDatabase -SqlInstance localhost -ExcludeDatabase master,model,tempdb,msdb -BackupDirectory C:\backups -CreateFolder -Type Full -CopyOnly -CompressBackup
 
 #Find service status
 get-service | Where-Object{($_.Status -eq "Running") -and ($_.Name -eq "MSSQLSERVER")}

# get output in table format
 get-dbadbfile -SqlInstance localhost | Format-Table
 # select only required columns
 get-dbadbfile -SqlInstance localhost -Database tt | Select-Object database,type,physicalname
 
 # Restore database with new name
 Restore-DbaDatabase -SqlInstance localhost -DatabaseName AA -Path C:\backups -DestinationDataDirectory C:\Data -DestinationLogDirectory C:\Log -Verbose -WithReplace -NoRecovery
 
 # restore in default directory
 Restore-DbaDatabase -SqlInstance localhost  -Path C:\backups\tt -UseDestinationDefaultDirectories -WithReplace 
 
 #     **** Database server migration
 #backup database in source server
 get-dbadatabase -SqlInstance localhost -ExcludeAllSystemdb|Backup-DbaDatabase -BackupDirectory C:\backups\migration -CreateFolder -Type Full -CopyOnly -CompressBackup
 # restore in destination server
 Restore-DbaDatabase -SqlInstance sqlnode3 -Path \\SQLNODE1\backups\Migration -UseDestinationDefaultDirectories
 
 #Agent job transfer
 Copy-DbaAgentJob -Source sqlnode1 -Destination sqlnode3 -ExcludeJob excludejobname  -DisableOnDestination -Force
 
 # Export login from source
 Export-DbaLogin -SqlInstance sqlnode1 -Path C:\backups\Migration\sqllogin.sql -DestinationVersion SQLServer2019 -ExcludeLogin ss 
 
 # Repair orphane user in destination
 Repair-DbaDbOrphanUser -SqlInstance sqlnode3
 
 # local disk 
 Get-DbaDiskSpace -computername sqlnode1| Where-Object{$_.PercentFree -lt 50}|select * |Format-Table
 
Get-DbaDiskSpace -computername sqlnode1| Where-Object{$_.PercentFree -lt 50}|select * |Format-Table| Out-File C:\backups\diskinfo.txt
 
 
 
 