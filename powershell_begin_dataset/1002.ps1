
$myEndpoint = "<your-endpoint-URL>"


$myResourceGroup="<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup
