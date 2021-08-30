

$dbs = Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Query "SELECT name FROM sys.databases WHERE recovery_model_desc = 'FULL' and state_desc = 'ONLINE'"


$datestring =  (Get-Date -Format 'yyyyMMddHHmm')


foreach($db in $dbs.name){
    $dir = "C:\Backups\$db"
    
    if( -not (Test-Path $dir)){New-Item -ItemType Directory -path $dir}
    
    
    $filename = "$db-$datestring.trn"
    $backup=Join-Path -Path $dir -ChildPath $filename
    Backup-SqlDatabase -ServerInstance localhost -Database $db -BackupFile $backup -CompressionOption On -BackupAction Log
    
    Get-ChildItem $dir\*.trn| Where {$_.LastWriteTime -lt (Get-Date).AddDays(-3)}|Remove-Item

}