#$Directory = "\\phl-svm-cifs-01.wcgclinical.com\phl_sql_non_prod_backup"
$Directory = "\\phl-svm-cifs-01.wcgclinical.com\phl_sql_prod_backup"
#$Directory = "C:\Users\salom-a\Desktop\sadrul"
$OutputDataSavePath="C:\Users\salom-a\Desktop\sadrul\phl_sql_prod_backup.csv"
$FileSizeFilter=1024
$DaysFilter=10

#Equals to(-eq),Greater than(-gt),Greater than or equal to(-ge),Less than(-lt),Less than or equal to(-le)

Get-ChildItem -Path $Directory -Recurse -Force |Where{$_.LastWriteTime -lt (Get-Date).AddDays(-$DaysFilter) -and [int]($_.length / 1mb) -gt $FileSizeFilter} | ForEach { 
if (! $_.PSIsContainer) #is directory check
    {
    [PSCustomObject]@{
        #Name = $_.Name
        FullName = $_.FullName
        LastModifiedTime=$_.LastWriteTime
        #Size=$_.length
        SizeMB = "$([int]($_.length / 1mb))"
        #SizeMB = "$([int]($_.length / 1mb)) MB"
    }
    }
} | Export-Csv -Path $OutputDataSavePath -NoTypeInformation