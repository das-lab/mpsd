
$myEndpoint = "<your-endpoint-URL>"



Set-AzContext -Subscription "<subscription-name-or-ID>"


New-AzEventGridSubscription -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub
