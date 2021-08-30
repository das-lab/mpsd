
Get-AzManagedApplication -ResourceGroupName "DemoApp"


(Get-AzManagedApplication -ResourceGroupName "DemoApp").Properties.managedResourceGroupId


Get-AzResource -ResourceGroupName DemoApp6zkevchqk7sfq -ResourceType Microsoft.Compute/virtualMachines


Get-AzVM -ResourceGroupName DemoApp6zkevchqk7sfq | ForEach{ $_.Name, $_.storageProfile.osDisk.osType, $_.hardwareProfile.vmSize }


$vm = Get-AzVM -ResourceGroupName DemoApp6zkevchqk7sfq -VMName demoVM
$vm.HardwareProfile.VmSize = "Standard_D2_v2"
Update-AzVM -VM $vm -ResourceGroupName DemoApp6zkevchqk7sfq
