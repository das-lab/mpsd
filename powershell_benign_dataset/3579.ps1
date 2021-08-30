














function Api-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $apis = Get-AzApiManagementApi -Context $context

    
    Assert-AreEqual 1 $apis.Count
    Assert-NotNull $apis[0].ApiId
    Assert-AreEqual "Echo API" $apis[0].Name
    Assert-Null $apis[0].Description
    Assert-AreEqual "http://echoapi.cloudapp.net/api" $apis[0].ServiceUrl
    Assert-AreEqual echo $apis[0].Path
    Assert-AreEqual 1 $apis[0].Protocols.Length
    Assert-AreEqual https $apis[0].Protocols[0]
    Assert-Null $apis[0].AuthorizationServerId
    Assert-Null $apis[0].AuthorizationScope
    Assert-Null $apis[0].SubscriptionKeyHeaderName
    Assert-Null $apis[0].SubscriptionKeyQueryParamName

    
    $apiId = $apis[0].ApiId

    $api = Get-AzApiManagementApi -Context $context -ApiId $apiId

    Assert-AreEqual $apiId $api.ApiId
    Assert-AreEqual "Echo API" $api.Name
    Assert-Null $api.Description
    Assert-AreEqual "http://echoapi.cloudapp.net/api" $api.ServiceUrl
    Assert-AreEqual echo $api.Path
    Assert-AreEqual 1 $api.Protocols.Length
    Assert-AreEqual https $api.Protocols[0]
    Assert-Null $api.AuthorizationServerId
    Assert-Null $api.AuthorizationScope
    Assert-NotNull $api.SubscriptionKeyHeaderName       
    Assert-NotNull $api.SubscriptionKeyQueryParamName   

    
    $apiName = $apis[0].Name

    $apis = Get-AzApiManagementApi -Context $context -Name $apiName

    Assert-AreEqual 1 $apis.Count
    Assert-NotNull $apis[0].ApiId
    Assert-AreEqual $apiName $apis[0].Name
    Assert-Null $apis[0].Description
    Assert-AreEqual "http://echoapi.cloudapp.net/api" $apis[0].ServiceUrl
    Assert-AreEqual echo $apis[0].Path
    Assert-AreEqual 1 $apis[0].Protocols.Length
    Assert-AreEqual https $apis[0].Protocols[0]
    Assert-Null $apis[0].AuthorizationServerId
    Assert-Null $apis[0].AuthorizationScope
    Assert-Null $apis[0].SubscriptionKeyHeaderName
    Assert-Null $apis[0].SubscriptionKeyQueryParamName

    
    $newApiId = getAssetName
    try {
        $newApiName = getAssetName
        $newApiDescription = getAssetName
        $newApiPath = getAssetName
        $newApiServiceUrl = "http://newechoapi.cloudapp.net/newapi"
        $subscriptionKeyParametersHeader = getAssetName
        $subscriptionKeyQueryStringParamName = getAssetName

        $newApi = New-AzApiManagementApi -Context $context -ApiId $newApiId -Name $newApiName -Description $newApiDescription `
            -Protocols @("http", "https") -Path $newApiPath -ServiceUrl $newApiServiceUrl `
            -SubscriptionKeyHeaderName $subscriptionKeyParametersHeader -SubscriptionKeyQueryParamName $subscriptionKeyQueryStringParamName

        Assert-AreEqual $newApiId $newApi.ApiId
        Assert-AreEqual $newApiName $newApi.Name
        Assert-AreEqual $newApiDescription.Description
        Assert-AreEqual $newApiServiceUrl $newApi.ServiceUrl
        Assert-AreEqual $newApiPath $newApi.Path
        Assert-AreEqual 2 $newApi.Protocols.Length
        Assert-AreEqual http $newApi.Protocols[0]
        Assert-AreEqual https $newApi.Protocols[1]
        Assert-Null $newApi.AuthorizationServerId
        Assert-Null $newApi.AuthorizationScope
        Assert-AreEqual $subscriptionKeyParametersHeader $newApi.SubscriptionKeyHeaderName
        Assert-AreEqual $subscriptionKeyQueryStringParamName $newApi.SubscriptionKeyQueryParamName

        
        $newApiName = getAssetName
        $newApiDescription = getAssetName
        $newApiPath = getAssetName
        $newApiServiceUrl = "http://newechoapi.cloudapp.net/newapinew"
        $subscriptionKeyParametersHeader = getAssetName
        $subscriptionKeyQueryStringParamName = getAssetName

        $newApi = Set-AzApiManagementApi -Context $context -ApiId $newApiId -Name $newApiName -Description $newApiDescription `
            -Protocols @("https") -Path $newApiPath -ServiceUrl $newApiServiceUrl `
            -SubscriptionKeyHeaderName $subscriptionKeyParametersHeader -SubscriptionKeyQueryParamName $subscriptionKeyQueryStringParamName `
            -PassThru

        Assert-AreEqual $newApiId $newApi.ApiId
        Assert-AreEqual $newApiName $newApi.Name
        Assert-AreEqual $newApiDescription.Description
        Assert-AreEqual $newApiServiceUrl $newApi.ServiceUrl
        Assert-AreEqual $newApiPath $newApi.Path
        Assert-AreEqual 1 $newApi.Protocols.Length
        Assert-AreEqual https $newApi.Protocols[0]
        Assert-Null $newApi.AuthorizationServerId
        Assert-Null $newApi.AuthorizationScope
        Assert-AreEqual $subscriptionKeyParametersHeader $newApi.SubscriptionKeyHeaderName
        Assert-AreEqual $subscriptionKeyQueryStringParamName $newApi.SubscriptionKeyQueryParamName

        $product = Get-AzApiManagementProduct -Context $context | Select-Object -First 1
        Add-AzApiManagementApiToProduct -Context $context -ApiId $newApiId -ProductId $product.ProductId

        
        $found = 0
        $apis = Get-AzApiManagementApi -Context $context -ProductId $product.ProductId
        for ($i = 0; $i -lt $apis.Count; $i++) {
            if ($apis[$i].ApiId -eq $newApiId) {
                $found = 1
            }
        }
        Assert-AreEqual 1 $found

        Remove-AzApiManagementApiFromProduct -Context $context -ApiId $newApiId -ProductId $product.ProductId
        $found = 0
        $apis = Get-AzApiManagementApi -Context $context -ProductId $product.ProductId
        for ($i = 0; $i -lt $apis.Count; $i++) {
            if ($apis[$i].ApiId -eq $newApiId) {
                $found = 1
            }
        }
        Assert-AreEqual 0 $found
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $newApiId -PassThru
        Assert-True { $removed }
    }
}


function ApiClone-Test {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $apis = Get-AzApiManagementApi -Context $context

    
    Assert-AreEqual 1 $apis.Count
    Assert-NotNull $apis[0].ApiId
    Assert-AreEqual "Echo API" $apis[0].Name
    Assert-Null $apis[0].Description
    Assert-AreEqual "http://echoapi.cloudapp.net/api" $apis[0].ServiceUrl
    Assert-AreEqual echo $apis[0].Path
    Assert-AreEqual 1 $apis[0].Protocols.Length
    Assert-AreEqual https $apis[0].Protocols[0]
    Assert-Null $apis[0].AuthorizationServerId
    Assert-Null $apis[0].AuthorizationScope
    Assert-Null $apis[0].SubscriptionKeyHeaderName
    Assert-Null $apis[0].SubscriptionKeyQueryParamName

    
    $apiId = $apis[0].ApiId

    $api = Get-AzApiManagementApi -Context $context -ApiId $apiId

    Assert-AreEqual $apiId $api.ApiId
    Assert-AreEqual "Echo API" $api.Name
    Assert-Null $api.Description
    Assert-AreEqual "http://echoapi.cloudapp.net/api" $api.ServiceUrl
    Assert-AreEqual echo $api.Path
    Assert-AreEqual 1 $api.Protocols.Length
    Assert-AreEqual https $api.Protocols[0]
    Assert-Null $api.AuthorizationServerId
    Assert-Null $api.AuthorizationScope
    Assert-NotNull $api.SubscriptionKeyHeaderName       
    Assert-NotNull $api.SubscriptionKeyQueryParamName   

    $echoapiOperations = Get-AzApiManagementOperation -Context $context -ApiId $apiId

    Assert-NotNull $echoapiOperations

    
    $newApiId = getAssetName
    
    $newApiVersionSetId = getAssetName
    
    $newApiInVersionId = getAssetName

    try {

        $newVersionSetName = getAssetName
        $queryName = getAssetName
        $description = getAssetName

        
        $newApiVersionSet = New-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -Name $newVersionSetName -Scheme Query `
            -QueryName $queryName -Description $description

        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Query $newApiVersionSet.VersioningScheme
        Assert-AreEqual $queryName $newApiVersionSet.VersionQueryName
        Assert-Null $newApiVersionSet.VersionHeaderName

        $newApiName = getAssetName
        $newApiDescription = getAssetName
        $newApiPath = getAssetName
        $newApiServiceUrl = "http://newechoapi.cloudapp.net/newapi"

        
        $newApi = New-AzApiManagementApi -Context $context -ApiId $newApiId -Name $newApiName -Description $newApiDescription `
            -Protocols @("http", "https") -Path $newApiPath -ServiceUrl $newApiServiceUrl `
            -SourceApiId $apiId

        Assert-AreEqual $newApiId $newApi.ApiId
        Assert-AreEqual $newApiName $newApi.Name
        Assert-AreEqual $newApiDescription.Description
        Assert-AreEqual $newApiServiceUrl $newApi.ServiceUrl
        Assert-AreEqual $newApiPath $newApi.Path
        Assert-AreEqual 2 $newApi.Protocols.Length
        Assert-AreEqual http $newApi.Protocols[0]
        Assert-AreEqual https $newApi.Protocols[1]
        Assert-Null $newApi.AuthorizationServerId
        Assert-Null $newApi.AuthorizationScope

        
        $newApiOperations = Get-AzApiManagementOperation -Context $context -ApiId $newApiId

        Assert-AreEqual $echoapiOperations.Count $newApiOperations.Count

        for ($i = 0; $i -lt $newApiOperations.Count; $i++) {
            Assert-AreEqual $newApiId $newApiOperations[$i].ApiId

            $operation = Get-AzApiManagementOperation -Context $context -ApiId $newApiId -OperationId $newApiOperations[$i].OperationId

            Assert-AreEqual $newApiId $operation.ApiId
            Assert-AreEqual $newApiOperations[$i].OperationId $operation.OperationId
            Assert-AreEqual $newApiOperations[$i].Name $operation.Name
            Assert-AreEqual $newApiOperations[$i].Description $operation.Description
            Assert-AreEqual $newApiOperations[$i].Method $operation.Method
            Assert-AreEqual $newApiOperations[$i].UrlTemplate $operation.UrlTemplate
        }

        
        $newApiCloneName = getAssetName
        $newApiCloneDescription = getAssetName
        $newApiClonePath = getAssetName
        $newApiCloneServiceUrl = "http://newechoapi.cloudapp.net/newapiv2"
        
        
        $newApiVersion = New-AzApiManagementApi -Context $context -ApiId $newApiInVersionId -Name $newApiCloneName -Description $newApiCloneDescription `
            -Protocols @("http", "https") -Path $newApiClonePath -ServiceUrl $newApiCloneServiceUrl `
            -SourceApiId $apiId -ApiVersion "2" -ApiVersionSetId $newApiVersionSet.ApiVersionSetId -SubscriptionRequired

        Assert-AreEqual $newApiInVersionId $newApiVersion.ApiId
        Assert-AreEqual $newApiCloneName $newApiVersion.Name
        Assert-AreEqual $newApiCloneDescription $newApiVersion.Description
        Assert-AreEqual $newApiCloneServiceUrl $newApiVersion.ServiceUrl
        Assert-AreEqual $newApiClonePath $newApiVersion.Path
        Assert-AreEqual 2 $newApiVersion.Protocols.Length
        Assert-AreEqual http $newApiVersion.Protocols[0]
        Assert-AreEqual https $newApiVersion.Protocols[1]
        Assert-AreEqual "2" $newApiVersion.APIVersion
        Assert-AreEqual $newApiVersionSet.Id $newApiVersion.ApiVersionSetId
		Assert-AreEqual $TRUE $newApiVersion.SubscriptionRequired
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $newApiId -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $newApiInVersionId -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -PassThru
        Assert-True { $removed }
    }
}


function Api-ImportExportWadlTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    $wadlPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "WADLYahoo.xml"
    $path = "wadlapi"
    $wadlApiId = getAssetName

    try {
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $wadlApiId -SpecificationPath $wadlPath -SpecificationFormat Wadl -Path $path

        Assert-AreEqual $wadlApiId $api.ApiId
        Assert-AreEqual $path $api.Path

        
        
        
        

        
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $wadlApiId -PassThru
        Assert-True { $removed }
    }
}


function Api-ImportExportSwaggerTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    $swaggerPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "SwaggerPetStoreV2.json"
    $swaggerUrl = "http://petstore.swagger.io/v2/swagger.json"
    $path1 = "swaggerapifromFile"
    $path2 = "swaggerapifromUrl"
    $swaggerApiId1 = getAssetName
    $swaggerApiId2 = getAssetName

    try {
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -SpecificationPath $swaggerPath -SpecificationFormat Swagger -Path $path1

        Assert-AreEqual $swaggerApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path

        
        
        
        
        
        

        
        $api = Import-AzApiManagementApi -Context $context -ApiId $swaggerApiId2 -SpecificationUrl $swaggerUrl -SpecificationFormat Swagger -Path $path2

        Assert-AreEqual $swaggerApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path

        $newName = "apimPetstore"
        $newDescription = "Swagger api via Apim"
        $api = Set-AzApiManagementApi -InputObject $api -Name $newName -Description $newDescription -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols -PassThru
        Assert-AreEqual $swaggerApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path
        Assert-AreEqual $newName $api.Name
        Assert-AreEqual $newDescription $api.Description
        Assert-AreEqual 'Http' $api.ApiType
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -PassThru
        Assert-True { $removed }

        $removed = Remove-AzApiManagementApi -Context $context -ApiId $swaggerApiId2 -PassThru
        Assert-True { $removed }
    }
}


function Api-ImportExportWsdlTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName
    $wsdlUrl = "http://fazioapisoap.azurewebsites.net/fazioService.svc?singleWSDL"   
    $wsdlPath1 = Join-Path (Join-Path "$TestOutputRoot" "Resources") "Weather.wsdl"
    $path1 = "soapapifromFile"
    $path2 = "soapapifromUrl"
    $wsdlApiId1 = getAssetName
    $wsdlApiId2 = getAssetName
    $wsdlServiceName1 = "Weather" 
    $wsdlEndpointName1 = "WeatherSoap" 
    $wsdlServiceName2 = "OrdersAPI" 
    $wsdlEndpointName2 = "basic" 
    
    try {
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $wsdlApiId1 -SpecificationPath $wsdlPath1 -SpecificationFormat Wsdl -Path $path1 `
            -WsdlServiceName $wsdlServiceName1 -WsdlEndpointName $wsdlEndpointName1 -ApiType Soap

        Assert-AreEqual $wsdlApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path
        Assert-AreEqual 'Soap' $api.ApiType
      
        
        
        
        
        
        

        
        $api = Import-AzApiManagementApi -Context $context -ApiId $wsdlApiId2 -SpecificationUrl $wsdlUrl -SpecificationFormat Wsdl -Path $path2 `
            -WsdlServiceName $wsdlServiceName2 -WsdlEndpointName $wsdlEndpointName2 -ApiType Soap

        Assert-AreEqual $wsdlApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path

        $newName = "apimSoap"
        $newDescription = "Soap api via Apim"
        $api = Set-AzApiManagementApi -InputObject $api -Name $newName -Description $newDescription -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols -PassThru
        Assert-AreEqual $wsdlApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path
        Assert-AreEqual $newName $api.Name
        Assert-AreEqual $newDescription $api.Description
        Assert-AreEqual 'Soap' $api.ApiType

        
        
        
        
        
        
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $wsdlApiId1 -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $wsdlApiId2 -PassThru
        Assert-True { $removed }
    }
}


