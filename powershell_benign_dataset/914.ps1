

$subscriptionId = 'yourSubscriptionId'


$resourceGroupName ='yourResourceGroupName'


$diskName = 'yourDiskName'






$location = 'westus'


$virtualNetworkName = 'yourVirtualNetworkName'


$virtualMachineName = 'yourVirtualMachineName'





$virtualMachineSize = 'Standard_DS3'



Select-AzSubscription -SubscriptionId $SubscriptionId


$disk =  Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName


$VirtualMachine = New-AzVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize


$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows


$publicIp = New-AzPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic


$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName


$nic = New-AzNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id


New-AzVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $location
