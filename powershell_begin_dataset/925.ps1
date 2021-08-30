
$resourceGroup = "myResourceGroup"
$location = "westeurope"
$vmName = "myVM"


$cred = Get-Credential -Message "Enter a username and password for the virtual machine."


New-AzResourceGroup -Name $resourceGroup -Location $location


New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Name $vmName `
  -Location $location `
  -ImageName "Win2016Datacenter" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -SecurityGroupName "myNetworkSecurityGroup" `
  -PublicIpAddressName "myPublicIp" `
  -Credential $cred `
  -OpenPorts 3389
