
$myEndpoint = "<your-endpoint-URL>"



$myResourceGroup = "<resource-group-name>"


$nsgName = "<your-nsg-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $myResourceGroup  -Location westus2


$resourceId = (Get-AzResource -ResourceName $nsgName -ResourceGroupName $myResourceGroup).ResourceId


New-AzEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup `
  -SubjectBeginsWith $resourceId
