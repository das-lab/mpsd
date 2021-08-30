
$subscriptionId = 'yourSubscriptionId'


$certpwd="Password
$certfolder="c:\mycertificates\"


$adminuser="vmadmin"
$adminpwd="Password


$clusterloc="SouthCentralUS"
$clustername = "mysfcluster"
$groupname="mysfclustergroup"       
$vmsku = "Standard_D2_v2"
$vaultname = "mykeyvault"
$subname="$clustername.$clusterloc.cloudapp.azure.com"


$clustersize=5 


Select-AzSubscription -SubscriptionId $subscriptionId


New-AzServiceFabricCluster -Name $clustername -ResourceGroupName $groupname -Location $clusterloc `
-ClusterSize $clustersize -VmUserName $adminuser -VmPassword $adminpwd -CertificateSubjectName $subname `
-CertificatePassword $certpwd -CertificateOutputFolder $certfolder `
-OS WindowsServer2016DatacenterwithContainers -VmSku $vmsku -KeyVaultName $vaultname