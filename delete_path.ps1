$Ticketlist = Get-Content -Path "C:\sadrul\DTicketLocation\backup_tickets.txt"
$Parent_location = "\\dce-p-fps02.epsnet.wan\sql_nonprod_backup_false"


 $Ticketlist | ForEach-Object {    
 $DeletePath = $Parent_location + "\" + $_

 write-host $DeletePath

 #Remove-Item $DeletePath -Force  -Recurse -ErrorAction SilentlyContinue
 
}   