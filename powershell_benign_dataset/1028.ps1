Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId "<yourSubscriptionID>"


$certpwd="Password
$certfolder="c:\mycertificates\"


$adminuser="vmadmin"
$adminpwd="Password


$clusterloc="SouthCentralUS"
$clustername = "mysftestcluster"
$groupname="mysfclustergroup"       
$vmsku = "Standard_D1_v2"
$subname="$clustername.$clusterloc.cloudapp.azure.com"


$clustersize=3 


New-AzServiceFabricCluster -Name $clustername -ResourceGroupName $groupname -Location $clusterloc `
-ClusterSize $clustersize -VmUserName $adminuser -VmPassword $adminpwd -CertificateSubjectName $subname `
-CertificatePassword $certpwd -CertificateOutputFolder $certfolder `
-OS WindowsServer2016DatacenterwithContainers -VmSku $vmsku