function Api-ImportExportOpenApiTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName
    $openApiUrl = "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/OpenAPI.next/examples/v3.0/petstore.yaml"   
    $yamlPath1 = Join-Path (Join-Path "$TestOutputRoot" "Resources") "uspto.yml"
    $path1 = "openapifromFile"
    $path2 = "openapifromUrl"
    $openApiId1 = getAssetName
    $openApiId2 = getAssetName
    
    try {
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $openApiId1 -SpecificationPath $yamlPath1 -SpecificationFormat OpenApi -Path $path1

        Assert-AreEqual $openApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path

        
        $api = Import-AzApiManagementApi -Context $context -ApiId $openApiId2 -SpecificationUrl $openApiUrl -SpecificationFormat OpenApi -Path $path2

        Assert-AreEqual $openApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path

        $newName = "apimPetstore"
        $newDescription = "Open api via Apim"
        $api = Set-AzApiManagementApi -InputObject $api -Name $newName -Description $newDescription -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols -PassThru
        Assert-AreEqual $openApiId2 $api.ApiId
        Assert-AreEqual $path2 $api.Path
        Assert-AreEqual $newName $api.Name
        Assert-AreEqual $newDescription $api.Description
        Assert-AreEqual 'Http' $api.ApiType
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $openApiId1 -PassThru
        Assert-True { $removed }

        $removed = Remove-AzApiManagementApi -Context $context -ApiId $openApiId2 -PassThru
        Assert-True { $removed }
    }
}


