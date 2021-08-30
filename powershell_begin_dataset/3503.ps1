














function Test-GetApplicationInsightsApiKey
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$apiKeyName = "test";
		$permissions = @("ReadTelemetry", "WriteAnnotations", "AuthenticateSDKControlChannel");
		$apiKey = New-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -Description $apiKeyName -Permissions $permissions;

        $apiKey2 = Get-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -ApiKeyId $apiKey.Id;

        Assert-AreEqual $apiKeyName $apiKey2.Description
        Assert-NotNull $apiKey2.Id
		
        Assert-Null $apiKey2.ApiKey
		Assert-AreEqual 3 $apiKey2.Permissions.count

        $apiKeys = Get-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName;
        
		Assert-AreEqual 1 $apiKeys.count
		Assert-AreEqual $apiKeyName $apiKeys[0].Description
        Assert-NotNull $apiKeys[0].Id
		
        Assert-Null $apiKeys[0].ApiKey
		Assert-AreEqual 3 $apiKeys[0].Permissions.count

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewApplicationInsightsApiKey
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$apiKeyName = "test";
		$permissions = @("ReadTelemetry", "WriteAnnotations", "AuthenticateSDKControlChannel");
		$apiKey = New-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -Description $apiKeyName -Permissions $permissions;

        Assert-AreEqual $apiKeyName $apiKey.Description
        Assert-NotNull $apiKey.Id
        Assert-NotNull $apiKey.ApiKey
		Assert-AreEqual 3 $apiKey.Permissions.count

        $apiKey2 = Get-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -ApiKeyId $apiKey.Id;

        Assert-AreEqual $apiKeyName $apiKey2.Description
        Assert-NotNull $apiKey2.Id
		
        Assert-Null $apiKey2.ApiKey
		Assert-AreEqual 3 $apiKey2.Permissions.count

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-RemoveApplicationInsightsApiKey
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$apiKeyName = "test";
		$permissions = @("ReadTelemetry", "WriteAnnotations", "AuthenticateSDKControlChannel");
		$apiKey = New-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -Description $apiKeyName -Permissions $permissions;

        Assert-AreEqual $apiKeyName $apiKey.Description
        Assert-NotNull $apiKey.Id
        Assert-NotNull $apiKey.ApiKey
		Assert-AreEqual 3 $apiKey.Permissions.count

        $apiKey2 = Get-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -ApiKeyId $apiKey.Id;

        Assert-NotNull $apiKey2

        Remove-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -ApiKeyId $apiKey.Id;

		Assert-ThrowsContains { Get-AzApplicationInsightsApiKey -ResourceGroupName $rgname -Name $appName -ApiKeyId $apiKey.Id } "NotFound"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

