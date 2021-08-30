




$myEndpoint = "<your-endpoint-URL>"


$myResourceGroup = "<resource-group-name>"


$resourceGroupID = (New-AzResourceGroup -Name $myResourceGroup -Location westus2).ResourceId


New-AzEventGridSubscription `
  -ResourceId $resourceGroupID `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup
