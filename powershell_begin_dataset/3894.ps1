














function Test-AccountActiveDirectory
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $accName3 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    
    $activeDirectory1 = @{
        Username = "sdkuser"
		
        Password = "sdkpass"
        Domain = "sdkdomain"
        Dns = "127.0.0.1"
        SmbServerName = "PSSMBSName"
    }
    $activeDirectory2 = @{
        Username = "sdkuser1"
		
        Password = "sdkpass1"
        Domain = "sdkdomain"
        Dns = "127.0.0.1"
        SmbServerName = "PSSMBSName"
    }

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        
        try
        {
            $activedirectories = @( $activeDirectory1, $activeDirectory2 )

            
            $newTagName = "tag1"
            $newTagValue = "tagValue1"
            $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue} -ActiveDirector $activeDirectories
            Assert-True { $false }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Assert-True { ($ErrorMessage -contains 'Only one active directory allowed') }
            
        }

        

        $activedirectories = @( $activeDirectory1 )

        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue} -ActiveDirectory $activeDirectories
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual $activeDirectory1.SmbServerName $retrievedAcc.ActiveDirectories[0].SmbServerName
        Assert-AreEqual $activeDirectory1.Username $retrievedAcc.ActiveDirectories[0].Username

        
        
        $newTagName = "tag1"
        $newTagValue = "tagValue2"
        $retrievedAcc = Update-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName1 -Tag @{$newTagName = $newTagValue}
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual $activeDirectory1.SmbServerName $retrievedAcc.ActiveDirectories[0].SmbServerName
        Assert-AreEqual $activeDirectory1.Username $retrievedAcc.ActiveDirectories[0].Username
        Assert-AreEqual 1 $retrievedAcc.ActiveDirectories.Length
        Assert-AreEqual "tagValue2" $retrievedAcc.Tags[$newTagName].ToString()

        
        $retrievedAcc = Set-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName1 -Location $resourceLocation
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-Null $retrievedAcc.Tags
        Assert-Null $retrievedAcc.ActiveDirectories

        
        $activedirectories = @( $activeDirectory2 )
        $retrievedAcc = Update-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName1 -ActiveDirectory $activedirectories
        Assert-AreEqual $accName1 $retrievedAcc.Name
        
        
        
        Assert-AreEqual $activeDirectory2.Username $retrievedAcc.ActiveDirectories[0].Username
        Assert-AreEqual 1 $retrievedAcc.ActiveDirectories.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}
    

function Test-AccountCrud
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $accName3 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    
    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue}
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual True $retrievedAcc.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedAcc.Tags[$newTagName].ToString()

        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName2 -Confirm:$false
        Assert-AreEqual $accName2 $retrievedAcc.Name
		
        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName3 -WhatIf

        
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        
        Assert-True {"$accName1" -eq $retrievedAcc[0].Name -or "$accName2" -eq $retrievedAcc[0].Name}
        Assert-True {"$accName1" -eq $retrievedAcc[1].Name -or "$accName2" -eq $retrievedAcc[1].Name}
        Assert-AreEqual 2 $retrievedAcc.Length

        
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Name $accName1
        Assert-AreEqual $accName1 $retrievedAcc.Name

        
        $retrievedAccById = Get-AzNetAppFilesAccount -ResourceId $retrievedAcc.Id
        Assert-AreEqual $accName1 $retrievedAccById.Name

        

        
        Remove-AzNetAppFilesAccount -ResourceId $retrievedAccById.Id

        
        Remove-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName2 -WhatIf
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        Assert-AreEqual 1 $retrievedAcc.Length

        Remove-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName2
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        Assert-AreEqual 0 $retrievedAcc.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}


function Test-AccountPipelines
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 | Remove-AnfAccount

        New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName2

        Get-AnfAccount -ResourceGroupName $resourceGroup -Name $accName2 | Remove-AnfAccount
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}
