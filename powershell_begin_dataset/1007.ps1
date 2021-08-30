




$myTopic = "<your-custom-topic-name>"


$myEndpoint = "<your-endpoint-URL>"


$myResourceGroup = "<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


$topicID = (New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic -Location westus2).Id 


New-AzEventGridSubscription `
  -ResourceId $topicID `
  -EventSubscriptionName demoSubscription `
  -Endpoint $myEndpoint 
