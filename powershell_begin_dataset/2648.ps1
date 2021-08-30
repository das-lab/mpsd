
$db = Get-ChildItem '\\TARKIN\C$\Backups' -Recurse | Where-Object {$_.Extension -eq '.bak'}


foreach($d in $db){
    
    $header = Invoke-Sqlcmd -ServerInstance TARKIN -Database tempdb "RESTORE HEADERONLY FROM DISK='$($d.FullName)'"

    
    Restore-SqlDatabase -ServerInstance TARKIN -Database $header.DatabaseName -BackupFile $d -Script
}

