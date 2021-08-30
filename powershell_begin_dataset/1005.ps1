
$myTopic = "<your-custom-topic-name>"


$myResourceGroup = "<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic -Location westus2 


$endpoint = (Get-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic).Endpoint
$key = (Get-AzEventGridTopicKey -ResourceGroupName $myResourceGroup -Name $myTopic).Key1

$endpoint
$key