function ApiSchema-SwaggerCRUDTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    $swaggerDefinitionsFilePath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "petstoreschema.json"

    
    $newApiId = getAssetName
    $newSchemaId = getAssetName
    try {
        $newApiName = getAssetName
        $newApiDescription = getAssetName
        $newApiPath = getAssetName
        $newApiServiceUrl = "http://newechoapi.cloudapp.net/newapi"
        $subscriptionKeyParametersHeader = getAssetName
        $subscriptionKeyQueryStringParamName = getAssetName

        $newApi = New-AzApiManagementApi -Context $context -ApiId $newApiId -Name $newApiName -Description $newApiDescription `
            -Protocols @("http", "https") -Path $newApiPath -ServiceUrl $newApiServiceUrl `
            -SubscriptionKeyHeaderName $subscriptionKeyParametersHeader -SubscriptionKeyQueryParamName $subscriptionKeyQueryStringParamName

        Assert-AreEqual $newApiId $newApi.ApiId
        Assert-AreEqual $newApiName $newApi.Name
        Assert-AreEqual $newApiDescription.Description
        Assert-AreEqual $newApiServiceUrl $newApi.ServiceUrl
        Assert-AreEqual $newApiPath $newApi.Path
        Assert-AreEqual 2 $newApi.Protocols.Length

        
        $apiSchemas = Get-AzApiManagementApiSchema -Context $context -ApiId $newApiId
        Assert-AreEqual 0 $apiSchemas.Count

        $apiSchema = New-AzApiManagementApiSchema -Context $context -ApiId $newApiId -SchemaId $newSchemaId -SchemaDocumentContentType SwaggerDefinition `
            -SchemaDocumentFilePath $swaggerDefinitionsFilePath
        
        Assert-NotNull $apiSchema
        Assert-AreEqual $newSchemaId $apiSchema.SchemaId
        Assert-AreEqual $newApiId $apiSchema.ApiId
        Assert-AreEqual SwaggerDefinition $apiSchema.SchemaDocumentContentType
        Assert-NotNull $apiSchema.SchemaDocument

        
        $getApiSchema = Get-AzApiManagementApiSchema -ResourceId $apiSchema.Id
        Assert-AreEqual $apiSchema.SchemaId $getApiSchema.SchemaId
        Assert-AreEqual $apiSchema.ApiId $getApiSchema.ApiId
        Assert-AreEqual SwaggerDefinition $getApiSchema.SchemaDocumentContentType        

        
        $apiSchemas = Get-AzApiManagementApiSchema -Context $context -ApiId $newApiId
        Assert-AreEqual 1 $apiSchemas.Count
        Assert-AreEqual $getApiSchema.SchemaId $apiSchemas[0].SchemaId
        Assert-AreEqual SwaggerDefinition $apiSchema.SchemaDocumentContentType
        Assert-AreEqual $getApiSchema.ApiId $apiSchemas[0].ApiId

        
        $apiSchema = Set-AzApiManagementApiSchema -InputObject $getApiSchema -SchemaDocumentContentType "application/json" -PassThru
        Assert-NotNull $apiSchema
        Assert-AreEqual $getApiSchema.SchemaId $apiSchema.SchemaId
        Assert-AreEqual $newApiId $apiSchema.ApiId
        Assert-AreEqual "application/json" $apiSchema.SchemaDocumentContentType

        Remove-AzApiManagementApiSchema -ResourceId $apiSchema.Id
    }
    finally {
        
        $removed = Remove-AzApiManagementApiSchema -Context $context -ApiId $newApiId -SchemaId $newSchemaId -PassThru
        Assert-True { $removed }

        $removed = Remove-AzApiManagementApi -Context $context -ApiId $newApiId -PassThru
        Assert-True { $removed }
    }
}


function ApiSchema-WsdlCRUDTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    $wsdlPath1 = Join-Path (Join-Path "$TestOutputRoot" "Resources") "Weather.wsdl"
    $wsdlFileSchema = Join-Path (Join-Path "$TestOutputRoot" "Resources") "weather.xsl"
    $path1 = "soapapifromFile"
    $wsdlServiceName1 = "Weather" 
    $wsdlEndpointName1 = "WeatherSoap" 

    
    $newApiId = getAssetName
    $newSchemaId = getAssetName
    try {
        
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $newApiId -SpecificationPath $wsdlPath1 -SpecificationFormat Wsdl -Path $path1 `
               -WsdlServiceName $wsdlServiceName1 -WsdlEndpointName $wsdlEndpointName1 -ApiType Soap

        Assert-AreEqual $newApiId $api.ApiId
        Assert-AreEqual $path1 $api.Path
        Assert-AreEqual 'Soap' $api.ApiType

        
        $apiSchemas = Get-AzApiManagementApiSchema -Context $context -ApiId $newApiId
        Assert-AreEqual 1 $apiSchemas.Count
        Assert-AreEqual XsdSchema $apiSchemas[0].SchemaDocumentContentType
        Assert-AreEqual $newApiId $apiSchemas[0].ApiId

        $newSchemaId = $apiSchemas[0].SchemaId
        $apiSchema = New-AzApiManagementApiSchema -Context $context -ApiId $newApiId -SchemaId $newSchemaId -SchemaDocumentContentType XsdSchema `
            -SchemaDocumentFilePath $wsdlFileSchema
        
        Assert-NotNull $apiSchema
        Assert-AreEqual $newSchemaId $apiSchema.SchemaId
        Assert-AreEqual $newApiId $apiSchema.ApiId
        Assert-AreEqual XsdSchema $apiSchema.SchemaDocumentContentType
        Assert-NotNull $apiSchema.SchemaDocument

        
        $getApiSchema = Get-AzApiManagementApiSchema -ResourceId $apiSchema.Id
        Assert-AreEqual $apiSchema.SchemaId $getApiSchema.SchemaId
        Assert-AreEqual $apiSchema.ApiId $getApiSchema.ApiId
        Assert-AreEqual XsdSchema $getApiSchema.SchemaDocumentContentType
        Assert-AreEqual $apiSchema.SchemaDocument $getApiSchema.SchemaDocument

        
        $apiSchemas = Get-AzApiManagementApiSchema -Context $context -ApiId $newApiId
        Assert-AreEqual 1 $apiSchemas.Count
        Assert-AreEqual $getApiSchema.SchemaId $apiSchemas[0].SchemaId
        Assert-AreEqual $getApiSchema.ApiId $apiSchemas[0].ApiId
        Assert-AreEqual $getApiSchema.SchemaDocumentContentType $apiSchemas[0].SchemaDocumentContentType

        
        $apiSchema = Set-AzApiManagementApiSchema -InputObject $getApiSchema -SchemaDocumentContentType "application/json" -PassThru
        Assert-NotNull $apiSchema
        Assert-AreEqual $getApiSchema.SchemaId $apiSchema.SchemaId
        Assert-AreEqual $newApiId $apiSchema.ApiId
        Assert-AreEqual "application/json" $apiSchema.SchemaDocumentContentType
        Assert-AreEqual $getApiSchema.SchemaDocument $apiSchema.SchemaDocument
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $newApiId -PassThru
        Assert-True { $removed }
    }
}



function Operations-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $api = Get-AzApiManagementApi -Context $context -Name 'Echo API' | Select-Object -First 1

    
    $operations = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId

    Assert-AreEqual 6 $operations.Count
    for ($i = 0; $i -lt $operations.Count; $i++) {
        Assert-AreEqual $api.ApiId $operations[$i].ApiId

        $operation = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId -OperationId $operations[$i].OperationId

        Assert-AreEqual $api.ApiId $operation.ApiId
        Assert-AreEqual $operations[$i].OperationId $operation.OperationId
        Assert-AreEqual $operations[$i].Name $operation.Name
        Assert-AreEqual $operations[$i].Description $operation.Description
        Assert-AreEqual $operations[$i].Method $operation.Method
        Assert-AreEqual $operations[$i].UrlTemplate $operation.UrlTemplate
    }

    
    $newOperationId = getAssetName
    try {
        $newOperationName = getAssetName
        $newOperationMethod = "PATCH"
        $newperationUrlTemplate = "/resource/{rid}?q={query}"
        $newOperationDescription = getAssetName
        $newOperationRequestDescription = getAssetName

        $newOperationRequestHeaderParamName = getAssetName
        $newOperationRequestHeaderParamDescr = getAssetName
        $newOperationRequestHeaderParamIsRequired = $TRUE
        $newOperationRequestHeaderParamDefaultValue = getAssetName
        $newOperationRequestHeaderParamType = "string"

        $newOperationRequestParmName = getAssetName
        $newOperationRequestParamDescr = getAssetName
        $newOperationRequestParamIsRequired = $TRUE
        $newOperationRequestParamDefaultValue = getAssetName
        $newOperationRequestParamType = "string"

        $newOperationRequestRepresentationContentType = "application/json"
        $newOperationRequestRepresentationSample = getAssetName

        $newOperationResponseDescription = getAssetName
        $newOperationResponseStatusCode = 1980785443;
        $newOperationResponseRepresentationContentType = getAssetName
        $newOperationResponseRepresentationSample = getAssetName

        
        $rid = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $rid.Name = "rid"
        $rid.Description = "Resource identifier"
        $rid.Type = "string"

        $query = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $query.Name = "query"
        $query.Description = "Query string"
        $query.Type = "string"

        
        $request = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRequest
        $request.Description = "Create/update resource request"

        
        $dummyQp = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $dummyQp.Name = $newOperationRequestParmName
        $dummyQp.Description = $newOperationRequestParamDescr
        $dummyQp.Type = $newOperationRequestParamType
        $dummyQp.Required = $newOperationRequestParamIsRequired
        $dummyQp.DefaultValue = $newOperationRequestParamDefaultValue
        $dummyQp.Values = @($newOperationRequestParamDefaultValue)
        $request.QueryParameters = @($dummyQp)

        
        $header = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $header.Name = $newOperationRequestHeaderParamName
        $header.Description = $newOperationRequestHeaderParamDescr
        $header.DefaultValue = $newOperationRequestHeaderParamDefaultValue
        $header.Values = @($newOperationRequestHeaderParamDefaultValue)
        $header.Type = $newOperationRequestHeaderParamType
        $header.Required = $newOperationRequestHeaderParamIsRequired
        $request.Headers = @($header)

        
        $requestRepresentation = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
        $requestRepresentation.ContentType = $newOperationRequestRepresentationContentType
        $requestRepresentation.Sample = $newOperationRequestRepresentationSample
        $request.Representations = @($requestRepresentation)

        
        $response = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementResponse
        $response.StatusCode = $newOperationResponseStatusCode
        $response.Description = $newOperationResponseDescription

        
        $responseRepresentation = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
        $responseRepresentation.ContentType = $newOperationResponseRepresentationContentType
        $responseRepresentation.Sample = $newOperationResponseRepresentationSample
        $response.Representations = @($responseRepresentation)

        $newOperation = New-AzApiManagementOperation –Context $context –ApiId $api.ApiId –OperationId $newOperationId –Name $newOperationName `
            –Method $newOperationMethod –UrlTemplate $newperationUrlTemplate –Description $newOperationDescription –TemplateParameters @($rid, $query) –Request $request –Responses @($response)

        Assert-AreEqual $api.ApiId $newOperation.ApiId
        Assert-AreEqual $newOperationId $newOperation.OperationId
        Assert-AreEqual $newOperationName $newOperation.Name
        Assert-AreEqual $newOperationMethod $newOperation.Method
        Assert-AreEqual $newperationUrlTemplate $newOperation.UrlTemplate
        Assert-AreEqual $newOperationDescription $newOperation.Description

        Assert-NotNull $newOperation.TemplateParameters
        Assert-AreEqual 2 $newOperation.TemplateParameters.Count
        Assert-AreEqual $rid.Name $newOperation.TemplateParameters[0].Name
        Assert-AreEqual $rid.Description $newOperation.TemplateParameters[0].Description
        Assert-AreEqual $rid.Type $newOperation.TemplateParameters[0].Type
        Assert-AreEqual $query.Name $newOperation.TemplateParameters[1].Name
        Assert-AreEqual $query.Description $newOperation.TemplateParameters[1].Description
        Assert-AreEqual $query.Type $newOperation.TemplateParameters[1].Type

        Assert-NotNull $newOperation.Request
        Assert-AreEqual $request.Description $newOperation.Request.Description
        Assert-NotNull $newOperation.Request.QueryParameters
        Assert-AreEqual 1 $newOperation.Request.QueryParameters.Count
        Assert-AreEqual $dummyQp.Name $newOperation.Request.QueryParameters[0].Name
        Assert-AreEqual $dummyQp.Description $newOperation.Request.QueryParameters[0].Description
        Assert-AreEqual $dummyQp.Type $newOperation.Request.QueryParameters[0].Type
        Assert-AreEqual $dummyQp.Required $newOperation.Request.QueryParameters[0].Required
        Assert-AreEqual $dummyQp.DefaultValue $newOperation.Request.QueryParameters[0].DefaultValue

        Assert-AreEqual 1 $newOperation.Request.Headers.Count
        Assert-AreEqual $header.Name $newOperation.Request.Headers[0].Name
        Assert-AreEqual $header.Description $newOperation.Request.Headers[0].Description
        Assert-AreEqual $header.Type $newOperation.Request.Headers[0].Type
        Assert-AreEqual $header.Required $newOperation.Request.Headers[0].Required
        Assert-AreEqual $header.DefaultValue $newOperation.Request.Headers[0].DefaultValue

        Assert-NotNull $newOperation.Responses
        Assert-AreEqual 1 $newOperation.Responses.Count
        Assert-AreEqual $newOperationResponseStatusCode $newOperation.Responses[0].StatusCode
        Assert-AreEqual $newOperationResponseDescription $newOperation.Responses[0].Description
        Assert-NotNull $newOperation.Responses[0].Representations
        Assert-AreEqual 1 $newOperation.Responses[0].Representations.Count
        Assert-AreEqual $newOperationResponseRepresentationContentType $newOperation.Responses[0].Representations[0].ContentType
        Assert-AreEqual $newOperationResponseRepresentationSample $newOperation.Responses[0].Representations[0].Sample

        

        $newOperationName = getAssetName
        $newOperationMethod = "PUT"
        $newperationUrlTemplate = "/resource/{xrid}?q={xquery}"
        $newOperationDescription = getAssetName
        $newOperationRequestDescription = getAssetName

        $newOperationRequestHeaderParamName = getAssetName
        $newOperationRequestHeaderParamDescr = getAssetName
        $newOperationRequestHeaderParamIsRequired = $TRUE
        $newOperationRequestHeaderParamDefaultValue = getAssetName
        $newOperationRequestHeaderParamType = "string"

        $newOperationRequestParmName = getAssetName
        $newOperationRequestParamDescr = getAssetName
        $newOperationRequestParamIsRequired = $TRUE
        $newOperationRequestParamDefaultValue = getAssetName
        $newOperationRequestParamType = "string"

        $newOperationRequestRepresentationContentType = "application/json"
        $newOperationRequestRepresentationSample = getAssetName

        $newOperationResponseDescription = getAssetName
        $newOperationResponseStatusCode = 1980785443;
        $newOperationResponseRepresentationContentType = getAssetName
        $newOperationResponseRepresentationSample = getAssetName

        
        $rid = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $rid.Name = "xrid"
        $rid.Description = "Resource identifier modified"
        $rid.Type = "string"

        $query = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $query.Name = "xquery"
        $query.Description = "Query string modified"
        $query.Type = "string"

        
        $request = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRequest
        $request.Description = "Create/update resource request modified"

        
        $dummyQp = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $dummyQp.Name = $newOperationRequestParmName
        $dummyQp.Description = $newOperationRequestParamDescr
        $dummyQp.Type = $newOperationRequestParamType
        $dummyQp.Required = $newOperationRequestParamIsRequired
        $dummyQp.DefaultValue = $newOperationRequestParamDefaultValue
        $dummyQp.Values = @($newOperationRequestParamDefaultValue)
        $request.QueryParameters = @($dummyQp)

        
        $header = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
        $header.Name = $newOperationRequestHeaderParamName
        $header.Description = $newOperationRequestHeaderParamDescr
        $header.DefaultValue = $newOperationRequestHeaderParamDefaultValue
        $header.Values = @($newOperationRequestHeaderParamDefaultValue)
        $header.Type = $newOperationRequestHeaderParamType
        $header.Required = $newOperationRequestHeaderParamIsRequired
        $request.Headers = @($header)

        
        $requestRepresentation = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
        $requestRepresentation.ContentType = $newOperationRequestRepresentationContentType
        $requestRepresentation.Sample = $newOperationRequestRepresentationSample
        $request.Representations = @($requestRepresentation)

        
        $response = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementResponse
        $response.StatusCode = $newOperationResponseStatusCode
        $response.Description = $newOperationResponseDescription

        
        $responseRepresentation = New-Object –TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
        $responseRepresentation.ContentType = $newOperationResponseRepresentationContentType
        $responseRepresentation.Sample = $newOperationResponseRepresentationSample
        $response.Representations = @($responseRepresentation)

        $newOperation = Set-AzApiManagementOperation –Context $context –ApiId $api.ApiId –OperationId $newOperationId –Name $newOperationName `
            –Method $newOperationMethod –UrlTemplate $newperationUrlTemplate –Description $newOperationDescription –TemplateParameters @($rid, $query) –Request $request –Responses @($response) -PassThru

        Assert-AreEqual $api.ApiId $newOperation.ApiId
        Assert-AreEqual $newOperationId $newOperation.OperationId
        Assert-AreEqual $newOperationName $newOperation.Name
        Assert-AreEqual $newOperationMethod $newOperation.Method
        Assert-AreEqual $newperationUrlTemplate $newOperation.UrlTemplate
        Assert-AreEqual $newOperationDescription $newOperation.Description

        Assert-NotNull $newOperation.TemplateParameters
        Assert-AreEqual 2 $newOperation.TemplateParameters.Count
        Assert-AreEqual $rid.Name $newOperation.TemplateParameters[0].Name
        Assert-AreEqual $rid.Description $newOperation.TemplateParameters[0].Description
        Assert-AreEqual $rid.Type $newOperation.TemplateParameters[0].Type
        Assert-AreEqual $query.Name $newOperation.TemplateParameters[1].Name
        Assert-AreEqual $query.Description $newOperation.TemplateParameters[1].Description
        Assert-AreEqual $query.Type $newOperation.TemplateParameters[1].Type

        Assert-NotNull $newOperation.Request
        Assert-AreEqual $request.Description $newOperation.Request.Description
        Assert-NotNull $newOperation.Request.QueryParameters
        Assert-AreEqual 1 $newOperation.Request.QueryParameters.Count
        Assert-AreEqual $dummyQp.Name $newOperation.Request.QueryParameters[0].Name
        Assert-AreEqual $dummyQp.Description $newOperation.Request.QueryParameters[0].Description
        Assert-AreEqual $dummyQp.Type $newOperation.Request.QueryParameters[0].Type
        Assert-AreEqual $dummyQp.Required $newOperation.Request.QueryParameters[0].Required
        Assert-AreEqual $dummyQp.DefaultValue $newOperation.Request.QueryParameters[0].DefaultValue

        Assert-AreEqual 1 $newOperation.Request.Headers.Count
        Assert-AreEqual $header.Name $newOperation.Request.Headers[0].Name
        Assert-AreEqual $header.Description $newOperation.Request.Headers[0].Description
        Assert-AreEqual $header.Type $newOperation.Request.Headers[0].Type
        Assert-AreEqual $header.Required $newOperation.Request.Headers[0].Required
        Assert-AreEqual $header.DefaultValue $newOperation.Request.Headers[0].DefaultValue

        Assert-NotNull $newOperation.Responses
        Assert-AreEqual 1 $newOperation.Responses.Count
        Assert-AreEqual $newOperationResponseStatusCode $newOperation.Responses[0].StatusCode
        Assert-AreEqual $newOperationResponseDescription $newOperation.Responses[0].Description
        Assert-NotNull $newOperation.Responses[0].Representations
        Assert-AreEqual 1 $newOperation.Responses[0].Representations.Count
        Assert-AreEqual $newOperationResponseRepresentationContentType $newOperation.Responses[0].Representations[0].ContentType
        Assert-AreEqual $newOperationResponseRepresentationSample $newOperation.Responses[0].Representations[0].Sample
    }
    finally {
        
        $removed = Remove-AzApiManagementOperation -Context $context -ApiId $api.ApiId -OperationId $newOperationId  -PassThru
        Assert-True { $removed }

        $operation = $null
        try {
            
            $operation = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId -OperationId $newOperationId
        }
        catch {
        }

        Assert-Null $operation
    }
}


function Product-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $products = Get-AzApiManagementProduct -Context $context

    
    Assert-AreEqual 2 $products.Count

    $found = 0
    for ($i = 0; $i -lt $products.Count; $i++) {
        Assert-NotNull $products[$i].ProductId
        Assert-NotNull $products[$i].Description
        Assert-AreEqual Published $products[$i].State

        if ($products[$i].Title -eq 'Starter') {
            $found += 1;
        }

        if ($products[$i].Title -eq 'Unlimited') {
            $found += 1;
        }
    }
    Assert-AreEqual 2 $found

    
    $productId = getAssetName
    try {
        $productName = getAssetName
        $productApprovalRequired = $TRUE
        $productDescription = getAssetName
        $productState = "Published"
        $productSubscriptionRequired = $TRUE
        $productSubscriptionsLimit = 10
        $productTerms = getAssetName

        $newProduct = New-AzApiManagementProduct -Context $context –ProductId $productId –Title $productName –Description $productDescription `
            –LegalTerms $productTerms –SubscriptionRequired $productSubscriptionRequired `
            –ApprovalRequired $productApprovalRequired –State $productState -SubscriptionsLimit $productSubscriptionsLimit

        Assert-AreEqual $productId $newProduct.ProductId
        Assert-AreEqual $productName $newProduct.Title
        Assert-AreEqual $productApprovalRequired $newProduct.ApprovalRequired
        Assert-AreEqual $productDescription $newProduct.Description
        Assert-AreEqual $productState $newProduct.State
        Assert-AreEqual $productSubscriptionRequired $newProduct.SubscriptionRequired
        Assert-AreEqual $productSubscriptionsLimit $newProduct.SubscriptionsLimit
        Assert-AreEqual $productTerms $newProduct.LegalTerms

        
        $apis = Get-AzApiManagementApi -Context $context -ProductId $productId
        Assert-AreEqual 0 $apis.Count

        Get-AzApiManagementApi -Context $context | Add-AzApiManagementApiToProduct -Context $context -ProductId $productId

        $apis = Get-AzApiManagementApi -Context $context -ProductId $productId
        Assert-AreEqual 1 $apis.Count
        
        
        $productName = getAssetName
        $productApprovalRequired = $FALSE
        $productDescription = getAssetName
        $productState = "Published"
        $productSubscriptionRequired = $TRUE
        $productSubscriptionsLimit = 20
        $productTerms = getAssetName

        $newProduct = Set-AzApiManagementProduct -Context $context –ProductId $productId –Title $productName –Description $productDescription `
            –LegalTerms $productTerms -ApprovalRequired $productApprovalRequired `
            –SubscriptionRequired $TRUE –State $productState -SubscriptionsLimit $productSubscriptionsLimit -PassThru

        Assert-AreEqual $productId $newProduct.ProductId
        Assert-AreEqual $productName $newProduct.Title
        Assert-AreEqual $productApprovalRequired $newProduct.ApprovalRequired
        Assert-AreEqual $productDescription $newProduct.Description
        Assert-AreEqual $productState $newProduct.State
        Assert-AreEqual $productSubscriptionRequired $newProduct.SubscriptionRequired
        Assert-AreEqual $productSubscriptionsLimit $newProduct.SubscriptionsLimit
        Assert-AreEqual $productTerms $newProduct.LegalTerms

        
        $newProduct = Get-AzApiManagementProduct -Context $context -Title $productName
        Assert-NotNull $newProduct
        Assert-AreEqual $productName $newProduct.Title

		
		$products = Get-AzApiManagementProduct -Context $context -ApiId $apis[0].ApiId
		Assert-NotNull $products

		
		Assert-AreEqual 3 $products.Count
		
		$found = 0
		for ($i = 0; $i -lt $products.Count; $i++) {
			Assert-NotNull $products[$i].ProductId
			Assert-NotNull $products[$i].Description
			Assert-AreEqual Published $products[$i].State

			if ($products[$i].Title -eq 'Starter') {
	            $found += 1;
			}

	        if ($products[$i].Title -eq 'Unlimited') {
		        $found += 1;
			}

			if ($products[$i].Title -eq $productName) {
		        $found += 1;
			}
		}
		Assert-AreEqual 3 $found

        
        Get-AzApiManagementApi -Context $context | Remove-AzApiManagementApiFromProduct -Context $context -ProductId $productId

        $apis = Get-AzApiManagementApi -Context $context -ProductId $productId
        Assert-AreEqual 0 $apis.Count
    }
    finally {
        
        $removed = Remove-AzApiManagementProduct -Context $context -ProductId $productId -DeleteSubscriptions -PassThru
        Assert-True { $removed }
    }
}


function SubscriptionOldModel-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $subs = Get-AzApiManagementSubscription -Context $context

    Assert-AreEqual 3 $subs.Count
    for ($i = 0; $i -lt $subs.Count; $i++) {
        Assert-NotNull $subs[$i]
        Assert-NotNull $subs[$i].SubscriptionId
        Assert-NotNull $subs[$i].Scope
        Assert-NotNull $subs[$i].State
        Assert-NotNull $subs[$i].CreatedDate
        Assert-NotNull $subs[$i].PrimaryKey
        Assert-NotNull $subs[$i].SecondaryKey

        
        $sub = Get-AzApiManagementSubscription -Context $context -SubscriptionId $subs[$i].SubscriptionId

        Assert-AreEqual $subs[$i].SubscriptionId $sub.SubscriptionId
        Assert-NotNull $subs[$i].Scope
        Assert-AreEqual $subs[$i].State $sub.State
        Assert-AreEqual $subs[$i].CreatedDate $sub.CreatedDate
        Assert-AreEqual $subs[$i].PrimaryKey $sub.PrimaryKey
        Assert-AreEqual $subs[$i].SecondaryKey $sub.SecondaryKey
    }

    
    Set-AzApiManagementProduct -Context $context -ProductId $subs[0].ProductId -SubscriptionsLimit 100

    
    $newSubscriptionId = getAssetName
    try {
        $newSubscriptionName = getAssetName
        $newSubscriptionPk = getAssetName
        $newSubscriptionSk = getAssetName
        $newSubscriptionState = "Active"

        $sub = New-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId -UserId $subs[0].UserId `
            -ProductId $subs[0].ProductId -Name $newSubscriptionName -PrimaryKey $newSubscriptionPk -SecondaryKey $newSubscriptionSk `
            -State $newSubscriptionState

        Assert-AreEqual $newSubscriptionId $sub.SubscriptionId
        Assert-AreEqual $newSubscriptionName $sub.Name
        Assert-AreEqual $newSubscriptionPk $sub.PrimaryKey
        Assert-AreEqual $newSubscriptionSk $sub.SecondaryKey
        Assert-AreEqual $newSubscriptionState $sub.State

        
        $patchedName = getAssetName
        $patchedPk = getAssetName
        $patchedSk = getAssetName
        $patchedExpirationDate = [DateTime]::Parse('2025-7-20')

        $sub = Set-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId -Name $patchedName `
            -PrimaryKey $patchedPk -SecondaryKey $patchedSk -ExpiresOn $patchedExpirationDate -PassThru

        Assert-AreEqual $newSubscriptionId $sub.SubscriptionId
        Assert-AreEqual $patchedName $sub.Name
        Assert-AreEqual $patchedPk $sub.PrimaryKey
        Assert-AreEqual $patchedSk $sub.SecondaryKey
        Assert-AreEqual $newSubscriptionState $sub.State
        Assert-AreEqual $patchedExpirationDate $sub.ExpirationDate

        
        $productSubs = Get-AzApiManagementSubscription -Context $context -ProductId $subs[0].ProductId

        Assert-AreEqual 2 $productSubs.Count
        for ($i = 0; $i -lt $productSubs.Count; $i++) 
        {
            Assert-NotNull $productSubs[$i]
            Assert-NotNull $productSubs[$i].SubscriptionId
            Assert-NotNull $productSubs[$i].Scope
            Assert-NotNull $productSubs[$i].State
            Assert-NotNull $productSubs[$i].CreatedDate
            Assert-NotNull $productSubs[$i].PrimaryKey
            Assert-NotNull $productSubs[$i].SecondaryKey

            Assert-AreEqual $subs[0].ProductId $productSubs[$i].ProductId
        }

        
        $userSubs = Get-AzApiManagementSubscription -Context $context -UserId $subs[0].UserId

        Assert-AreEqual 3 $userSubs.Count
        for ($i = 0; $i -lt $userSubs.Count; $i++) 
        {
            Assert-NotNull $userSubs[$i]
            Assert-NotNull $userSubs[$i].SubscriptionId
            Assert-NotNull $userSubs[$i].Scope
            Assert-NotNull $userSubs[$i].State
            Assert-NotNull $userSubs[$i].CreatedDate
            Assert-NotNull $userSubs[$i].PrimaryKey
            Assert-NotNull $userSubs[$i].SecondaryKey

            Assert-AreEqual $subs[0].UserId $userSubs[$i].UserId
        }

        
        $productUserSubs = Get-AzApiManagementSubscription -Context $context -UserId $subs[0].UserId -ProductId $subs[0].ProductId

        Assert-AreEqual 2 $productUserSubs.Count
        for ($i = 0; $i -lt $productUserSubs.Count; $i++) 
        {
            Assert-NotNull $productUserSubs[$i]
            Assert-NotNull $productUserSubs[$i].SubscriptionId
            Assert-NotNull $productUserSubs[$i].Scope
            Assert-NotNull $productUserSubs[$i].State
            Assert-NotNull $productUserSubs[$i].CreatedDate
            Assert-NotNull $productUserSubs[$i].PrimaryKey
            Assert-NotNull $productUserSubs[$i].SecondaryKey

            Assert-AreEqual $subs[0].UserId $productUserSubs[$i].UserId
            Assert-AreEqual $subs[0].ProductId $productUserSubs[$i].ProductId
        }
    }
    finally {
        
        $removed = Remove-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId  -PassThru
        Assert-True { $removed }

        $sub = $null
        try {
            
            $sub = Get-AzApiManagementSubscripiton -Context $context -SubscriptionId $newSubscriptionId
        }
        catch {
        }

        Assert-Null $sub
    }
}


