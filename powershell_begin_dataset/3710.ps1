














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