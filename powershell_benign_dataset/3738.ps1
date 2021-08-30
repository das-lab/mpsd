














function Test-NewAzureRmMapsAccount
{
    
    $rgname = Get-MapsManagementTestResourceName;
    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;

        $createdAccount = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        Assert-NotNull $createdAccount;
        
        $createdAccountAgain = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        Assert-NotNull $createdAccountAgain
        Assert-AreEqual $createdAccount.Id $createdAccountAgain.Id;
        Assert-AreEqual $createdAccount.ResourceGroupName $createdAccountAgain.ResourceGroupName;
        Assert-AreEqual $createdAccount.Name $createdAccountAgain.Name;
        Assert-AreEqual $createdAccount.Location $createdAccountAgain.Location;
        Assert-AreEqual $createdAccount.Sku.Name $createdAccountAgain.Sku.Name;
        
        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmMapsAccountS1
{
    
    $rgname = Get-MapsManagementTestResourceName;
    try
    {
        
        $accountname = 'ps-s1-' + $rgname;
        $skuname = 'S1';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;

        $createdAccount = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        Assert-NotNull $createdAccount;
        
        $createdAccountAgain = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        Assert-NotNull $createdAccountAgain
        Assert-AreEqual $createdAccount.Id $createdAccountAgain.Id;
        Assert-AreEqual $createdAccount.ResourceGroupName $createdAccountAgain.ResourceGroupName;
        Assert-AreEqual $createdAccount.Name $createdAccountAgain.Name;
        Assert-AreEqual $createdAccount.Location $createdAccountAgain.Location;
        Assert-AreEqual $createdAccount.Sku.Name $createdAccountAgain.Sku.Name;
        
        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RemoveAzureRmMapsAccount
{
    
    $rgname = Get-MapsManagementTestResourceName;

    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;

        $createdAccount = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false;
        $accountGotten = Get-AzMapsAccount -ResourceGroupName $rgname -Name $accountname;
        Assert-Null $accountGotten

        
        $createdAccount2 = New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;

        $resource = Get-AzResource -ResourceGroupName $rgname -ResourceName $accountname;
        $resourceid = $resource.ResourceId;

        Remove-AzMapsAccount -ResourceId $resourceid -Confirm:$false;
        $accountGotten2 = Get-AzMapsAccount -ResourceGroupName $rgname -Name $accountname;
        Assert-Null $accountGotten2

        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureMapsAccount
{
    
    $rgname = Get-MapsManagementTestResourceName;

    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;

        New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;

        $account = Get-AzMapsAccount -ResourceGroupName $rgname -Name $accountname;
        
        Assert-AreEqual $accountname $account.AccountName;
        Assert-AreEqual $skuname $account.Sku.Name;

        
        $resource = Get-AzResource -ResourceGroupName $rgname -ResourceName $accountname;
        $resourceid = $resource.ResourceId;

        $account2 = Get-AzMapsAccount -ResourceId $resourceid;
        Assert-AreEqual $accountname $account2.AccountName;
        Assert-AreEqual $skuname $account2.Sku.Name;

        
        $accounts = Get-AzMapsAccount -ResourceGroupName $rgname;
        $numberOfAccountsInRG = ($accounts | measure).Count;
        Assert-AreEqual $accountname $accounts[0].AccountName;
        Assert-AreEqual $skuname $accounts[0].Sku.Name;

        
        $allAccountsInSubscription = Get-AzMapsAccount;
        $numberOfAccountsInSubscription = ($allAccountsInSubscription | measure).Count;

        Assert-True { $numberOfAccountsInSubscription -ge $numberOfAccountsInRG }
        
        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureRmMapsAccountKey
{
    
    $rgname = Get-MapsManagementTestResourceName;

    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;
        New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        
        $keys = Get-AzMapsAccountKey -ResourceGroupName $rgname -Name $accountname;
        
        Assert-NotNull $keys.PrimaryKey;
        Assert-NotNull $keys.SecondaryKey;
        Assert-AreNotEqual $keys.PrimaryKey $keys.SecondaryKey;

        
        $resource = Get-AzResource -ResourceGroupName $rgname -ResourceName $accountname;
        $resourceid = $resource.ResourceId;

        $keys2 = Get-AzMapsAccountKey -ResourceId $resourceid;
        Assert-AreEqual $keys.PrimaryKey $keys2.PrimaryKey;
        Assert-AreEqual $keys.SecondaryKey $keys2.SecondaryKey;

        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmMapsAccountKey
{
    
    $rgname = Get-MapsManagementTestResourceName;
    
    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;
        New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;
        
        $originalKeys = Get-AzMapsAccountKey -ResourceGroupName $rgname -Name $accountname;

        
        $updatedKeys = New-AzMapsAccountKey -ResourceGroupName $rgname -Name $accountname -KeyName Primary -Confirm:$false;
            
        Assert-AreNotEqual $originalKeys.PrimaryKey $updatedKeys.PrimaryKey;
        Assert-AreEqual $originalKeys.SecondaryKey $updatedKeys.SecondaryKey;

        
        $updatedKeys2 = New-AzMapsAccountKey -ResourceGroupName $rgname -Name $accountname -KeyName Secondary -Confirm:$false;

        Assert-AreEqual $updatedKeys.PrimaryKey $updatedKeys2.PrimaryKey;
        Assert-AreNotEqual $updatedKeys.SecondaryKey $updatedKeys2.SecondaryKey;

        
        $resource = Get-AzResource -ResourceGroupName $rgname -ResourceName $accountname;
        $resourceid = $resource.ResourceId;

        $updatedKeys3 = New-AzMapsAccountKey -ResourceId $resourceid -KeyName Primary -Confirm:$false;
            
        Assert-AreNotEqual $updatedKeys2.PrimaryKey $updatedKeys3.PrimaryKey;
        Assert-AreEqual $updatedKeys2.SecondaryKey $updatedKeys3.SecondaryKey;


        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-PipingGetAccountToGetKey
{
    
    $rgname = Get-MapsManagementTestResourceName;

    try
    {
        
        $accountname = 'ps-' + $rgname;
        $skuname = 'S0';
        $location = 'West US';

        New-AzResourceGroup -Name $rgname -Location $location;
        New-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -SkuName $skuname -Force;

        $keys = Get-AzMapsAccount -ResourceGroupName $rgname -Name $accountname | Get-AzMapsAccountKey;
        Assert-NotNull $keys
        Assert-NotNull $keys.PrimaryKey
        Assert-NotNull $keys.SecondaryKey
        Assert-AreNotEqual $keys.PrimaryKey $keys.SecondaryKey;

        Retry-IfException { Remove-AzMapsAccount -ResourceGroupName $rgname -Name $accountname -Confirm:$false; }
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

