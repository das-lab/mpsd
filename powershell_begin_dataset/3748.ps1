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
