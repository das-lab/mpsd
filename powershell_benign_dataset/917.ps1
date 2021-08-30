
$resourceGroup = "myResourceGroup"
$location = "eastus"
$vmName = "myVM"


$cred = Get-Credential


New-AzResourceGroup -ResourceGroupName myResourceGroup -Location eastus


$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name mySubnet `
  -AddressPrefix 192.168.1.0/24


$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myVnet `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig


$pip = New-AzPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -AllocationMethod Static `
  -Name myPublicIPAddress


$nsgRule = New-AzNetworkSecurityRuleConfig `
  -Name myNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow


$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myNetworkSecurityGroup `
  -SecurityRules $nsgRule


$nic = New-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myNic `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id


$encoded = [System.Text.Encoding]::UTF8.GetBytes("Add-WindowsFeature Web-Server; Add-Content -Path 'C:\inetpub\wwwroot\Default.htm' -Value 'Hello World from myVM'")
$etext = [System.Convert]::ToBase64String($encoded)


$vm = New-AzVMConfig `
  -VMName $vmName `
  -VMSize Standard_D1


$vm = Set-AzVMOperatingSystem `
  -VM $vm `
  -Windows `
  -ComputerName myVM `
  -Credential $cred `
  -CustomData $etext `
  -ProvisionVMAgent `
  -EnableAutoUpdate


$vm = Set-AzVMSourceImage `
  -VM $vm `
  -PublisherName MicrosoftWindowsServer `
  -Offer WindowsServer `
  -Skus 2016-Datacenter `
  -Version latest


$vm = Set-AzVMOSDisk `
  -VM $vm `
  -Name myOsDisk `
  -StorageAccountType StandardLRS `
  -DiskSizeInGB 128 `
  -CreateOption FromImage `
  -Caching ReadWrite


$nic = Get-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Name myNic
$vm = Add-AzVMNetworkInterface `
  -VM $vm `
  -Id $nic.Id


New-AzVM -ResourceGroupName $resourceGroup `
  -Location eastus `
  -VM $vm


Set-AzVMExtension -ResourceGroupName $resourceGroup `
  -ExtensionName IIS `
  -VMName $vmName `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -SettingString '{"commandToExecute":"powershell \"[System.Text.Encoding]::UTF8.GetString([System.convert]::FromBase64String((Get-Content C:\\AzureData\\CustomData.bin))) | Out-File .\\command.ps1; powershell.exe .\\command.ps1\""}' `
  -Location $location
