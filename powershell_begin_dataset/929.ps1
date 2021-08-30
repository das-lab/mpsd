
$omsId = "<Replace with your OMS Id>"
$omsKey = "<Replace with your OMS key>"


$resourceGroup = "myResourceGroup"
$location = "westeurope"
$vmName = "myVM"


$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)


New-AzResourceGroup -Name $resourceGroup -Location $location


$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24


$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig


$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4


$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow


$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleSSH


$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id


$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1 | `
Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication | `
Set-AzVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
Add-AzVMNetworkInterface -Id $nic.Id


$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
Add-AzVMSshPublicKey -VM $vmConfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"


New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig


$PublicSettings = New-Object psobject | Add-Member -PassThru NoteProperty workspaceId $omsId | ConvertTo-Json
$protectedSettings = New-Object psobject | Add-Member -PassThru NoteProperty workspaceKey $omsKey | ConvertTo-Json

Set-AzVMExtension -ExtensionName "OMS" -ResourceGroupName $resourceGroup -VMName $vmName `
  -Publisher "Microsoft.EnterpriseCloud.Monitoring" -ExtensionType "OmsAgentForLinux" `
  -TypeHandlerVersion 1.0 -SettingString $PublicSettings ` -ProtectedSettingString $protectedSettings `
  -Location $location
