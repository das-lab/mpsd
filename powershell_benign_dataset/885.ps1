
$resourceGroupName = "<Enter a name for the resource group>"
$nhubnamespace = "<Enter a name for the notification hub namespace>"
$location = "East US"


New-AzResourceGroup -Name $resourceGroupName -Location $location


New-AzNotificationHubsNamespace -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -Location $location


$text = '{"name": "MyNotificationHub",  "Location": "East US",  "Properties": {  }}'
$text | Out-File "inputfile2.json"


New-AzNotificationHub -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -InputFile .\inputfile.json