function SubscriptionNewModel-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $subs = Get-AzApiManagementSubscription -Context $context

    Assert-AreEqual 3 $subs.Count
    for ($i = 0; $i -lt $subs.Count; $i++) {
        Assert-NotNull $subs[$i]
        Assert-NotNull $subs[$i].SubscriptionId
        Assert-NotNull $subs[$i].Scope
        Assert-NotNull $subs[$i].State
        Assert-NotNull $subs[$i].CreatedDate
        Assert-NotNull $subs[$i].PrimaryKey
        Assert-NotNull $subs[$i].SecondaryKey

        
        $sub = Get-AzApiManagementSubscription -Context $context -SubscriptionId $subs[$i].SubscriptionId

        Assert-AreEqual $subs[$i].SubscriptionId $sub.SubscriptionId
        Assert-NotNull $subs[$i].Scope
        Assert-AreEqual $subs[$i].State $sub.State
        Assert-AreEqual $subs[$i].CreatedDate $sub.CreatedDate
        Assert-AreEqual $subs[$i].PrimaryKey $sub.PrimaryKey
        Assert-AreEqual $subs[$i].SecondaryKey $sub.SecondaryKey
    }

    
    $newSubscriptionId = getAssetName
    try {
        $newSubscriptionName = getAssetName
        $newSubscriptionPk = getAssetName
        $newSubscriptionSk = getAssetName
        $newSubscriptionState = "Active"
        $allApisScope = "/apis"

        $sub = New-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId `
            -Scope $allApisScope -Name $newSubscriptionName -PrimaryKey $newSubscriptionPk -SecondaryKey $newSubscriptionSk `
            -State $newSubscriptionState

        Assert-AreEqual $newSubscriptionId $sub.SubscriptionId
        Assert-AreEqual $newSubscriptionName $sub.Name
        Assert-AreEqual $newSubscriptionPk $sub.PrimaryKey
        Assert-AreEqual $newSubscriptionSk $sub.SecondaryKey
        Assert-AreEqual $newSubscriptionState $sub.State
        Assert-Null $sub.UserId
        Assert-Null $sub.OwnerId

        
        $patchedName = getAssetName
        $patchedPk = getAssetName
        $patchedSk = getAssetName
        $patchedExpirationDate = [DateTime]::Parse('2025-7-20')

        $sub = Set-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId -Name $patchedName `
            -UserId $subs[0].UserId -PrimaryKey $patchedPk -SecondaryKey $patchedSk -ExpiresOn $patchedExpirationDate -PassThru

        Assert-AreEqual $newSubscriptionId $sub.SubscriptionId
        Assert-AreEqual $patchedName $sub.Name
        Assert-AreEqual $patchedPk $sub.PrimaryKey
        Assert-AreEqual $patchedSk $sub.SecondaryKey
        Assert-AreEqual $newSubscriptionState $sub.State
        Assert-AreEqual $patchedExpirationDate $sub.ExpirationDate
        Assert-NotNull $sub.UserId
        Assert-AreEqual 1 $sub.UserId
        Assert-NotNull $sub.OwnerId

        
        $sub = Get-AzApiManagementSubscription -Context $context -Scope $allApisScope

        Assert-AreEqual $newSubscriptionId $sub.SubscriptionId
        Assert-AreEqual $patchedName $sub.Name
        Assert-AreEqual $patchedPk $sub.PrimaryKey
        Assert-AreEqual $patchedSk $sub.SecondaryKey
        Assert-AreEqual $newSubscriptionState $sub.State
        Assert-AreEqual $patchedExpirationDate $sub.ExpirationDate
        Assert-NotNull $sub.UserId
        Assert-AreEqual 1 $sub.UserId
        Assert-NotNull $sub.OwnerId
    }
    finally {
        
        $removed = Remove-AzApiManagementSubscription -Context $context -SubscriptionId $newSubscriptionId  -PassThru
        Assert-True { $removed }

        $sub = $null
        try {
            
            $sub = Get-AzApiManagementSubscripiton -Context $context -SubscriptionId $newSubscriptionId
        }
        catch {
        }

        Assert-Null $sub
    }
}


function User-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $users = Get-AzApiManagementUser -Context $context

    Assert-AreEqual 1 $users.Count
    Assert-NotNull $users[0].UserId
    Assert-NotNull $users[0].FirstName
    Assert-NotNull $users[0].LastName
    Assert-NotNull $users[0].Email
    Assert-NotNull $users[0].State
    Assert-NotNull $users[0].RegistrationDate

    
    $user = Get-AzApiManagementUser -Context $context -UserId $users[0].UserId

    Assert-AreEqual $users[0].UserId $user.UserId
    Assert-AreEqual $users[0].FirstName $user.FirstName
    Assert-AreEqual $users[0].LastName $user.LastName
    Assert-AreEqual $users[0].Email $user.Email
    Assert-AreEqual $users[0].State $user.State
    Assert-AreEqual $users[0].RegistrationDate $user.RegistrationDate

    
    $userId = getAssetName
    try {
        $userEmail = "contoso@microsoft.com"
        $userFirstName = getAssetName
        $userLastName = getAssetName
        $userPassword = getAssetName
        $userNote = getAssetName
        $userState = "Active"

        $secureUserPassword = ConvertTo-SecureString -String $userPassword -AsPlainText -Force

        $user = New-AzApiManagementUser -Context $context -UserId $userId -FirstName $userFirstName -LastName $userLastName `
            -Password $secureUserPassword -State $userState -Note $userNote -Email $userEmail

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userNote $user.Note
        Assert-AreEqual $userState $user.State

        
        $userEmail = "changed.contoso@microsoft.com"
        $userFirstName = getAssetName
        $userLastName = getAssetName
        $userPassword = getAssetName
        $userNote = getAssetName
        $userState = "Active"

        $secureUserPassword = ConvertTo-SecureString -String $userPassword -AsPlainText -Force

        $user = Set-AzApiManagementUser -Context $context -UserId $userId -FirstName $userFirstName -LastName $userLastName `
            -Password $secureUserPassword -State $userState -Note $userNote -PassThru -Email $userEmail

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userNote $user.Note
        Assert-AreEqual $userState $user.State

        
        $user = Get-AzApiManagementUser -Context $context -Email $userEmail

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName

        
        $user = Get-AzApiManagementUser -Context $context -FirstName $userFirstName

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName

        
        $user = Get-AzApiManagementUser -Context $context -LastName $userLastName

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userLastName $user.LastName

        
        $user = Get-AzApiManagementUser -Context $context -LastName $userLastName -FirstName $userFirstName

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userFirstName $user.FirstName

        
        $userState = "Blocked"
        $user = Set-AzApiManagementUser -Context $context -UserId $userId -State $userState -PassThru
        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userNote $user.Note
        Assert-AreEqual $userState $user.State

        
        $user = Get-AzApiManagementUser -Context $context -State $userState

        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userState $user.State

        
        $userState = "Active"
        $user = Set-AzApiManagementUser -Context $context -UserId $userId -State $userState -PassThru
        Assert-AreEqual $userId $user.UserId
        Assert-AreEqual $userEmail $user.Email
        Assert-AreEqual $userFirstName $user.FirstName
        Assert-AreEqual $userLastName $user.LastName
        Assert-AreEqual $userNote $user.Note
        Assert-AreEqual $userState $user.State

        
        $ssoUrl = Get-AzApiManagementUserSsoUrl -Context $context -UserId $userId

        Assert-NotNull $ssoUrl
        Assert-AreEqual $true [System.Uri]::IsWellFormedUriString($ssoUrl, 'Absolute')

        
        $token = New-AzApiManagementUserToken -Context $context -UserId $userId

        Assert-NotNull $token
    }
    finally {
        
        $removed = Remove-AzApiManagementUser -Context $context -UserId $userId -DeleteSubscriptions  -PassThru
        Assert-True { $removed }

        $user = $null
        try {
            
            $user = Get-AzApiManagementUser -Context $context -UserId $userId
        }
        catch {
        }

        Assert-Null $user
    }
}


function Group-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $groups = Get-AzApiManagementGroup -Context $context

    Assert-AreEqual 3 $groups.Count
    for ($i = 0; $i -lt 3; $i++) {
        Assert-NotNull $groups[$i].GroupId
        Assert-NotNull $groups[$i].Name
        Assert-NotNull $groups[$i].Description
        Assert-NotNull $groups[$i].System
        Assert-NotNull $groups[$i].Type

        
        $group = Get-AzApiManagementGroup -Context $context -GroupId $groups[$i].GroupId

        Assert-AreEqual $group.GroupId $groups[$i].GroupId
        Assert-AreEqual $group.Name $groups[$i].Name
        Assert-AreEqual $group.Description $groups[$i].Description
        Assert-AreEqual $group.System $groups[$i].System
        Assert-AreEqual $group.Type $groups[$i].Type
    }

    
    $groupId = getAssetName
    $externalgroupId = getAssetName
    try {
        $newGroupName = getAssetName
        $newGroupDescription = getAssetName

        
        $group = New-AzApiManagementGroup -GroupId $groupId -Context $context -Name $newGroupName -Description $newGroupDescription

        Assert-AreEqual $groupId $group.GroupId
        Assert-AreEqual $newGroupName $group.Name
        Assert-AreEqual $newGroupDescription $group.Description
        Assert-AreEqual $false $group.System
        Assert-AreEqual 'Custom' $group.Type

        
        $newGroupName = getAssetName
        $newGroupDescription = getAssetName

        $group = Set-AzApiManagementGroup -Context $context -GroupId $groupId -Name $newGroupName -Description $newGroupDescription -PassThru

        Assert-AreEqual $groupId $group.GroupId
        Assert-AreEqual $newGroupName $group.Name
        Assert-AreEqual $newGroupDescription $group.Description
        Assert-AreEqual $false $group.System
        Assert-AreEqual 'Custom' $group.Type

        
        $product = Get-AzApiManagementProduct -Context $context | Select -First 1
        Add-AzApiManagementProductToGroup -Context $context -GroupId $groupId -ProductId $product.ProductId

        
        $groups = Get-AzApiManagementGroup -Context $context -ProductId $product.ProductId
        Assert-AreEqual 4 $groups.Count

        
        Remove-AzApiManagementProductFromGroup -Context $context -GroupId $groupId -ProductId $product.ProductId

        
        $groups = Get-AzApiManagementGroup -Context $context -ProductId $product.ProductId
        Assert-AreEqual 3 $groups.Count

        
        $user = Get-AzApiManagementUser -Context $context | Select -First 1
        Add-AzApiManagementUserToGroup -Context $context -GroupId $groupId -UserId $user.UserId

        $groups = Get-AzApiManagementGroup -Context $context -UserId $user.UserId
        Assert-AreEqual 3 $groups.Count

        
        Remove-AzApiManagementUserFromGroup -Context $context -GroupId $groupId -UserId $user.UserId
        $groups = Get-AzApiManagementGroup -Context $context -UserId $user.UserId
        Assert-AreEqual 2 $groups.Count

        
        $externalgroupname = getAssetName
        $externalgroupdescription = getAssetName
        $externalgroup = New-AzApiManagementGroup -GroupId $externalgroupId -Context $context -Name $externalgroupname -Type 'External' -Description $externalgroupdescription

        Assert-AreEqual $externalgroupId $externalgroup.GroupId
        Assert-AreEqual $externalgroupname $externalgroup.Name
        Assert-AreEqual $externalgroupdescription $externalgroup.Description
        Assert-AreEqual $false $externalgroup.System
        Assert-AreEqual 'External' $externalgroup.Type
    }
    finally {
        
        $removed = Remove-AzApiManagementGroup -Context $context -GroupId $groupId -PassThru
        Assert-True { $removed }

        $group = $null
        try {
            
            $group = Get-AzApiManagementGroup -Context $context -GroupId $groupId
        }
        catch {
        }

        Assert-Null $group

        
        $removed = Remove-AzApiManagementGroup -Context $context -GroupId $externalgroupId -PassThru
        Assert-True { $removed }
        $group = $null
        try {
            
            $group = Get-AzApiManagementGroup -Context $context -GroupId $externalgroupId
        }
        catch {
        }

        Assert-Null $group
    }
}


function Policy-CrudTest {
    Param($resourceGroupName, $serviceName)

    

    $tenantValidPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "TenantValidPolicy.xml"
    $productValidPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "ProductValidPolicy.xml"
    $apiValidPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "ApiValidPolicy.xml"
    $operationValidPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "OperationValidPolicy.xml"

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -PolicyFilePath $tenantValidPath -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context
        Assert-NotNull $policy
        Assert-True { $policy -like '*<find-and-replace from="aaa" to="BBB" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context
        Assert-Null $policy
    }

    
    $product = Get-AzApiManagementProduct -Context $context -Title 'Unlimited' | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -PolicyFilePath $productValidPath -ProductId $product.ProductId -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context  -ProductId $product.ProductId
        Assert-NotNull $policy
        Assert-True { $policy -like '*<rate-limit calls="5" renewal-period="60" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ProductId $product.ProductId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ProductId $product.ProductId
        Assert-Null $policy
    }

    
    $api = Get-AzApiManagementApi -Context $context | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -PolicyFilePath $apiValidPath -ApiId $api.ApiId -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId
        Assert-NotNull $policy
        Assert-True { $policy -like '*<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none">*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ApiId $api.ApiId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId
        Assert-Null $policy
    }

    
    $api = Get-AzApiManagementApi -Context $context | Select-Object -First 1
    $operation = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -PolicyFilePath $operationValidPath -ApiId $api.ApiId `
            -OperationId $operation.OperationId -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId -OperationId $operation.OperationId
        Assert-NotNull $policy
        Assert-True { $policy -like '*<rewrite-uri template="/resource" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ApiId $api.ApiId -OperationId $operation.OperationId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId -OperationId $operation.OperationId
        Assert-Null $policy
    }

    

    
    $tenantValid = '<policies><inbound><find-and-replace from="aaa" to="BBB" /><set-header name="ETag" exists-action="skip"><value>bbyby</value><!-- for multiple headers with the same name add additional value elements --></set-header><set-query-parameter name="additional" exists-action="append"><value>xxbbcczc</value><!-- for multiple parameters with the same name add additional value elements --></set-query-parameter><cross-domain /></inbound><outbound /></policies>'
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -Policy $tenantValid -PassThru
        Assert-AreEqual $true $set

        Get-AzApiManagementPolicy -Context $context  -SaveAs "$TestOutputRoot/TenantPolicy.xml" -Force
        $exists = [System.IO.File]::Exists((Join-Path "$TestOutputRoot" "TenantPolicy.xml"))
        $policy = gc (Join-Path "$TestOutputRoot" "TenantPolicy.xml")
        Assert-True { $policy -like '*<find-and-replace from="aaa" to="BBB" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context
        Assert-Null $policy
    }

    
    $productValid = '<policies><inbound><rate-limit calls="5" renewal-period="60" /><quota calls="100" renewal-period="604800" /><base /></inbound><outbound><base /></outbound></policies>'
    $product = Get-AzApiManagementProduct -Context $context -Title 'Unlimited' | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -Policy $productValid -ProductId $product.ProductId -PassThru
        Assert-AreEqual $true $set

        Get-AzApiManagementPolicy -Context $context  -ProductId $product.ProductId -SaveAs "$TestOutputRoot/ProductPolicy.xml" -Format 'RawXml' -Force
        $exists = [System.IO.File]::Exists((Join-Path "$TestOutputRoot" "ProductPolicy.xml"))
        $policy = gc (Join-Path "$TestOutputRoot" "ProductPolicy.xml")
        Assert-True { $policy -like '*<rate-limit calls="5" renewal-period="60" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ProductId $product.ProductId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ProductId $product.ProductId
        Assert-Null $policy

        try {
            rm (Join-Path "$TestOutputRoot" "ProductPolicy.xml")
        }
        catch { }
    }

    
    $apiValid = '<policies><inbound><base /><cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none"><vary-by-query-parameter>version</vary-by-query-parameter><vary-by-header>Accept</vary-by-header><vary-by-header>Accept-Charset</vary-by-header></cache-lookup></inbound><outbound><cache-store duration="10" /><base /></outbound></policies>'
    $api = Get-AzApiManagementApi -Context $context | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -Policy $apiValid -ApiId $api.ApiId -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId -SaveAs (Join-Path "$TestOutputRoot" "ApiPolicy.xml") -Format 'RawXml' -Force
        $exists = [System.IO.File]::Exists((Join-Path "$TestOutputRoot" "ApiPolicy.xml"))
        $policy = gc (Join-Path "$TestOutputRoot" "ApiPolicy.xml")
        Assert-True { $policy -like '*<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none">*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ApiId $api.ApiId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId
        Assert-Null $policy

        try {
            rm (Join-Path "$TestOutputRoot" "ApiPolicy.xml")
        }
        catch { }
    }

    
    $operationValid = '<policies><inbound><base /><rewrite-uri template="/resource" /></inbound><outbound><base /></outbound></policies>'
    $api = Get-AzApiManagementApi -Context $context | Select -First 1
    $operation = Get-AzApiManagementOperation -Context $context -ApiId $api.ApiId | Select-Object -First 1
    try {
        $set = Set-AzApiManagementPolicy -Context $context  -Policy $operationValid -ApiId $api.ApiId `
            -OperationId $operation.OperationId -PassThru
        Assert-AreEqual $true $set

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId -OperationId $operation.OperationId `
            -SaveAs (Join-Path "$TestOutputRoot" "OperationPolicy.xml") -Format 'RawXml' -Force
        $exists = [System.IO.File]::Exists((Join-Path "$TestOutputRoot" "OperationPolicy.xml"))
        $policy = gc (Join-Path "$TestOutputRoot" "OperationPolicy.xml")
        Assert-True { $policy -like '*<rewrite-uri template="/resource" />*' }
    }
    finally {
        $removed = Remove-AzApiManagementPolicy -Context $context -ApiId $api.ApiId -OperationId $operation.OperationId -PassThru
        Assert-AreEqual $true $removed

        $policy = Get-AzApiManagementPolicy -Context $context  -ApiId $api.ApiId -OperationId $operation.OperationId
        Assert-Null $policy

        try {
            rm (Join-Path "$TestOutputRoot" "OperationPolicy.xml")
        }
        catch { }
    }
}


