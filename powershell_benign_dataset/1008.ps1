
$myTopic = "<your-custom-topic-name>"


$myEndpoint = "<your-endpoint-URL>"


$myResourceGroup = "<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic -Location westus2 


New-AzEventGridSubscription `
  -EventSubscriptionName demoSubscription `
  -Endpoint $myEndpoint `
  -ResourceGroupName $myResourceGroup `
  -TopicName $myTopic
