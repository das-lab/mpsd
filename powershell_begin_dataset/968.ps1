



Connect-AzAccount


Set-AzContext -SubscriptionId "subscription ID"







$location = "westus2" 
$resourcegroup = "MyRG" 
New-AzResourceGroup -Name $resourcegroup -Location $location


$vaultname = "MyKeyVault" 
New-AzKeyVault -VaultName $vaultname -ResourceGroupName $resourcegroup -Location $location -EnableSoftDelete


$objectid = (Set-AzSqlInstance -ResourceGroupName $resourcegroup -Name "MyManagedInstance" -AssignIdentity).Identity.PrincipalId
Set-AzKeyVaultAccessPolicy -BypassObjectIdValidation -VaultName $vaultname -ObjectId $objectid -PermissionsToKeys get,wrapKey,unwrapKey


Update-AzKeyVaultNetworkRuleSet -VaultName $vaultname -Bypass AzureServices


Update-AzKeyVaultNetworkRuleSet -VaultName $vaultname -DefaultAction Deny





$keypath = "c:\some_path\mytdekey.pfx" 
$securepfxpwd = ConvertTo-SecureString -String "<PFX private key password>" -AsPlainText -Force 
$key = Add-AzKeyVaultKey -VaultName $vaultname -Name "MyTDEKey" -KeyFilePath $keypath -KeyFilePassword $securepfxpwd











Add-AzSqlInstanceKeyVaultKey -KeyId $key.id -InstanceName "MyManagedInstance" -ResourceGroupName $resourcegroup


Set-AzSqlInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -InstanceName "MyManagedInstance" -ResourceGroup $resourcegroup -KeyId $key.id