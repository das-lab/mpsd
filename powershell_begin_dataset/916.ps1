

$keyVaultName = "myKeyVault00"

$rgName = "myResourceGroup"

$location = "East US"

$password = $([guid]::NewGuid()).Guid)
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

$appName = "My App"

$vmName = "myEncryptedVM"

$vmAdminName = "encryptedUser"


New-AzResourceGroup -Location $location -Name $rgName


New-AzKeyVault `
    -Location $location `
    -ResourceGroupName $rgName `
    -VaultName $keyVaultName `
    -EnabledForDiskEncryption


Add-AzKeyVaultKey `
    -VaultName $keyVaultName `
    -Name "myKey" `
    -Destination "Software"



Set-AzKeyVaultSecret -VaultName $keyVaultName -Name adminCreds -SecretValue $securePassword
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name protectValue -SecretValue $securePassword



$app = New-AzADApplication -DisplayName $appName `
    -HomePage "https://myapp0.contoso.com" `
    -IdentifierUris "https://contoso.com/myapp0" `
    -Password (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValue

New-AzADServicePrincipal -ApplicationId $app.ApplicationId


Set-AzKeyVaultAccessPolicy -VaultName $keyvaultName `
    -ServicePrincipalName $app.ApplicationId  `
    -PermissionsToKeys decrypt,encrypt,unwrapKey,wrapKey,verify,sign,get,list,update `
    -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge


$cred = New-Object System.Management.Automation.PSCredential($vmAdminName, (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValue)


New-AzVM `
  -ResourceGroupName $rgName `
  -Name $vmName `
  -Location $location `
  -ImageName "Win2016Datacenter" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -SecurityGroupName "myNetworkSecurityGroup" `
  -PublicIpAddressName "myPublicIp" `
  -Credential $cred `
  -OpenPorts 3389


$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $rgName;
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $keyVaultName -Name "myKey").Key.kid;


Set-AzVMDiskEncryptionExtension `
    -ResourceGroupName $rgName `
    -VMName $vmName `
    -AadClientID $app.ApplicationId `
    -AadClientSecret (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValueText `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId


Get-AzVmDiskEncryptionStatus  -ResourceGroupName $rgName -VMName $vmName


