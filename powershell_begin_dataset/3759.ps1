














function Test-CreateIntegrationAccountCertificate
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$certFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "IntegrationAccountCertificate.cer"

	$integrationAccountCertificate = New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" -PublicCertificateFilePath $certFilePath
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificate.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-CreateIntegrationAccountCertificatePrivateKey
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountCertificate = New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1"
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificate.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-CreateIntegrationAccountCertificatePublicKey
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$certFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "IntegrationAccountCertificate.cer"

	$integrationAccountCertificate = New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1"
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificate.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-UpdateIntegrationAccountCertificate
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$certFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "IntegrationAccountCertificate.cer"

	$integrationAccountCertificate = New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" -PublicCertificateFilePath $certFilePath
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificate.Name

	$integrationAccountCertificateUpdated = Set-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -Force
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificateUpdated.Name
	Assert-AreEqual "PRIVATEKEY" $integrationAccountCertificateUpdated.Key.KeyName

	$integrationAccountCertificateUpdated = Set-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyVersion "273ab4059bd84b81bbb8308df706379a" -Force
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificateUpdated.Name
	Assert-AreEqual "273ab4059bd84b81bbb8308df706379a" $integrationAccountCertificateUpdated.Key.KeyVersion

	$integrationAccountCertificateUpdated = Set-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" -Force
	Assert-AreEqual $integrationAccountCertificateName $integrationAccountCertificateUpdated.Name
	Assert-AreEqual "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" $integrationAccountCertificateUpdated.Key.KeyVault.Id
	
	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-GetIntegrationAccountCertificate
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$certFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "IntegrationAccountCertificate.cer"

	New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" -PublicCertificateFilePath $certFilePath

	$result =  Get-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName
	Assert-AreEqual $integrationAccountCertificateName $result.Name

	$result1 =  Get-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName	
	Assert-True { $result1.Count -gt 0 }	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-RemoveIntegrationAccountCertificate
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountCertificateName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$certFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "IntegrationAccountCertificate.cer"

	New-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -KeyName "PRIVATEKEY" -KeyVersion "273ab4059bd84b81bbb8308df706379a" -KeyVaultId "/subscriptions/f34b22a3-2202-4fb1-b040-1332bd928c84/resourcegroups/DONOTDELETE-IntegrationAccountPsCmdletTest/providers/microsoft.keyvault/vaults/IntegrationAccountVault1" -PublicCertificateFilePath $certFilePath

	Remove-AzIntegrationAccountCertificate -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -CertificateName $integrationAccountCertificateName -Force	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}