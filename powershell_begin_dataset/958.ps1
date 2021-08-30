



$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "MyResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" 
$apiType = "MongoDB"
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$databaseName = "database1"
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$databaseResourceName = $accountName + "/mongodb/" + $databaseName
$collectionName = "collection2"
$collectionResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections"
$collectionResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName


$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{ "defaultConsistencyLevel"="Session" }

$accountProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="true"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Kind $apiType -Name $accountName -PropertyObject $accountProperties -Force



$databaseProperties = @{
    "resource"=@{ "id"=$databaseName };
    "options"=@{ "Throughput"= 400 }
} 
New-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName -PropertyObject $databaseProperties -Force




$collectionProperties = @{
    "resource"=@{
        "id"=$collectionName; 
        "shardKey"= @{ "user_id"="Hash" };
        "indexes"= @(
            @{
                "key"= @{ "keys"=@("user_id", "user_address") };
                "options"= @{ "unique"= "true" }
            };
            @{
                "key"= @{ "keys"=@("_ts") };
                "options"= @{ "expireAfterSeconds"= 604800 }
            }
        );
        "conflictResolutionPolicy"=@{
            "mode"="lastWriterWins"; 
            "conflictResolutionPath"="myResolutionPath"
        }
    }
} 
New-AzResource -ResourceType $collectionResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $collectionResourceName -PropertyObject $collectionProperties -Force
