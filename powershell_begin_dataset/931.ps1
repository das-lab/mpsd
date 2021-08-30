
$subscriptionId = "yourSubscriptionId"


$resourceGroupName ="yourResourceGroupName"


$diskName = "yourDiskName"



$sasExpiryDuration = "3600"


$storageAccountName = "yourstorageaccountName"


$storageContainerName = "yourstoragecontainername"


$storageAccountKey = 'yourStorageAccountKey'


$destinationVHDFileName = "yourvhdfilename"





$useAzCopy = 1 


Select-AzSubscription -SubscriptionId $SubscriptionId


$sas = Grant-AzDiskAccess -ResourceGroupName $ResourceGroupName -DiskName $diskName -DurationInSecond $sasExpiryDuration -Access Read 


$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey


if($useAzCopy -eq 1)
{
    $containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -FullUri -Name $storageContainerName -Permission rw
    .\azcopy copy $sas.AccessSAS $containerSASURI

}else{

    Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName
}
