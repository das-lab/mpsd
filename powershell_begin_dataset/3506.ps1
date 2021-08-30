














function Test-GetApplicationInsightsPricingPlan
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
        $pricingPlan = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludePricingPlan;

		Assert-NotNull $pricingPlan
        Assert-AreEqual "Basic" $pricingPlan.PricingPlan
        
        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-SetApplicationInsightsPricingPlan
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
        $pricingPlan = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludePricingPlan;

		Assert-NotNull $pricingPlan
        Assert-AreEqual "Basic" $pricingPlan.PricingPlan
        
		$planName = "Application Insights Enterprise";
		$dailyCapGB = 300;		
		$stopSendEmail = $True;
        Set-AzApplicationInsightsPricingPlan -ResourceGroupName $rgname -Name $appName -PricingPlan $planName -DailyCapGB $dailyCapGB -DisableNotificationWhenHitCap;

		$pricingPlan2 = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludePricingPlan;
		Assert-NotNull $pricingPlan2
        Assert-AreEqual $planName $pricingPlan2.PricingPlan
		Assert-AreEqual $dailyCapGB $pricingPlan2.Cap
		Assert-AreEqual $stopSendEmail $pricingPlan2.StopSendNotificationWhenHitCap

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetApplicationInsightsDailyCap
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
        $dailyCap = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludePricingPlan;

		Assert-NotNull $dailyCap
        Assert-AreEqual 100 $dailyCap.Cap
		Assert-AreEqual $False $dailyCap.StopSendNotificationWhenHitCap
        
        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-SetApplicationInsightsDailyCap
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$dailyCapGB = 300;
		$stopSendEmail = $True;
        Set-AzApplicationInsightsDailyCap -ResourceGroupName $rgname -Name $appName -DailyCapGB $dailyCapGB -DisableNotificationWhenHitCap;

		$dailyCapInfo = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludePricingPlan;
		Assert-NotNull $dailyCapInfo        
		Assert-AreEqual $dailyCapGB $dailyCapInfo.Cap
		Assert-AreEqual $stopSendEmail $dailyCapInfo.StopSendNotificationWhenHitCap

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetApplicationInsightsDailyCapStatus
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
        $dailyCapStatus = Get-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -IncludeDailyCapStatus;

		Assert-NotNull $dailyCapStatus
		Assert-AreEqual $False $dailyCapStatus.IsCapped
        
        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}