function Certificate-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $certificates = Get-AzApiManagementCertificate -Context $context

    Assert-AreEqual 0 $certificates.Count

    $certPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "powershelltest.pfx"
    
    $certPassword = 'Password'
    $certSubject = "CN=*.msitesting.net"
    $certThumbprint = '8E989652CABCF585ACBFCB9C2C91F1D174FDB3A2'

    $certId = getAssetName
    try {
        
        $cert = New-AzApiManagementCertificate -Context $context -CertificateId $certId -PfxFilePath $certPath -PfxPassword $certPassword

        Assert-AreEqual $certId $cert.CertificateId
        Assert-AreEqual $certThumbprint $cert.Thumbprint
        Assert-AreEqual $certSubject $cert.Subject

        
        $cert = Get-AzApiManagementCertificate -Context $context -CertificateId $certId

        Assert-AreEqual $certId $cert.CertificateId
        Assert-AreEqual $certThumbprint $cert.Thumbprint
        Assert-AreEqual $certSubject $cert.Subject

        
        $cert = Get-AzApiManagementCertificate -ResourceId $cert.Id

        Assert-AreEqual $certId $cert.CertificateId
        Assert-AreEqual $certThumbprint $cert.Thumbprint
        Assert-AreEqual $certSubject $cert.Subject

        
        $cert = Set-AzApiManagementCertificate -Context $context -CertificateId $certId -PfxFilePath $certPath -PfxPassword $certPassword -PassThru

        Assert-AreEqual $certId $cert.CertificateId
        Assert-AreEqual $certThumbprint $cert.Thumbprint
        Assert-AreEqual $certSubject $cert.Subject

        
        $certificates = Get-AzApiManagementCertificate -Context $context
        Assert-AreEqual 1 $certificates.Count

        Assert-AreEqual $certId $certificates[0].CertificateId
        Assert-AreEqual $certThumbprint $certificates[0].Thumbprint
        Assert-AreEqual $certSubject $certificates[0].Subject
    }
    finally {
        
        $removed = Remove-AzApiManagementCertificate -Context $context -CertificateId $certId  -PassThru
        Assert-True { $removed }

        $cert = $null
        try {
            
            $cert = Get-AzApiManagementCertificate -Context $context -CertificateId $certId
        }
        catch {
        }

        Assert-Null $cert
    }
}


function Cache-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $caches = Get-AzApiManagementCache -Context $context

    Assert-AreEqual 0 $caches.Count

    $cacheDescription = getAssetName
    $cacheConnectionString = 'teamdemo.redis.cache.windows.net:6380,password=xxxxxx+xxxxx=,ssl=True,abortConnect=False'

    $cacheId = "default"
    try {
        
        $cache = New-AzApiManagementCache -Context $context -CacheId $cacheId -ConnectionString $cacheConnectionString -Description $cacheDescription

        Assert-AreEqual $cacheId $cache.CacheId
        Assert-NotNull $cache.ConnectionString
        Assert-AreEqual $cacheDescription $cache.Description

        
        $cache = Get-AzApiManagementCache -Context $context -CacheId $cacheId

        Assert-AreEqual $cacheId $cache.CacheId
        Assert-NotNull $cache.ConnectionString
        Assert-AreEqual $cacheDescription $cache.Description

		
		$cache = Get-AzApiManagementCache -ResourceId $cache.Id

		Assert-AreEqual $cacheId $cache.CacheId
        Assert-NotNull $cache.ConnectionString
        Assert-AreEqual $cacheDescription $cache.Description

        
        $newDescription = getAssetName
        $cache.Description = $newDescription
        $cache = Update-AzApiManagementCache -InputObject $cache -PassThru

        Assert-AreEqual $cacheId $cache.CacheId
        Assert-NotNull $cache.ConnectionString
        Assert-AreEqual $newDescription $cache.Description

        
        $caches = Get-AzApiManagementCache -Context $context
        Assert-AreEqual 1 $caches.Count

        Assert-AreEqual $cacheId $caches[0].CacheId
        Assert-NotNull $caches[0].ConnectionString
        Assert-AreEqual $newDescription $caches[0].Description
    }
    finally {
        
        $removed = Remove-AzApiManagementCache -Context $context -CacheId $cacheId  -PassThru
        Assert-True { $removed }

        $cache = $null
        try {
            
            $cache = Get-AzApiManagementCache -Context $context -CacheId $cacheId
        }
        catch {
        }

        Assert-Null $cache

        
        $properties = Get-AzApiManagementProperty -Context $context
        for ($i = 0; $i -lt $properties.Count; $i++) {
            Remove-AzApiManagementProperty -Context $context -PropertyId $properties[$i].PropertyId
        }
    }
}


