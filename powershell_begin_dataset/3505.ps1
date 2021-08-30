














function Test-GetApplicationInsightsContinuousExport
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$dummySubId = "50359d91-7b9d-4823-85af-eb298a61ba97";
		$dummyStorageAccount = "dummysa";
		$dummyContainer = "dummycontianer";

		$destinatinStorageAccountId = "/subscriptions/" + $dummySubId + "/resourceGroups/" + $rgname + "/providers/Microsoft.Storage/storageAccounts/"+ $dummyStorageAccount;
		$destinationStorageAccountSASToken = "https://"+ $dummyStorageAccount + ".blob.core.windows.net/"+$dummyContainer + "?sv=2015-04-05&sr=c&sig=xxxxxxxxx";
		
		$documentTypes = @("Request", "Custom Event");
		$continuousExport = New-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -DocumentType $documentTypes -StorageAccountId $destinatinStorageAccountId -StorageLocation $loc -StorageSASUri $destinationStorageAccountSASToken;

        $continuousExport2 = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId;
        
        Assert-NotNull $continuousExport2        
		Assert-AreEqual "Request, Custom Event" $continuousExport2.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport2.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport2.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport2.ContainerName

        $continuousExports = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName;
        
		Assert-AreEqual 1 $continuousExports.count
		Assert-AreEqual "Request, Custom Event" $continuousExports[0].DocumentTypes
		Assert-AreEqual $dummySubId $continuousExports[0].DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExports[0].DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExports[0].ContainerName

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewApplicationInsightsContinuousExport
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$dummySubId = "50359d91-7b9d-4823-85af-eb298a61ba97";
		$dummyStorageAccount = "dummysa";
		$dummyContainer = "dummycontianer";

		$destinatinStorageAccountId = "/subscriptions/" + $dummySubId + "/resourceGroups/" + $rgname + "/providers/Microsoft.Storage/storageAccounts/"+ $dummyStorageAccount;
		$destinationStorageAccountSASToken = "https://"+ $dummyStorageAccount + ".blob.core.windows.net/"+$dummyContainer + "?sv=2015-04-05&sr=c&sig=xxxxxxxxx";
		
		$documentTypes = @("Request", "Custom Event");
		$continuousExport = New-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -DocumentType $documentTypes -StorageAccountId $destinatinStorageAccountId -StorageLocation $loc -StorageSASUri $destinationStorageAccountSASToken;

        Assert-NotNull $continuousExport       
		Assert-AreEqual "Request, Custom Event" $continuousExport.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport.ContainerName

        $continuousExport2 = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId;
        
        Assert-NotNull $continuousExport2        
		Assert-AreEqual "Request, Custom Event" $continuousExport2.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport2.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport2.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport2.ContainerName

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-RemoveApplicationInsightsContinuousExport
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$dummySubId = "50359d91-7b9d-4823-85af-eb298a61ba97";
		$dummyStorageAccount = "dummysa";
		$dummyContainer = "dummycontianer";

		$destinatinStorageAccountId = "/subscriptions/" + $dummySubId + "/resourceGroups/" + $rgname + "/providers/Microsoft.Storage/storageAccounts/"+ $dummyStorageAccount;
		$destinationStorageAccountSASToken = "https://"+ $dummyStorageAccount + ".blob.core.windows.net/"+$dummyContainer + "?sv=2015-04-05&sr=c&sig=xxxxxxxxx";
		
		$documentTypes = @("Request", "Custom Event");
		$continuousExport = New-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -DocumentType $documentTypes -StorageAccountId $destinatinStorageAccountId -StorageLocation $loc -StorageSASUri $destinationStorageAccountSASToken;

        $continuousExport2 = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId;
        
        Assert-NotNull $continuousExport2        
		Assert-AreEqual "Request, Custom Event" $continuousExport2.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport2.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport2.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport2.ContainerName

        Remove-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId;

		$continuousExports = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName;
		Assert-AreEqual 0 $continuousExports.count;

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SetApplicationInsightsContinuousExport
{
    
    $rgname = Get-ApplicationInsightsTestResourceName;

    try
    {
        
		$appName = "app" + $rgname;
        $loc = Get-ProviderLocation ResourceManagement;
		$kind = "web";
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzApplicationInsights -ResourceGroupName $rgname -Name $appName -Location $loc -Kind $kind;
		
		$dummySubId = "50359d91-7b9d-4823-85af-eb298a61ba97";
		$dummyStorageAccount = "dummysa";
		$dummyContainer = "dummycontianer";

		$destinatinStorageAccountId = "/subscriptions/" + $dummySubId + "/resourceGroups/" + $rgname + "/providers/Microsoft.Storage/storageAccounts/"+ $dummyStorageAccount;
		$destinationStorageAccountSASToken = "https://"+ $dummyStorageAccount + ".blob.core.windows.net/"+$dummyContainer + "?sv=2015-04-05&sr=c&sig=xxxxxxxxx";
		
		$documentTypes = @("Request", "Custom Event");
		$continuousExport = New-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -DocumentType $documentTypes -StorageAccountId $destinatinStorageAccountId -StorageLocation $loc -StorageSASUri $destinationStorageAccountSASToken;

        $continuousExport2 = Get-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId;
        
        Assert-NotNull $continuousExport2        
		Assert-AreEqual "Request, Custom Event" $continuousExport2.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport2.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport2.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport2.ContainerName

		$documentTypes = @("Request", "Custom Event", "Exception");
		$continuousExport3 = Set-AzApplicationInsightsContinuousExport -ResourceGroupName $rgname -Name $appName -ExportId $continuousExport.ExportId -DocumentType $documentTypes -StorageAccountId $destinatinStorageAccountId -StorageLocation $loc -StorageSASUri $destinationStorageAccountSASToken;
        Assert-NotNull $continuousExport3        
		Assert-AreEqual "Request, Custom Event, Exception" $continuousExport3.DocumentTypes
		Assert-AreEqual $dummySubId $continuousExport3.DestinationStorageSubscriptionId
		Assert-AreEqual $loc $continuousExport3.DestinationStorageLocationId
		Assert-AreEqual $dummyContainer $continuousExport3.ContainerName

        Remove-AzApplicationInsights -ResourceGroupName $rgname -Name $appName;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


