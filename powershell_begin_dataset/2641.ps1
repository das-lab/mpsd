

$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE database_id != 2 and state_desc = 'ONLINE'"


$datestring =  (Get-Date -Format 'yyyyMMddHHmm')


foreach($db in $dbs.name){
    $dir = "C:\Backups\$db"
    
    if( -not (Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    
    $filename = "$db-$datestring.bak"
    $backup=Join-Path -Path $dir -ChildPath $filename
    Backup-SqlDatabase -ServerInstance localhost -Database $db -BackupFile $backup -CompressionOption On
    
    Get-ChildItem $dir\*.bak| Where {$_.LastWriteTime -lt (Get-Date).AddMinutes(-1)}|Remove-Item

}