function AuthorizationServer-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $servers = Get-AzApiManagementAuthorizationServer -Context $context

    Assert-AreEqual 0 $servers.Count

    
    $serverId = getAssetName
    try {
        $name = getAssetName
        $defaultScope = getAssetName
        $authorizationEndpoint = 'https://contoso.com/auth'
        $tokenEndpoint = 'https://contoso.com/token'
        $clientRegistrationEndpoint = 'https://contoso.com/clients/reg'
        $grantTypes = @('AuthorizationCode', 'Implicit', 'ResourceOwnerPassword')
        $authorizationMethods = @('Post', 'Get')
        $bearerTokenSendingMethods = @('AuthorizationHeader', 'Query')
        $clientId = getAssetName
        $description = getAssetName
        $clientAuthenticationMethods = @('Basic')
        $clientSecret = getAssetName
        $resourceOwnerPassword = getAssetName
        $resourceOwnerUsername = getAssetName
        $supportState = $true
        $tokenBodyParameters = @{'tokenname' = 'tokenvalue' }

        $server = New-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId -Name $name -Description $description `
            -ClientRegistrationPageUrl $clientRegistrationEndpoint -AuthorizationEndpointUrl $authorizationEndpoint `
            -TokenEndpointUrl $tokenEndpoint -ClientId $clientId -ClientSecret $clientSecret -AuthorizationRequestMethods $authorizationMethods `
            -GrantTypes $grantTypes -ClientAuthenticationMethods $clientAuthenticationMethods -TokenBodyParameters $tokenBodyParameters `
            -SupportState $supportState -DefaultScope $defaultScope -AccessTokenSendingMethods $bearerTokenSendingMethods `
            -ResourceOwnerUsername $resourceOwnerUsername -ResourceOwnerPassword $resourceOwnerPassword

        Assert-AreEqual $serverId $server.ServerId
        Assert-AreEqual $name $server.Name
        Assert-AreEqual $defaultScope $server.DefaultScope
        Assert-AreEqual $authorizationEndpoint $server.AuthorizationEndpointUrl
        Assert-AreEqual $tokenEndpoint $server.TokenEndpointUrl
        Assert-AreEqual $clientRegistrationEndpoint $server.ClientRegistrationPageUrl
        Assert-AreEqual $grantTypes.Count $server.GrantTypes.Count
        Assert-AreEqual $grantTypes[0] $server.GrantTypes[0]
        Assert-AreEqual $grantTypes[1] $server.GrantTypes[1]
        Assert-AreEqual $grantTypes[2] $server.GrantTypes[2]
        Assert-AreEqual $authorizationMethods.Count $server.AuthorizationRequestMethods.Count
        Assert-AreEqual $authorizationMethods[0] $server.AuthorizationRequestMethods[0]
        Assert-AreEqual $authorizationMethods[1] $server.AuthorizationRequestMethods[1]
        Assert-AreEqual $bearerTokenSendingMethods.Count $server.AccessTokenSendingMethods.Count
        Assert-AreEqual $bearerTokenSendingMethods[0] $server.AccessTokenSendingMethods[0]
        Assert-AreEqual $bearerTokenSendingMethods[1] $server.AccessTokenSendingMethods[1]
        Assert-AreEqual $clientId $server.ClientId
        Assert-AreEqual $description $server.Description
        Assert-AreEqual $clientAuthenticationMethods.Count $server.ClientAuthenticationMethods.Count
        Assert-AreEqual $clientAuthenticationMethods[0] $server.ClientAuthenticationMethods[0]
        Assert-AreEqual $clientSecret $server.ClientSecret
        Assert-AreEqual $resourceOwnerPassword $server.ResourceOwnerPassword
        Assert-AreEqual $resourceOwnerUsername $server.ResourceOwnerUsername
        Assert-AreEqual $supportState $server.SupportState
        Assert-AreEqual $tokenBodyParameters.Count $server.TokenBodyParameters.Count

        $server = Get-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId

        Assert-AreEqual $serverId $server.ServerId
        Assert-AreEqual $name $server.Name
        Assert-AreEqual $defaultScope $server.DefaultScope
        Assert-AreEqual $authorizationEndpoint $server.AuthorizationEndpointUrl
        Assert-AreEqual $tokenEndpoint $server.TokenEndpointUrl
        Assert-AreEqual $clientRegistrationEndpoint $server.ClientRegistrationPageUrl
        Assert-AreEqual $grantTypes.Count $server.GrantTypes.Count
        Assert-AreEqual $grantTypes[0] $server.GrantTypes[0]
        Assert-AreEqual $grantTypes[1] $server.GrantTypes[1]
        Assert-AreEqual $grantTypes[2] $server.GrantTypes[2]
        Assert-AreEqual $authorizationMethods.Count $server.AuthorizationRequestMethods.Count
        Assert-AreEqual $authorizationMethods[0] $server.AuthorizationRequestMethods[0]
        Assert-AreEqual $authorizationMethods[1] $server.AuthorizationRequestMethods[1]
        Assert-AreEqual $bearerTokenSendingMethods.Count $server.AccessTokenSendingMethods.Count
        Assert-AreEqual $bearerTokenSendingMethods[0] $server.AccessTokenSendingMethods[0]
        Assert-AreEqual $bearerTokenSendingMethods[1] $server.AccessTokenSendingMethods[1]
        Assert-AreEqual $clientId $server.ClientId
        Assert-AreEqual $description $server.Description
        Assert-AreEqual $clientAuthenticationMethods.Count $server.ClientAuthenticationMethods.Count
        Assert-AreEqual $clientAuthenticationMethods[0] $server.ClientAuthenticationMethods[0]
        Assert-AreEqual $clientSecret $server.ClientSecret
        Assert-AreEqual $resourceOwnerPassword $server.ResourceOwnerPassword
        Assert-AreEqual $resourceOwnerUsername $server.ResourceOwnerUsername
        Assert-AreEqual $supportState $server.SupportState
        Assert-AreEqual $tokenBodyParameters.Count $server.TokenBodyParameters.Count

        
        $name = getAssetName
        $defaultScope = getAssetName
        $authorizationEndpoint = 'https://contoso.com/authv2'
        $tokenEndpoint = 'https://contoso.com/tokenv2'
        $clientRegistrationEndpoint = 'https://contoso.com/clients/regv2'
        $grantTypes = @('AuthorizationCode', 'Implicit', 'ClientCredentials')
        $authorizationMethods = @('Get')
        $bearerTokenSendingMethods = @('AuthorizationHeader')
        $clientId = getAssetName
        $description = getAssetName
        $clientAuthenticationMethods = @('Basic')
        $clientSecret = getAssetName
        $supportState = $false
        $tokenBodyParameters = @{'tokenname1' = 'tokenvalue1' }

        $server = Set-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId -Name $name -Description $description `
            -ClientRegistrationPageUrl $clientRegistrationEndpoint -AuthorizationEndpointUrl $authorizationEndpoint `
            -TokenEndpointUrl $tokenEndpoint -ClientId $clientId -ClientSecret $clientSecret -AuthorizationRequestMethods $authorizationMethods `
            -GrantTypes $grantTypes -ClientAuthenticationMethods $clientAuthenticationMethods -TokenBodyParameters $tokenBodyParameters `
            -SupportState $supportState -DefaultScope $defaultScope -AccessTokenSendingMethods $bearerTokenSendingMethods -PassThru

        Assert-AreEqual $serverId $server.ServerId
        Assert-AreEqual $name $server.Name
        Assert-AreEqual $defaultScope $server.DefaultScope
        Assert-AreEqual $authorizationEndpoint $server.AuthorizationEndpointUrl
        Assert-AreEqual $tokenEndpoint $server.TokenEndpointUrl
        Assert-AreEqual $clientRegistrationEndpoint $server.ClientRegistrationPageUrl
        Assert-AreEqual $grantTypes.Count $server.GrantTypes.Count
        Assert-AreEqual $grantTypes[0] $server.GrantTypes[0]
        Assert-AreEqual $grantTypes[1] $server.GrantTypes[1]
        Assert-AreEqual $grantTypes[2] $server.GrantTypes[2]
        Assert-AreEqual $authorizationMethods.Count $server.AuthorizationRequestMethods.Count
        Assert-AreEqual $authorizationMethods[0] $server.AuthorizationRequestMethods[0]
        Assert-AreEqual $bearerTokenSendingMethods.Count $server.AccessTokenSendingMethods.Count
        Assert-AreEqual $bearerTokenSendingMethods[0] $server.AccessTokenSendingMethods[0]
        Assert-AreEqual $clientId $server.ClientId
        Assert-AreEqual $description $server.Description
        Assert-AreEqual $clientAuthenticationMethods.Count $server.ClientAuthenticationMethods.Count
        Assert-AreEqual $clientAuthenticationMethods[0] $server.ClientAuthenticationMethods[0]
        Assert-AreEqual $clientSecret $server.ClientSecret
        
        
        Assert-AreEqual $supportState $server.SupportState
        Assert-AreEqual $tokenBodyParameters.Count $server.TokenBodyParameters.Count

        $server = Get-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId

        Assert-AreEqual $serverId $server.ServerId
        Assert-AreEqual $name $server.Name
        Assert-AreEqual $defaultScope $server.DefaultScope
        Assert-AreEqual $authorizationEndpoint $server.AuthorizationEndpointUrl
        Assert-AreEqual $tokenEndpoint $server.TokenEndpointUrl
        Assert-AreEqual $clientRegistrationEndpoint $server.ClientRegistrationPageUrl
        Assert-AreEqual $grantTypes.Count $server.GrantTypes.Count
        Assert-AreEqual $grantTypes[0] $server.GrantTypes[0]
        Assert-AreEqual $grantTypes[1] $server.GrantTypes[1]
        Assert-AreEqual $grantTypes[2] $server.GrantTypes[2]
        Assert-AreEqual $authorizationMethods.Count $server.AuthorizationRequestMethods.Count
        Assert-AreEqual $authorizationMethods[0] $server.AuthorizationRequestMethods[0]
        Assert-AreEqual $authorizationMethods[1] $server.AuthorizationRequestMethods[1]
        Assert-AreEqual $bearerTokenSendingMethods.Count $server.AccessTokenSendingMethods.Count
        Assert-AreEqual $bearerTokenSendingMethods[0] $server.AccessTokenSendingMethods[0]
        Assert-AreEqual $bearerTokenSendingMethods[1] $server.AccessTokenSendingMethods[1]
        Assert-AreEqual $clientId $server.ClientId
        Assert-AreEqual $description $server.Description
        Assert-AreEqual $clientAuthenticationMethods.Count $server.ClientAuthenticationMethods.Count
        Assert-AreEqual $clientAuthenticationMethods[0] $server.ClientAuthenticationMethods[0]
        Assert-AreEqual $clientSecret $server.ClientSecret
        
        
        Assert-AreEqual $supportState $server.SupportState
        Assert-AreEqual $tokenBodyParameters.Count $server.TokenBodyParameters.Count
    }
    finally {
        
        $removed = Remove-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId  -PassThru
        Assert-True { $removed }

        $server = $null
        try {
            
            $server = Get-AzApiManagementAuthorizationServer -Context $context -ServerId $serverId
        }
        catch {
        }

        Assert-Null $server
    }
}


function Logger-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $loggerId = getAssetName
    $appInsightsLoggerId = getAssetName
    $instrumentationKey = [guid]::newguid()
    try {        
        $newLoggerDescription = getAssetName
        $eventHubName = "powershell"
        
        $eventHubConnectionString = "Test-ConnectionString"

        $logger = New-AzApiManagementLogger -Context $context -LoggerId $loggerId -Name $eventHubName -ConnectionString $eventHubConnectionString -Description $newLoggerDescription

        Assert-AreEqual $loggerId $logger.LoggerId
        Assert-AreEqual $newLoggerDescription $logger.Description
        Assert-AreEqual 'AzureEventHub' $logger.Type
        Assert-AreEqual $true $logger.IsBuffered

        
        $newLoggerDescription = getAssetName

        $logger = $null
        $logger = Set-AzApiManagementLogger -Context $context -LoggerId $loggerId -Description $newLoggerDescription -PassThru

        Assert-AreEqual $loggerId $logger.LoggerId
        Assert-AreEqual $newLoggerDescription $logger.Description
        Assert-AreEqual 'AzureEventHub' $logger.Type
        Assert-AreEqual $false $logger.IsBuffered

        
        $loggers = Get-AzApiManagementLogger -Context $context

        Assert-NotNull $loggers
        Assert-AreEqual 1 $loggers.Count

        
        $logger = $null
        $logger = Get-AzApiManagementLogger -Context $context -LoggerId $loggerId
        Assert-AreEqual $loggerId $logger.LoggerId
        Assert-AreEqual $newLoggerDescription $logger.Description
        Assert-AreEqual 'AzureEventHub' $logger.Type
        Assert-AreEqual $false $logger.IsBuffered

        
        $appInsightsLoggerDescription = getAssetName
        $applogger = New-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId -InstrumentationKey $instrumentationKey.Guid -Description $appInsightsLoggerDescription
        Assert-NotNull $applogger
        Assert-AreEqual 'ApplicationInsights' $applogger.Type
        Assert-AreEqual $appInsightsLoggerId $applogger.LoggerId
        Assert-AreEqual $appInsightsLoggerDescription $applogger.Description
    }
    finally {
        
        $removed = Remove-AzApiManagementLogger -Context $context -LoggerId $loggerId  -PassThru
        Assert-True { $removed }

        $logger = $null
        try {
            
            $logger = Get-AzApiManagementLogger -Context $context -LoggerId $loggerId
        }
        catch {
        }

        Assert-Null $logger

        
        $removed = Remove-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId  -PassThru
        Assert-True { $removed }
 
        $logger = $null
        try {
            
            $logger = Get-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId
        }
        catch {
        }
 
        Assert-Null $logger

        
        $properties = Get-AzApiManagementProperty -Context $context
        for ($i = 0; $i -lt $properties.Count; $i++) {

            Remove-AzApiManagementProperty -Context $context -PropertyId $properties[$i].PropertyId
        }
    }
}


function OpenIdConnectProvider-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $openIdConnectProviderId = getAssetName
    $yamlPath1 = Join-Path (Join-Path "$TestOutputRoot" "Resources") "uspto.yml"
    $path1 = "openapifromFile"
    $openApiId1 = getAssetName
    
    try {
        $openIdConnectProviderName = getAssetName
        $metadataEndpoint = "https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0/.well-known/openid-configuration"
        $clientId = getAssetName
        $openIdDescription = getAssetName

        $openIdConectProvider = New-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId -Name $openIdConnectProviderName -MetadataEndpointUri $metadataEndpoint -ClientId $clientId -Description $openIdDescription

        Assert-AreEqual $openIdConnectProviderId $openIdConectProvider.OpenIdConnectProviderId
        Assert-AreEqual $openIdConnectProviderName $openIdConectProvider.Name
        Assert-AreEqual $metadataEndpoint $openIdConectProvider.MetadataEndpoint
        Assert-AreEqual $clientId $openIdConectProvider.ClientId
        Assert-AreEqual $openIdDescription $openIdConectProvider.Description
        Assert-Null $openIdConectProvider.ClientSecret

        
        $openIdConectProvider = $null
        $openIdConectProvider = Get-AzApiManagementOpenIdConnectProvider -Context $context -Name $openIdConnectProviderName

        Assert-NotNull $openIdConectProvider
        Assert-AreEqual $openIdConnectProviderId $openIdConectProvider.OpenIdConnectProviderId

        
        $openIdConectProvider = Get-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId

        Assert-NotNull $openIdConectProvider
        Assert-AreEqual $openIdConnectProviderId $openIdConectProvider.OpenIdConnectProviderId

        
        $openIdConectProviders = Get-AzApiManagementOpenIdConnectProvider -Context $context
        Assert-AreEqual 1 $openIdConectProviders.Count

        Assert-NotNull $openIdConectProviders
        Assert-AreEqual $openIdConnectProviderId $openIdConectProvider.OpenIdConnectProviderId

        
        $api = Import-AzApiManagementApi -Context $context -ApiId $openApiId1 -SpecificationPath $yamlPath1 -SpecificationFormat OpenApi -Path $path1

        Assert-AreEqual $openApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path
        Assert-NotNull $api.ServiceUrl

        
        $api = Set-AzApiManagementApi -InputObject $api -Name $api.Name -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols -OpenIdProviderId $openIdConnectProviderId -BearerTokenSendingMethod 'query' -PassThru
        Assert-AreEqual $openApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path
        Assert-AreEqual $openIdConnectProviderId $api.OpenIdProviderId
        Assert-AreEqual 'query' $api.BearerTokenSendingMethod[0]

        
        $clientSecret = getAssetName
        $openIdConectProvider = Set-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId -ClientSecret $clientSecret -PassThru

        Assert-AreEqual $openIdConnectProviderId $openIdConectProvider.OpenIdConnectProviderId
        Assert-AreEqual $clientSecret $openIdConectProvider.ClientSecret
        Assert-AreEqual $clientId $openIdConectProvider.ClientId
        Assert-AreEqual $metadataEndpoint $openIdConectProvider.MetadataEndpoint
        Assert-AreEqual $openIdConnectProviderName $openIdConectProvider.Name

        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $openApiId1 -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId -PassThru
        Assert-True { $removed }

        $openIdConectProvider = $null
        try {
            
            $openIdConectProvider = Get-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId
        }
        catch {
        }

        Assert-Null $openIdConectProvider
    }
    finally {

        $removed = Remove-AzApiManagementApi -Context $context -ApiId $openApiId1 -PassThru
        Assert-True { $removed }

        $removed = Remove-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId -PassThru
        Assert-True { $removed }

        $openIdConectProvider = $null
        try {
            
            $openIdConectProvider = Get-AzApiManagementOpenIdConnectProvider -Context $context -OpenIdConnectProviderId $openIdConnectProviderId
        }
        catch {
        }

        Assert-Null $openIdConectProvider
    }
}


function Properties-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $propertyId = getAssetName
    $secretPropertyId = $null
    try {
        $propertyName = getAssetName
        $propertyValue = getAssetName
        $tags = 'sdk', 'powershell'
        $property = New-AzApiManagementProperty -Context $context -PropertyId $propertyId -Name $propertyName -Value $propertyValue -Tag $tags

        Assert-NotNull $property
        Assert-AreEqual $propertyId $property.PropertyId
        Assert-AreEqual $propertyName $property.Name
        Assert-AreEqual $propertyValue $property.Value
        Assert-AreEqual $false  $property.Secret
        Assert-AreEqual 2 $property.Tags.Count

        
        $secretPropertyId = getAssetName
        $secretPropertyName = getAssetName
        $secretPropertyValue = getAssetName
        $secretProperty = New-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId -Name $secretPropertyName -Value $secretPropertyValue -Secret

        Assert-NotNull $secretProperty
        Assert-AreEqual $secretPropertyId $secretProperty.PropertyId
        Assert-AreEqual $secretPropertyName $secretProperty.Name
        Assert-AreEqual $secretPropertyValue $secretProperty.Value
        Assert-AreEqual $true  $secretProperty.Secret
        Assert-NotNull $secretProperty.Tags
        Assert-AreEqual 0 $secretProperty.Tags.Count

        
        $properties = Get-AzApiManagementProperty -Context $context

        Assert-NotNull $properties
        
        Assert-AreEqual 2 $properties.Count

        
        $properties = $null
        $properties = Get-AzApiManagementProperty -Context $context -Name 'ps'
		
        Assert-NotNull $properties
        
        Assert-AreEqual 2 $properties.Count

        
        $properties = $null
        $properties = Get-AzApiManagementProperty -Context $context -Tag 'sdk'

        Assert-NotNull $property
        Assert-AreEqual 1 $properties.Count

        
        $secretProperty = $null
        $secretProperty = Get-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId

        Assert-NotNull $secretProperty
        Assert-AreEqual $secretPropertyId $secretProperty.PropertyId
        Assert-AreEqual $secretPropertyName $secretProperty.Name
        Assert-AreEqual $secretPropertyValue $secretProperty.Value
        Assert-AreEqual $true  $secretProperty.Secret
        Assert-NotNull $secretProperty.Tags
        Assert-AreEqual 0 $secretProperty.Tags.Count

        
        $secretProperty = $null
        $secretProperty = Set-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId -Tag $tags -PassThru

        Assert-NotNull $secretProperty
        Assert-AreEqual $secretPropertyId $secretProperty.PropertyId
        Assert-AreEqual $secretPropertyName $secretProperty.Name
        Assert-AreEqual $secretPropertyValue $secretProperty.Value
        Assert-AreEqual $true  $secretProperty.Secret
        Assert-NotNull $secretProperty.Tags
        Assert-AreEqual 2 $secretProperty.Tags.Count

        
        $property = $null
        $property = Set-AzApiManagementProperty -Context $context -PropertyId $propertyId -Secret $true -PassThru

        Assert-NotNull $property
        Assert-AreEqual $propertyId $property.PropertyId
        Assert-AreEqual $propertyName $property.Name
        Assert-AreEqual $propertyValue $property.Value
        Assert-AreEqual $true  $property.Secret
        Assert-NotNull $property.Tags
        Assert-AreEqual 2 $property.Tags.Count

        
        $removed = Remove-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId -PassThru
        Assert-True { $removed }

        $secretProperty = $null
        try {
            
            $secretProperty = Get-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId
        }
        catch {
        }

        Assert-Null $secretProperty
    }
    finally {
        $removed = Remove-AzApiManagementProperty -Context $context -PropertyId $propertyId -PassThru
        Assert-True { $removed }

        $property = $null
        try {
            
            $property = Get-AzApiManagementProperty -Context $context -PropertyId $propertyId
        }
        catch {
        }

        Assert-Null $property

        
        try {
            Remove-AzApiManagementProperty -Context $context -PropertyId $secretPropertyId -PassThru
        }
        catch {
        }
    }
}


function TenantGitConfiguration-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    try {
        $tenantGitAccess = Get-AzApiManagementTenantGitAccess -Context $context

        Assert-NotNull $tenantGitAccess
        Assert-AreEqual $true $tenantGitAccess.Enabled

        
        $tenantSyncState = Get-AzApiManagementTenantSyncState -Context $context
        Assert-NotNull $tenantSyncState
        Assert-AreEqual $true $tenantSyncState.IsGitEnabled

        
        $saveResponse = Save-AzApiManagementTenantGitConfiguration -Context $context -Branch 'master' -PassThru

        Assert-NotNull $saveResponse
        Assert-AreEqual "Succeeded" $saveResponse.State
        Assert-Null $saveResponse.Error

        
        $tenantSyncState = $null
        $tenantSyncState = Get-AzApiManagementTenantSyncState -Context $context
        Assert-NotNull $tenantSyncState
        Assert-AreEqual $true $tenantSyncState.IsGitEnabled
        Assert-AreEqual "master" $tenantSyncState.Branch

        
        $validateResponse = Publish-AzApiManagementTenantGitConfiguration -Context $context -Branch 'master' -ValidateOnly -PassThru

        Assert-NotNull $validateResponse
        Assert-AreEqual "Succeeded" $validateResponse.State
        Assert-Null $validateResponse.Error

        
        $deployResponse = Publish-AzApiManagementTenantGitConfiguration -Context $context -Branch 'master' -PassThru

        Assert-NotNull $deployResponse
        Assert-AreEqual "Succeeded" $deployResponse.State
        Assert-Null $deployResponse.Error

        
        $tenantSyncState = $null
        $tenantSyncState = Get-AzApiManagementTenantSyncState -Context $context
        Assert-NotNull $tenantSyncState
        Assert-AreEqual $true $tenantSyncState.IsGitEnabled
        Assert-AreEqual "master" $tenantSyncState.Branch
        Assert-AreEqual $true $tenantSyncState.IsSynced
    }
    finally {

    }
}


function TenantAccessConfiguration-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    try {
        $tenantAccess = Get-AzApiManagementTenantAccess -Context $context

        Assert-NotNull $tenantAccess
        Assert-AreEqual $false $tenantAccess.Enabled

        
        $tenantAccess = $null
        $tenantAccess = Set-AzApiManagementTenantAccess -Context $context -Enabled $true -PassThru

        Assert-NotNull $tenantAccess
        Assert-AreEqual $true $tenantAccess.Enabled
    }
    finally {
        Set-AzApiManagementTenantAccess -Context $context -Enabled $false -PassThru
    }
}


function IdentityProvider-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $identityProviderName = 'Facebook'
    try {
        $clientId = getAssetName
        $clientSecret = getAssetName

        $identityProvider = New-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -ClientId $clientId -ClientSecret $clientSecret

        Assert-NotNull $identityProvider
        Assert-AreEqual $identityProviderName $identityProvider.Type
        Assert-AreEqual $clientId $identityProvider.ClientId
        Assert-AreEqual $clientSecret $identityProvider.ClientSecret

        
        $identityProvider = $null
        $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName

        Assert-NotNull $identityProvider
        Assert-AreEqual $identityProviderName $identityProvider.Type

        
        $identityProviders = Get-AzApiManagementIdentityProvider -Context $context

        Assert-NotNull $identityProviders
        Assert-AreEqual 1 $identityProviders.Count

        
        $clientSecret = getAssetName
        $identityProvider = Set-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -ClientSecret $clientSecret -PassThru

        Assert-AreEqual $identityProviderName $identityProvider.Type
        Assert-AreEqual $clientSecret $identityProvider.ClientSecret
        Assert-AreEqual $clientId $identityProvider.ClientId

        
        $removed = Remove-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -PassThru
        Assert-True { $removed }

        $identityProvider = $null
        try {
            
            $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName
        }
        catch {
        }

        Assert-Null $identityProvider
    }
    finally {
        $removed = Remove-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -PassThru
        Assert-True { $removed }

        $identityProvider = $null
        try {
            
            $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName
        }
        catch {
        }

        Assert-Null $identityProvider
    }
}


function IdentityProvider-AadB2C-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $identityProviderName = 'AadB2C'
    try {
        $clientId = getAssetName
        $clientSecret = getAssetName
        $allowedTenants = 'samirtestbc.onmicrosoft.com'
        $signupPolicyName = 'B2C_1_signup-policy'
        $signinPolicyName = 'B2C_1_Sign-policy'

        $identityProvider = New-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -ClientId $clientId -ClientSecret $clientSecret `
            -AllowedTenants $allowedTenants -SignupPolicyName $signupPolicyName -SigninPolicyName $signinPolicyName

        Assert-NotNull $identityProvider
        Assert-AreEqual $identityProviderName $identityProvider.Type
        Assert-AreEqual $clientId $identityProvider.ClientId
        Assert-AreEqual $clientSecret $identityProvider.ClientSecret
        Assert-AreEqual $signinPolicyName $identityProvider.SigninPolicyName
        Assert-AreEqual $signupPolicyName $identityProvider.SignupPolicyName
        Assert-AreEqual 'login.microsoftonline.com' $identityProvider.Authority
        Assert-AreEqual $allowedTenants $identityProvider.AllowedTenants[0]

        
        $identityProvider = $null
        $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName

        Assert-NotNull $identityProvider
        Assert-AreEqual $identityProviderName $identityProvider.Type

        
        $identityProviders = Get-AzApiManagementIdentityProvider -Context $context

        Assert-NotNull $identityProviders
        Assert-AreEqual 1 $identityProviders.Count

        
        $profileEditingPolicy = 'B2C_1_UpdateEmail'
        $identityProvider = Set-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -ProfileEditingPolicyName $profileEditingPolicy -PassThru

        Assert-AreEqual $identityProviderName $identityProvider.Type
        Assert-AreEqual $clientSecret $identityProvider.ClientSecret
        Assert-AreEqual $clientId $identityProvider.ClientId
        Assert-AreEqual $clientSecret $identityProvider.ClientSecret
        Assert-AreEqual $signinPolicyName $identityProvider.SigninPolicyName
        Assert-AreEqual $signupPolicyName $identityProvider.SignupPolicyName
        Assert-AreEqual 'login.microsoftonline.com' $identityProvider.Authority
        Assert-AreEqual $allowedTenants $identityProvider.AllowedTenants[0]
        Assert-AreEqual $profileEditingPolicy $identityProvider.ProfileEditingPolicyName

        
        $removed = Remove-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -PassThru
        Assert-True { $removed }

        $identityProvider = $null
        try {
            
            $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName
        }
        catch {
        }

        Assert-Null $identityProvider
    }
    finally {
        $removed = Remove-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName -PassThru
        Assert-True { $removed }

        $identityProvider = $null
        try {
            
            $identityProvider = Get-AzApiManagementIdentityProvider -Context $context -Type $identityProviderName
        }
        catch {
        }

        Assert-Null $identityProvider
    }
}


