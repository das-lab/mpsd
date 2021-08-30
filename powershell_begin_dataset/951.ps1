




$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" 
$apiType = "EnableCassandra"
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$keyspaceName = "keyspace1"
$keyspaceResourceName = $accountName + "/cassandra/" + $keyspaceName
$keyspaceResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces"
$tableName = "table1"
$tableResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName
$tableResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables"


$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{
    "defaultConsistencyLevel"="BoundedStaleness";
    "maxIntervalInSeconds"=300;
    "maxStalenessPrefix"=100000
}

$accountProperties = @{
    "capabilities"= @( @{ "name"=$apiType } );
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="true"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties



$keyspaceProperties = @{
    "resource"=@{ "id"=$keyspaceName };
    "options"=@{ "Throughput"= 400 }
}

New-AzResource -ResourceType $keyspaceResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName -PropertyObject $keyspaceProperties


$tableProperties = @{
    "resource"=@{
        "id"=$tableName; 
        "schema"= @{
            "columns"= @(
                @{ "name"= "loadid"; "type"= "uuid" };
                @{ "name"= "machine"; "type"= "uuid" };
                @{ "name"= "cpu"; "type"= "int" };
                @{ "name"= "mtime"; "type"= "int" };
                @{ "name"= "load"; "type"= "float" };
            );
            "partitionKeys"= @(
                @{ "name"= "machine" };
                @{ "name"= "cpu" };
                @{ "name"= "mtime" }; 
            );
            "clusterKeys"= @( 
                @{ "name"= "loadid"; "orderBy"= "asc" }
            )
        }
    };
    "conflictResolutionPolicy"=@{
        "mode"="lastWriterWins"; 
        "conflictResolutionPath"="myResolutionPath"
    }; 
    "options"=@{ "Throughput"=400 }
} 
New-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName -PropertyObject $tableProperties 
