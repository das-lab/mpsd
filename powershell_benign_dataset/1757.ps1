















Import-Module AzureRM.NetCore.Preview


Login-AzureRmAccount


$resourceGroupName = "PSAzDemo" + (New-Guid | ForEach-Object guid) -replace "-",""
$resourceGroupName


New-AzureRmResourceGroup -Name $resourceGroupName -Location "West US"




$dnsLabelPrefix = $resourceGroupName | ForEach-Object tolower
$dnsLabelPrefix


$password = ConvertTo-SecureString -String "PowerShellRocks!" -AsPlainText -Force
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ./Compute-Linux.json -adminUserName psuser -adminPassword $password -dnsLabelPrefix $dnsLabelPrefix


Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName


Find-AzureRmResource -ResourceGroupName $resourceGroupName | Select-Object Name,ResourceType,Location



Get-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName -ODataQuery '$expand=instanceView' | ForEach-Object properties | ForEach-Object instanceview | ForEach-Object statuses



Get-AzureRmProviderOperation -OperationSearchString Microsoft.Compute/* | Select-Object OperationName,Operation


Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Compute/virtualMachines -ResourceName MyUbuntuVM -Action poweroff


Get-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName -ODataQuery '$expand=instanceView' | ForEach-Object properties | ForEach-Object instanceview | ForEach-Object statuses



Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Compute/virtualMachines -ResourceName MyUbuntuVM -Action deallocate


Remove-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName


Find-AzureRmResource -ResourceGroupName $resourceGroupName | Select-Object Name,ResourceType,Location


Remove-AzureRmResourceGroup -Name $resourceGroupName