function Backend-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $backendId = getAssetName
    try {
        $title = getAssetName
        $urlEndpoint = 'https://contoso.com/awesomeapi'
        $description = getAssetName
        $skipCertificateChainValidation = $true

        $credential = New-AzApiManagementBackendCredential -AuthorizationHeaderScheme basic -AuthorizationHeaderParameter opensesame -Query @{"sv" = @('xx', 'bb'); "sr" = @('cc') } -Header @{"x-my-1" = @('val1', 'val2') }
        $backend = New-AzApiManagementBackend -Context $context -BackendId $backendId -Url $urlEndpoint -Protocol http -Title $title -SkipCertificateChainValidation $skipCertificateChainValidation -Credential $credential -Description $description

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $description $backend.Description
        Assert-AreEqual $urlEndpoint $backend.Url
        Assert-AreEqual "http" $backend.Protocol
        Assert-NotNull $backend.Credentials
        Assert-NotNull $backend.Credentials.Authorization
        Assert-NotNull $backend.Credentials.Query
        Assert-NotNull $backend.Credentials.Header
        Assert-AreEqual 2 $backend.Credentials.Query.Count
        Assert-AreEqual 1 $backend.Credentials.Header.Count
        Assert-NotNull $backend.Properties
        Assert-AreEqual 1 $backend.Properties.Count

        
        $newBackendDescription = getAssetName

        $backend = $null
        $backend = Set-AzApiManagementBackend -Context $context -BackendId $backendId -Description $newBackendDescription -PassThru

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $newBackendDescription $backend.Description

        
        $backends = Get-AzApiManagementBackend -Context $context

        Assert-NotNull $backends
        Assert-AreEqual 1 $backends.Count

        
        $backend = $null
        $backend = Get-AzApiManagementBackend -Context $context -BackendId $backendId

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $newBackendDescription $backend.Description
        Assert-AreEqual $urlEndpoint $backend.Url
        Assert-AreEqual http $backend.Protocol
        Assert-NotNull $backend.Credentials
        Assert-NotNull $backend.Credentials.Authorization
        Assert-NotNull $backend.Credentials.Query
        Assert-NotNull $backend.Credentials.Header
        Assert-AreEqual 2 $backend.Credentials.Query.Count
        Assert-AreEqual 1 $backend.Credentials.Header.Count
        Assert-NotNull $backend.Properties
        Assert-AreEqual 1 $backend.Properties.Count

        
        $secpassword = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force; 
        $proxyCreds = New-Object System.Management.Automation.PSCredential ("foo", $secpassword)
        $credential = New-AzApiManagementBackendProxy -Url "http://12.168.1.1:8080" -ProxyCredential $proxyCreds

        $backend = Set-AzApiManagementBackend -Context $context -BackendId $backendId -Proxy $credential -PassThru
        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $newBackendDescription $backend.Description
        Assert-AreEqual $urlEndpoint $backend.Url
        Assert-AreEqual http $backend.Protocol
        Assert-NotNull $backend.Credentials
        Assert-NotNull $backend.Credentials.Authorization
        Assert-NotNull $backend.Credentials.Query
        Assert-NotNull $backend.Credentials.Header
        Assert-AreEqual 2 $backend.Credentials.Query.Count
        Assert-AreEqual 1 $backend.Credentials.Header.Count
        Assert-NotNull $backend.Properties
        Assert-AreEqual 1 $backend.Properties.Count
        Assert-NotNull $backend.Proxy
        Assert-AreEqual $backend.Proxy.Url "http://12.168.1.1:8080"
        Assert-NotNull $backend.Proxy.ProxyCredentials
    }
    finally {
        
        $removed = Remove-AzApiManagementBackend -Context $context -BackendId $backendId -PassThru
        Assert-True { $removed }

        $backend = $null
        try {
            
            $backend = Get-AzApiManagementBackend -Context $context -BackendId $backendId
        }
        catch {
        }

        Assert-Null $backend
    }
}


function BackendServiceFabric-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $backends = Get-AzApiManagementBackend -Context $context
    Assert-AreEqual 0 $backends.Count

    
    $certId = getAssetName    
    $certPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "powershelltest.pfx"
    
    $certPassword = 'Password'
    $certSubject = "CN=*.msitesting.net"
    $certThumbprint = '8E989652CABCF585ACBFCB9C2C91F1D174FDB3A2'

    
    $backendId = getAssetName
    
    try {
        
        $cert = New-AzApiManagementCertificate -Context $context -CertificateId $certId -PfxFilePath $certPath -PfxPassword $certPassword

        Assert-AreEqual $certId $cert.CertificateId
        Assert-AreEqual $certThumbprint $cert.Thumbprint
        Assert-AreEqual $certSubject $cert.Subject

        $title = getAssetName
        $urlEndpoint = 'https://contoso.com/awesomeapi'
        $description = getAssetName

        $ManagementEndpoints = 'https://sfbackend-01.net:443', 'https://sfbackend-02.net:443'
        $ServerCertificateThumbprints = $cert.Thumbprint
        $serviceFabric = New-AzApiManagementBackendServiceFabric -ManagementEndpoint  $ManagementEndpoints -ClientCertificateThumbprint $cert.Thumbprint `
            -ServerX509Name @{"CN=foobar.net" = $cert.Thumbprint }

        $backend = New-AzApiManagementBackend -Context $context -BackendId $backendId -Url $urlEndpoint -Protocol http -Title $title -ServiceFabricCluster $serviceFabric  `
            -Description $description

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $description $backend.Description
        Assert-AreEqual $urlEndpoint $backend.Url
        Assert-AreEqual "http" $backend.Protocol
        Assert-Null $backend.Credentials
        Assert-NotNull $backend.ServiceFabricCluster
        Assert-AreEqual 2 $backend.ServiceFabricCluster.ManagementEndpoints.Count
        Assert-AreEqual $cert.Thumbprint $backend.ServiceFabricCluster.ClientCertificateThumbprint
        Assert-Null $backend.ServiceFabricCluster.ServerCertificateThumbprint
        Assert-NotNull $backend.ServiceFabricCluster.ServerX509Names
        Assert-AreEqual 1 $backend.ServiceFabricCluster.ServerX509Names.Count
        
        Assert-AreEqual 3 $backend.ServiceFabricCluster.MaxPartitionResolutionRetries
        Assert-Null $backend.Properties

        
        $newBackendDescription = getAssetName

        $backend = $null
        $backend = Set-AzApiManagementBackend -Context $context -BackendId $backendId -Description $newBackendDescription -PassThru

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $newBackendDescription $backend.Description
       
        
        $backends = Get-AzApiManagementBackend -Context $context
		
        Assert-NotNull $backends
        Assert-AreEqual 1 $backends.Count
		
        
        $backend = $null
        $backend = Get-AzApiManagementBackend -Context $context -BackendId $backendId

        Assert-AreEqual $backendId $backend.BackendId
        Assert-AreEqual $newBackendDescription $backend.Description
        Assert-AreEqual $urlEndpoint $backend.Url
        Assert-AreEqual http $backend.Protocol
        Assert-Null $backend.Credentials
        Assert-NotNull $backend.ServiceFabricCluster
        Assert-AreEqual 2 $backend.ServiceFabricCluster.ManagementEndpoints.Count
        Assert-AreEqual $cert.Thumbprint $backend.ServiceFabricCluster.ClientCertificateThumbprint
        Assert-NotNull $backend.ServiceFabricCluster.ServerCertificateThumbprint
        Assert-NotNull $backend.ServiceFabricCluster.ServerX509Names
        Assert-AreEqual 1 $backend.ServiceFabricCluster.ServerX509Names.Count
        
        Assert-AreEqual 3 $backend.ServiceFabricCluster.MaxPartitionResolutionRetries 
        Assert-Null $backend.Properties       
    }
    finally {
        
        $removed = Remove-AzApiManagementBackend -Context $context -BackendId $backendId -PassThru
        Assert-True { $removed }

        $backend = $null
        try {
            
            $backend = Get-AzApiManagementBackend -Context $context -BackendId $backendId
        }
        catch {
        }

        Assert-Null $backend

        
        $removed = Remove-AzApiManagementCertificate -Context $context -CertificateId $certId -PassThru
        Assert-True { $removed }

        $certificate = $null
        try {
            
            $certificate = Get-AzApiManagementCertificate -Context $context -CertificateId $certId
        }
        catch {
        }

        Assert-Null $certificate
    }
}


function ApiVersionSet-SetCrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $apiversionsets = Get-AzApiManagementApiVersionSet -Context $context
    
    Assert-AreEqual 0 $apiversionsets.Count

    
    $swaggerPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "SwaggerPetStoreV2.json"
    $path1 = "swaggerapifromFile"
    $swaggerApiId1 = getAssetName        
    $newApiVersionSetId = getAssetName
    try {
        $newVersionSetName = getAssetName
        $queryName = getAssetName
        $description = getAssetName

        $newApiVersionSet = New-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -Name $newVersionSetName -Scheme Query `
            -QueryName $queryName -Description $description

        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Query $newApiVersionSet.VersioningScheme
        Assert-AreEqual $queryName $newApiVersionSet.VersionQueryName
        Assert-Null $newApiVersionSet.VersionHeaderName

        
        $versionHeaderName = getAssetName
        $newApiVersionSet = Set-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId  `
            -Scheme Header -HeaderName $versionHeaderName -PassThru

        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Header $newApiVersionSet.VersioningScheme
        Assert-AreEqual $versionHeaderName $newApiVersionSet.VersionHeaderName

        
        $newApiVersionSet = Get-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId
        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Header $newApiVersionSet.VersioningScheme
        Assert-AreEqual $versionHeaderName $newApiVersionSet.VersionHeaderName
        
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -SpecificationPath $swaggerPath -SpecificationFormat Swagger -Path $path1
        Assert-AreEqual $swaggerApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path

        
        $api.ApiVersionSetId = $newApiVersionSet.Id
        $api.APIVersion = "v1"
        $api.ApiVersionSetDescription = $newApiVersionSet.Description
        $updatedApi = Set-AzApiManagementApi -InputObject $api -PassThru
        Assert-NotNull $updatedApi
        Assert-AreEqual $newApiVersionSet.Id $updatedApi.ApiVersionSetId
        Assert-AreEqual $newApiVersionSet.Description $updatedApi.ApiVersionSetDescription
        Assert-AreEqual "v1" $updatedApi.ApiVersion
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -PassThru
        Assert-True { $removed }
    }
}


function ApiVersionSet-ImportCrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $apiversionsets = Get-AzApiManagementApiVersionSet -Context $context

    
    Assert-AreEqual 0 $apiversionsets.Count
    
    
    $swaggerApiId1 = getAssetName
    $newApiVersionSetId = getAssetName
    try {
        $newVersionSetName = getAssetName
        $queryName = getAssetName
        $description = getAssetName

        $newApiVersionSet = New-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -Name $newVersionSetName -Scheme Query `
            -QueryName $queryName -Description $description

        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Query $newApiVersionSet.VersioningScheme
        Assert-AreEqual $queryName $newApiVersionSet.VersionQueryName
        Assert-Null $newApiVersionSet.VersionHeaderName

        
        $versionHeaderName = getAssetName
        $newApiVersionSet = Set-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId  `
            -Scheme Header -HeaderName $versionHeaderName -PassThru

        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Header $newApiVersionSet.VersioningScheme
        Assert-AreEqual $versionHeaderName $newApiVersionSet.VersionHeaderName

        
        $newApiVersionSet = Get-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId
        Assert-AreEqual $newApiVersionSetId $newApiVersionSet.ApiVersionSetId
        Assert-AreEqual $newVersionSetName $newApiVersionSet.DisplayName
        Assert-AreEqual $description $newApiVersionSet.Description
        Assert-AreEqual Header $newApiVersionSet.VersioningScheme
        Assert-AreEqual $versionHeaderName $newApiVersionSet.VersionHeaderName

        
        $swaggerPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "SwaggerPetStoreV2.json"
        $path1 = "swaggerapifromFile"        
        $apiVersion = "2"

        $api = Import-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -SpecificationPath $swaggerPath -SpecificationFormat Swagger -Path $path1 -ApiVersion $apiVersion -ApiVersionSetId $newApiVersionSetId
        Assert-NotNull $api
        Assert-AreEqual $apiVersion $api.ApiVersion
        Assert-AreEqual $swaggerApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path
        Assert-AreEqual $newApiVersionSet.Id $api.ApiVersionSetId
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementApiVersionSet -Context $context -ApiVersionSetId $newApiVersionSetId -PassThru
        Assert-True { $removed }
    }
}


