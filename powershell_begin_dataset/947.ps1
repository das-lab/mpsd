


$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 10 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" 
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"

$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)


$ipRangeFilter = "10.0.0.1,10.1.0.1"

$consistencyPolicy = @{
    "defaultConsistencyLevel"="Session";
}

$accountProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "ipRangeFilter"= $ipRangeFilter;
    "enableMultipleWriteLocations"="false"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties -Force
