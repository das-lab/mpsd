



[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');            

[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');            
$Server = "(local)";     
$Dest = "C:\Support\SQLBac\";    
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server;            

If ($Dest -eq "")            
{ $Dest = $server.Settings.BackupDirectory + "\" };            
Write-Output ("Started at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));            

foreach ($db in $srv.Databases)            
{            
    If($db.Name -ne "tempdb")  
    {            
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";            
        $backup.Database = $db.Name;            
        $backup.Devices.AddDevice($Dest + $db.Name + "_full_" + $timestamp + ".bak", "File");            
        $backup.BackupSetDescription = "Full backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 0;            
        
        $backup.SqlBackup($srv);     
        
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;            
            $backup.Devices.AddDevice($Dest + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            
            $backup.LogTruncation = "Truncate";
            
            $backup.SqlBackup($srv);            
        };            
    };            
};            
Write-Output ("Finished at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));