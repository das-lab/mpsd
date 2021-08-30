














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-TestStorageAccountName
{
    return getAssetName
}


function Get-CommitmentPlanName
{
    return getAssetName
}


function Get-WebServiceName
{
    return getAssetName
}


function Get-ProviderLocation($providerNamespace, $resourceType)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $provider = Get-AzResourceProvider -ProviderNamespace $providerNamespace
        $resourceType = $provider.ResourceTypes | `
                        where {$_.ResourceTypeName -eq $resourceType}
          if ($resourceType -eq $null) 
        {  
            return "southcentralus"  
        } else 
        {  
            return $resourceType.Locations[0].Replace(" ", "").ToLowerInvariant()
        } 
    }

    return "southcentralus"
}


function Get-ProviderAPIVersion($providerNamespace, $resourceType)
{ 
    if ($providerNamespace -eq "Microsoft.MachineLearning")
    {
        if ([System.String]::Equals($resourceType, "commitmentPlans", `
            [System.StringComparison]::OrdinalIgnoreCase))
        {
            return "2016-05-01-preview"
        }

        if ([System.String]::Equals($resourceType, "webServices", `
            [System.StringComparison]::OrdinalIgnoreCase))
        {
            return "2017-01-01"
        }
    }

    return $null
}


function Create-TestStorageAccount($resourceGroup, $location, $storageName)
{
    New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageName `
                                -Location $location -Type 'Standard_LRS' | Out-Null
    $accessKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup `
                                -Name $storageName).Key1;
    return @{ Name = $storageName; Key = $accessKey }
}


function Clean-CommitmentPlan($resourceGroup, $commitmentPlanName)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) 
    {
        try {
            LogOutput "Removing commitment plan $commitmentPlanName from resource group $rgName"    
            Remove-AzMlCommitmentPlan -ResourceGroupName $resourceGroup `
                                        -Name $commitmentPlanName -Force
            LogOutput "Commitment plan $commitmentPlanName was removed."
        }
        catch {
            Write-Warning "Caught unexpected exception when cleaning up commitment `
                            plan $commitmentPlanName in group $resourceGroup : `
                            $($($_.Exception).Message)"
        }
    }
}


function Clean-WebService($resourceGroup, $webServiceName)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) 
    {
        try {
            LogOutput "Removing web service $webServiceName from resource group $rgName"    
            Remove-AzMlWebService -ResourceGroupName $resourceGroup `
                                        -Name $webServiceName -Force
            LogOutput "Web service $webServiceName was removed."
        }
        catch {
            Write-Warning "Caught unexpected exception when cleaning up web `
                            service $webServiceName in group $resourceGroup : `
                            $($($_.Exception).Message)"
        }
    }
}


function Clean-TestStorageAccount($resourceGroup, $accountName)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) 
    {
        try {
            LogOutput "Removing storage account $accountName from resource group $rgName"             
            Remove-AzStorageAccount -ResourceGroupName $resourceGroup -Name $webServiceName
            LogOutput "Storage account $accountName was removed."
        }
        catch {
            Write-Warning "Caught unexpected exception when cleaning up `
                            storage account $accountName in group $resourceGroup : `
                            $($($_.Exception).Message)"
        }
    }
}


function Clean-ResourceGroup($resourceGroup)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        try {
            LogOutput "Removing resource group $resourceGroup" 
            Remove-AzResourceGroup -Name $resourceGroup -Force
            LogOutput "Resource group $resourceGroup was removed." 
        }
        catch {
            Write-Warning "Caught unexpected exception when cleaning up resource `
                            group $resourceGroup : $($($_.Exception).Message)"
        }
    }
}


function LogOutput($message)
{
    $timestamp = Get-Date -UFormat "%Y-%m-%d %H:%M:%S %Z"
    Write-Debug "[$timestamp]: $message"
}
