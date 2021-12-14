$localScriptRoot = "C:\Users\salom-a\Desktop\Backup SPs"
$Server = "localhost"
$scripts = Get-ChildItem $localScriptRoot | Where-Object {$_.Extension -eq ".sql"}
  
foreach ($s in $scripts)
    {
        Write-Host "Running Script : " $s.Name -BackgroundColor DarkGreen -ForegroundColor White
        $script = $s.FullName
         $script
        #Invoke-Sqlcmd -ServerInstance $Server -InputFile $script
    }