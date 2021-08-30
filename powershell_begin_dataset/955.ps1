


$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" 
$resourceType = "Microsoft.DocumentDb/databaseAccounts"

$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{
    "defaultConsistencyLevel"="Session";
}

$CosmosDBProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
}

New-AzResource -ResourceType $resourceType -ApiVersion $apiVersion `
    -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $CosmosDBProperties


Read-Host -Prompt "Press any key to add a region in South Central US"

$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 },
    @{ "locationName"="South Central US"; "failoverPriority"=2 }
)

$account = Get-AzResource -ResourceType $resourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountName

$account.Properties.locations = $locations
$CosmosDBProperties = $account.Properties

Set-AzResource -ResourceType $resourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountName -PropertyObject $CosmosDBProperties