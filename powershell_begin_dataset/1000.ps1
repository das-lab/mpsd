




$myEndpoint = "<your-endpoint-URL>"


$subID = (Get-AzureRmSubscription -SubscriptionName "<subscription-name>").Id


New-AzureRmEventGridSubscription -ResourceId "/subscriptions/$subID" -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub
