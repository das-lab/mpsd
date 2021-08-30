














function Test-GetApplicationInsights
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;

        $app = New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind

        Assert-AreEqual $app.Name $appName
        Assert-AreEqual $app.Kind $kind
        Assert-NotNull $app.InstrumentationKey

        $apps = Get-AzApplicationInsights -ResourceGroupName $rgname;

		Assert-AreEqual $apps.count 1
        Assert-AreEqual $apps[0].Name $appName
        Assert-AreEqual $apps[0].Kind $kind
        Assert-NotNull $apps[0].InstrumentationKey

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewApplicationInsights
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;

        $app = New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind

        Assert-AreEqual $app.Name $appName
        Assert-AreEqual $app.Kind $kind
        Assert-NotNull $app.InstrumentationKey

        $app = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
		
        Assert-AreEqual $app.Name $appName
        Assert-AreEqual $app.Kind $kind
        Assert-NotNull $app.InstrumentationKey

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RemoveApplicationInsights
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind

        $app = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
		
		Assert-NotNull $app
        Assert-AreEqual $app.Name $appName
        Assert-AreEqual $app.Kind $kind
        Assert-NotNull $app.InstrumentationKey

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;

		Assert-ThrowsContains { Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName } "not found"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

