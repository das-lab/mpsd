




$myEndpoint = "<your-endpoint-URL>"


$topicName = "<your-topic-name>"


$myResourceGroup= "<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Location westus2 -Name $topicName


$topicid = (Get-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $topicName).Id


$AdvFilter1=@{operator="StringIn"; key="Data.color"; Values=@('blue', 'red', 'green')}


New-AzEventGridSubscription `
  -ResourceId $topicid `
  -EventSubscriptionName demoSubWithFilter `
  -Endpoint $myEndpoint `
  -AdvancedFilter @($AdvFilter1)