function ApiRevision-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName
   
    $swaggerPath = Join-Path (Join-Path "$TestOutputRoot" "Resources") "SwaggerPetStoreV2.json"
    $path1 = "swaggerapifromFile"
    $swaggerApiId1 = getAssetName
    $apiRevisionId = "2"
    $apiReleaseId = getAssetName
	$apiRevisionDescription = getAssetName

    try {
        
        $api = Import-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -SpecificationPath $swaggerPath -SpecificationFormat Swagger -Path $path1

        Assert-AreEqual $swaggerApiId1 $api.ApiId
        Assert-AreEqual $path1 $api.Path

        
        $product = Get-AzApiManagementProduct -Context $context | Select-Object -First 1
        Add-AzApiManagementApiToProduct -Context $context -ApiId $swaggerApiId1 -ProductId $product.ProductId

        
        $found = 0
        $apis = Get-AzApiManagementApi -Context $context -ProductId $product.ProductId
        for ($i = 0; $i -lt $apis.Count; $i++) {
            if ($apis[$i].ApiId -eq $swaggerApiId1) {
                $found = 1
            }
        }
        Assert-AreEqual 1 $found

        
        $originalOps = Get-AzApiManagementOperation -Context $context -ApiId $swaggerApiId1
        Assert-NotNull $originalOps

        
        $expectedApiId = [string]::Format("{0};rev={1}", $swaggerApiId1, $apiRevisionId) 
        $apiRevision = New-AzApiManagementApiRevision -Context $context -ApiId $swaggerApiId1 -ApiRevision $apiRevisionId -SourceApiRevision "1" -ApiRevisionDescription $apiRevisionDescription
        Assert-AreEqual $expectedApiId $apiRevision.ApiId
        Assert-AreEqual $apiRevisionId $apiRevision.ApiRevision
        Assert-NotNull $apiRevision.ApiRevisionDescription
        Assert-AreEqual $apiRevisionDescription $apiRevision.ApiRevisionDescription
        Assert-AreEqual $path1 $apiRevision.Path        
        Assert-False { $apiRevision.IsCurrent }

        $revisionOperations = Get-AzApiManagementOperation -Context $context -ApiId $swaggerApiId1 -ApiRevision $apiRevisionId
        Assert-NotNull $revisionOperations
        
        Assert-AreEqual $originalOps.Count $revisionOperations.Count 

        
        $apiRevisionDetails = Get-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -ApiRevision $apiRevisionId
        Assert-AreEqual $expectedApiId $apiRevisionDetails.ApiId
        Assert-AreEqual $path1 $apiRevisionDetails.Path
        Assert-AreEqual $apiRevisionId $apiRevisionDetails.ApiRevision
        Assert-False { $apiRevisionDetails.IsCurrent }

        
        $apiRevisions = Get-AzApiManagementApiRevision -Context $context -ApiId $swaggerApiId1
        Assert-AreEqual 2 $apiRevisions.Count

        
        $apiReleaseNote = getAssetName
        $apiRelease = New-AzApiManagementApiRelease -Context $context -ApiId $swaggerApiId1 -ApiRevision $apiRevisionId `
            -ReleaseId $apiReleaseId -Note $apiReleaseNote
        Assert-AreEqual $apiReleaseId $apiRelease.ReleaseId
        Assert-AreEqual $swaggerApiId1 $apiRelease.ApiId

        
        $updateReleaseNote = getAssetName        
        $updateApiRelease = Update-AzApiManagementApiRelease -InputObject $apiRelease -Note $updateReleaseNote -PassThru
        Assert-NotNull $updateApiRelease
        Assert-AreEqual $apiReleaseId $updateApiRelease.ReleaseId
        Assert-AreEqual $swaggerApiId1 $updateApiRelease.ApiId
        Assert-AreEqual $updateReleaseNote $updateApiRelease.Notes

        
        $apiReleases = Get-AzApiManagementApiRelease -Context $context -ApiId $swaggerApiId1
        Assert-AreEqual 1 $apiReleases.Count
        
        
        $result = Remove-AzApiManagementApiRevision -Context $context -ApiId $swaggerApiId1 -ApiRevision "1" -PassThru
        Assert-True { $result }        
    }
    finally {
        
        $removed = Remove-AzApiManagementApi -Context $context -ApiId $swaggerApiId1 -PassThru
        Assert-True { $removed }
    }
}


function Diagnostic-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $diagnostics = Get-AzApiManagementDiagnostic -Context $context

    
    Assert-AreEqual 0 $diagnostics.Count
    
    
    $appInsightsLoggerId = getAssetName
    $newDiagnosticId = 'ApplicationInsights'

    try {
        $instrumentationKey = [guid]::newguid()

        $appInsightsLoggerDescription = getAssetName
        $applogger = New-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId -InstrumentationKey $instrumentationKey.Guid -Description $appInsightsLoggerDescription
        Assert-NotNull $applogger
        Assert-AreEqual 'ApplicationInsights' $applogger.Type
        Assert-AreEqual $appInsightsLoggerId $applogger.LoggerId
        Assert-AreEqual $appInsightsLoggerDescription $applogger.Description

        
        $samplingSetting = New-AzApiManagementSamplingSetting -SamplingType Fixed -SamplingPercentage 100
        Assert-NotNull $samplingSetting
        
        
        $httpMessageDiagnostic = New-AzApiManagementHttpMessageDiagnostic -HeadersToLog 'Content-Type', 'UserAgent' -BodyBytesToLog 100
        Assert-NotNull $httpMessageDiagnostic

        
        $pipelineDiagnostic = New-AzApiManagementPipelineDiagnosticSetting -Request $httpMessageDiagnostic -Response $httpMessageDiagnostic
        Assert-NotNull $pipelineDiagnostic

        
        $diagnostic = New-AzApiManagementDiagnostic -LoggerId $applogger.LoggerId -Context $context -AlwaysLog AllErrors -SamplingSetting $samplingSetting `
            -FrontEndSetting $pipelineDiagnostic -BackendSetting $pipelineDiagnostic -DiagnosticId $newDiagnosticId
        Assert-NotNull $diagnostic

        Assert-NotNull $diagnostic
        Assert-AreEqual $newDiagnosticId $diagnostic.DiagnosticId
		Assert-AreEqual $applogger.LoggerId $diagnostic.LoggerId
        Assert-AreEqual allErrors $diagnostic.AlwaysLog
        Assert-NotNull $diagnostic.SamplingSetting
        Assert-AreEqual fixed $diagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 100 $diagnostic.SamplingSetting.SamplingPercentage
        Assert-NotNull $diagnostic.FrontendSetting
        Assert-AreEqual 'Content-Type' $diagnostic.FrontendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $diagnostic.FrontendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $diagnostic.FrontendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $diagnostic.FrontendSetting.Response.HeadersToLog[1]
        Assert-NotNull $diagnostic.BackendSetting
        Assert-AreEqual 'Content-Type' $diagnostic.BackendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $diagnostic.BackendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $diagnostic.BackendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $diagnostic.BackendSetting.Response.HeadersToLog[1]

        
        $diagnostic.BackendSetting = $null
        $diagnostic.SamplingSetting.SamplingPercentage = 50
        $updateDiagnostic = Set-AzApiManagementDiagnostic -InputObject $diagnostic -PassThru

        Assert-NotNull $updateDiagnostic        
        Assert-AreEqual $newDiagnosticId $updateDiagnostic.DiagnosticId
        Assert-Null $updateDiagnostic.BackendSetting
		Assert-AreEqual $applogger.LoggerId $updateDiagnostic.LoggerId
        Assert-AreEqual fixed $updateDiagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $updateDiagnostic.SamplingSetting.SamplingPercentage        
        Assert-NotNull $updateDiagnostic.FrontEndSetting
        Assert-AreEqual 'Content-Type' $updateDiagnostic.FrontendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $updateDiagnostic.FrontendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $updateDiagnostic.FrontendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $updateDiagnostic.FrontendSetting.Response.HeadersToLog[1]

        
        $diagnostic = Get-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId
        Assert-NotNull $diagnostic
        Assert-AreEqual $newDiagnosticId $diagnostic.DiagnosticId
		Assert-AreEqual $applogger.LoggerId $diagnostic.LoggerId
        Assert-AreEqual allErrors $diagnostic.AlwaysLog
        Assert-NotNull $diagnostic.SamplingSetting
        Assert-AreEqual fixed $diagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $diagnostic.SamplingSetting.SamplingPercentage
        Assert-NotNull $diagnostic.FrontendSetting
        Assert-Null $diagnostic.BackendSetting

		
		$diagnostic = Get-AzApiManagementDiagnostic -ResourceId $diagnostic.Id
        Assert-NotNull $diagnostic
        Assert-AreEqual $newDiagnosticId $diagnostic.DiagnosticId
		Assert-AreEqual $applogger.LoggerId $diagnostic.LoggerId
        Assert-AreEqual allErrors $diagnostic.AlwaysLog
        Assert-NotNull $diagnostic.SamplingSetting
        Assert-AreEqual fixed $diagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $diagnostic.SamplingSetting.SamplingPercentage
        Assert-NotNull $diagnostic.FrontendSetting
        Assert-Null $diagnostic.BackendSetting

		
        Remove-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId

        $diagnostics = Get-AzApiManagementDiagnostic -Context $context
        Assert-AreEqual 0 $diagnostics.Count
    }
    finally {
        
        $removed = Remove-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId -PassThru
        Assert-True { $removed }

        
        $properties = Get-AzApiManagementProperty -Context $context
        for ($i = 0; $i -lt $properties.Count; $i++) {

            Remove-AzApiManagementProperty -Context $context -PropertyId $properties[$i].PropertyId
        }
    }
}


function ApiDiagnostic-CrudTest {
    Param($resourceGroupName, $serviceName)

    $context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $serviceName

    
    $apis = Get-AzApiManagementApi -Context $context

    
    Assert-AreEqual 1 $apis.Count
    Assert-NotNull $apis[0].ApiId
    Assert-AreEqual "Echo API" $apis[0].Name
    Assert-Null $apis[0].Description

    
    $diagnostics = Get-AzApiManagementDiagnostic -Context $context -ApiId $apis[0].ApiId
    
    
    Assert-AreEqual 0 $diagnostics.Count
    
    
    $appInsightsLoggerId = getAssetName
    $newDiagnosticId = 'ApplicationInsights'

    try {
        $instrumentationKey = [guid]::newguid()

        $appInsightsLoggerDescription = getAssetName
        $applogger = New-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId -InstrumentationKey $instrumentationKey.Guid `
            -Description $appInsightsLoggerDescription
        Assert-NotNull $applogger
        Assert-AreEqual 'ApplicationInsights' $applogger.Type
        Assert-AreEqual $appInsightsLoggerId $applogger.LoggerId
        Assert-AreEqual $appInsightsLoggerDescription $applogger.Description

        
        $samplingSetting = New-AzApiManagementSamplingSetting -SamplingType Fixed -SamplingPercentage 100
        Assert-NotNull $samplingSetting
        
        
        $httpMessageDiagnostic = New-AzApiManagementHttpMessageDiagnostic -HeadersToLog 'Content-Type', 'UserAgent' -BodyBytesToLog 100
        Assert-NotNull $httpMessageDiagnostic

        
        $pipelineDiagnostic = New-AzApiManagementPipelineDiagnosticSetting -Request $httpMessageDiagnostic -Response $httpMessageDiagnostic
        Assert-NotNull $pipelineDiagnostic

        
        $apiDiagnostic = New-AzApiManagementDiagnostic -Context $context -ApiId $apis[0].ApiId -LoggerId $applogger.LoggerId -AlwaysLog AllErrors -SamplingSetting $samplingSetting `
            -FrontEndSetting $pipelineDiagnostic -BackendSetting $pipelineDiagnostic -DiagnosticId $newDiagnosticId
        Assert-NotNull $apiDiagnostic

        Assert-NotNull $apiDiagnostic
        Assert-AreEqual $apis[0].ApiId $apiDiagnostic.ApiId
		Assert-AreEqual $applogger.LoggerId $apiDiagnostic.LoggerId
        Assert-AreEqual $newDiagnosticId $apiDiagnostic.DiagnosticId
        Assert-AreEqual allErrors $apiDiagnostic.AlwaysLog
        Assert-NotNull $apiDiagnostic.SamplingSetting
        Assert-AreEqual fixed $apiDiagnostic.SamplingSetting.SamplingType
        Assert-NotNull $apiDiagnostic.FrontendSetting
        Assert-AreEqual 'Content-Type' $apiDiagnostic.FrontendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $apiDiagnostic.FrontendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $apiDiagnostic.FrontendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $apiDiagnostic.FrontendSetting.Response.HeadersToLog[1]
        Assert-NotNull $apiDiagnostic.BackendSetting
        Assert-AreEqual 'Content-Type' $apiDiagnostic.BackendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $apiDiagnostic.BackendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $apiDiagnostic.BackendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $apiDiagnostic.BackendSetting.Response.HeadersToLog[1]

        
        $apiDiagnostic.BackendSetting = $null
        $apiDiagnostic.SamplingSetting.SamplingPercentage = 50
        $updateDiagnostic = Set-AzApiManagementDiagnostic -InputObject $apiDiagnostic -PassThru

        Assert-NotNull $updateDiagnostic  
        Assert-AreEqual $apis[0].ApiId $updateDiagnostic.ApiId      
        Assert-AreEqual $newDiagnosticId $updateDiagnostic.DiagnosticId
		Assert-AreEqual $applogger.LoggerId $updateDiagnostic.LoggerId
        Assert-Null $updateDiagnostic.BackendSetting
        Assert-AreEqual fixed $updateDiagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $updateDiagnostic.SamplingSetting.SamplingPercentage        
        Assert-NotNull $updateDiagnostic.FrontendSetting
        Assert-AreEqual 'Content-Type' $updateDiagnostic.FrontendSetting.Request.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $updateDiagnostic.FrontendSetting.Request.HeadersToLog[1]
        Assert-AreEqual 'Content-Type' $updateDiagnostic.FrontendSetting.Response.HeadersToLog[0]
        Assert-AreEqual 'UserAgent' $updateDiagnostic.FrontendSetting.Response.HeadersToLog[1]

        
        $diagnostic = Get-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId -ApiId $apis[0].ApiId
        Assert-NotNull $diagnostic
        Assert-AreEqual $apis[0].ApiId $diagnostic.ApiId
		Assert-AreEqual $applogger.LoggerId $diagnostic.LoggerId
        Assert-AreEqual $newDiagnosticId $diagnostic.DiagnosticId
        Assert-AreEqual allErrors $diagnostic.AlwaysLog
        Assert-NotNull $diagnostic.SamplingSetting
        Assert-AreEqual fixed $diagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $diagnostic.SamplingSetting.SamplingPercentage
        Assert-NotNull $diagnostic.FrontendSetting
        Assert-Null $diagnostic.BackendSetting

		
		$diagnostic = Get-AzApiManagementDiagnostic -ResourceId $diagnostic.Id
        Assert-NotNull $diagnostic
        Assert-AreEqual $newDiagnosticId $diagnostic.DiagnosticId
        Assert-AreEqual allErrors $diagnostic.AlwaysLog
        Assert-NotNull $diagnostic.SamplingSetting
        Assert-AreEqual fixed $diagnostic.SamplingSetting.SamplingType
        Assert-AreEqual 50 $diagnostic.SamplingSetting.SamplingPercentage
        Assert-NotNull $diagnostic.FrontendSetting
        Assert-Null $diagnostic.BackendSetting

        Remove-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId -ApiId $apis[0].ApiId

        $diagnostics = Get-AzApiManagementDiagnostic -Context $context -ApiId $apis[0].ApiId
        Assert-AreEqual 0 $diagnostics.Count
    }
    finally {
        
        $removed = Remove-AzApiManagementDiagnostic -Context $context -DiagnosticId $newDiagnosticId -ApiId $apis[0].ApiId -PassThru
        Assert-True { $removed }

        
        $removed = Remove-AzApiManagementLogger -Context $context -LoggerId $appInsightsLoggerId -PassThru
        Assert-True { $removed }

        
        $properties = Get-AzApiManagementProperty -Context $context
        for ($i = 0; $i -lt $properties.Count; $i++) {

            Remove-AzApiManagementProperty -Context $context -PropertyId $properties[$i].PropertyId
        }
    }
}