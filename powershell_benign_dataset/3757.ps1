














function Test-CreateIntegrationAccountPartner
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName 

	$integrationAccountPartnerName = getAssetname
	$integrationAccountPartnerName1 = getAssetname

	$businessIdentities = @(
             ("01","Test1"),
             ("02","Test2"),
             ("As2Identity","Test3"),
             ("As2Identity","Test4")
            )

	$businessIdentities1 = @(
             ("As2Identity","Test4")
            )

	$integrationAccountPartner =  New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -PartnerType "B2B" -BusinessIdentities $businessIdentities
	Assert-AreEqual $integrationAccountPartnerName $integrationAccountPartner.Name

	$integrationAccountPartner1 =  New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName1 -BusinessIdentities $businessIdentities1
	Assert-AreEqual $integrationAccountPartnerName1 $integrationAccountPartner1.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-GetIntegrationAccountPartner
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName 

	$integrationAccountPartnerName = getAssetname

	$businessIdentities = @(
             ("ZZ","AA"),
             ("XX","GG")
            )

	$integrationAccountPartner =  New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -PartnerType "B2B" -BusinessIdentities $businessIdentities
	Assert-AreEqual $integrationAccountPartnerName $integrationAccountPartner.Name

	$result =  Get-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName
	Assert-AreEqual $integrationAccountPartnerName $result.Name

	$result1 =  Get-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName
	Assert-True { $result1.Count -gt 0 }	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-ListIntegrationAccountPartner
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName 

	$businessIdentities = @(("ZZ","AA"),("XX","GG"))

	$val=0
	while($val -ne 1)
	{
		$val++ ;
		$integrationAccountPartnerName = getAssetname
		New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -PartnerType "B2B" -BusinessIdentities $businessIdentities
	}

	$result =  Get-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName
	Assert-True { $result.Count -eq 1 }

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}



function Test-RemoveIntegrationAccountPartner
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountPartnerName = getAssetname
	$businessIdentities = @(
             ("ZZ","AA"),
             ("XX","GG")
            )

	$integrationAccountPartner =  New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -PartnerType "B2B" -BusinessIdentities $businessIdentities
	Assert-AreEqual $integrationAccountPartnerName $integrationAccountPartner.Name

	Remove-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -Force	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-UpdateIntegrationAccountPartner
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountPartnerName = getAssetname
	$businessIdentities = @(
             ("ZZ","AA"),
             ("SS","FF")
            )

	$businessIdentities1 = @(
             ("CC","VV")
            )

	$integrationAccountPartner =  New-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -BusinessIdentities $businessIdentities
	Assert-AreEqual $integrationAccountPartnerName $integrationAccountPartner.Name

	$integrationAccountPartnerUpdated = Set-AzIntegrationAccountPartner -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -PartnerName $integrationAccountPartnerName -BusinessIdentities $businessIdentities1	-Force
	Assert-AreEqual $integrationAccountPartnerName $integrationAccountPartnerUpdated.Name
	
	
	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}