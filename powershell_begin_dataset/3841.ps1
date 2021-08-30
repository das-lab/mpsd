














function Test-AzureContainerRegistry
{
    
    $resourceGroupName = Get-RandomResourceGroupName
    $classicRegistryName = Get-RandomRegistryName
    $location = Get-ProviderLocation "Microsoft.ContainerRegistry/registries"
	$replicationLocation = 'westus2'

	try
	{
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		$classicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName -Sku "Classic"
		Verify-ContainerRegistry $classicRegistry $resourceGroupName $classicRegistryName "Classic" $null $false

		
		$nameStatus = Test-AzContainerRegistryNameAvailability -Name $classicRegistryName
		Assert-True {!$nameStatus.nameAvailable}
		Assert-AreEqual "AlreadyExists" $nameStatus.Reason
		Assert-AreEqual "The registry $($classicRegistryName) is already in use." $nameStatus.Message

		
		$storageAccountName = $classicRegistry.StorageAccountName
		$retrievedRegistry = Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName
		Verify-ContainerRegistry $retrievedRegistry $resourceGroupName $classicRegistryName "Classic" $storageAccountName $false

		$basicRegistryName = Get-RandomRegistryName
		$basicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $basicRegistryName -Sku "Basic" -EnableAdminUser
		Verify-ContainerRegistry $basicRegistry $resourceGroupName $basicRegistryName "Basic" $null $true

		$standardRegistryName = Get-RandomRegistryName
		$standardRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $standardRegistryName -Sku "Standard"
		Verify-ContainerRegistry $standardRegistry $resourceGroupName $standardRegistryName "Standard" $null $false

		$premiumRegistryName = Get-RandomRegistryName
		$premiumRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -Sku "Premium"
		Verify-ContainerRegistry $premiumRegistry $resourceGroupName $premiumRegistryName "Premium" $null $false

		
		$registry = Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -IncludeDetail
		Assert-AreEqual "Size" $registry.Usages[0].Name
		Assert-AreEqual "Webhooks" $registry.Usages[1].Name

		
		$registries = Get-AzContainerRegistry -ResourceGroupName $resourceGroupName
		Assert-AreEqual 4 $registries.Count
		foreach($r in $registries)
		{
			switch($r.SkuName)
			{
				"Classic" { Verify-ContainerRegistry $r $resourceGroupName $classicRegistryName "Classic" $storageAccountName $false }
				"Basic" { Verify-ContainerRegistry $r $resourceGroupName $basicRegistryName "Basic" $null $true }
				"Standard" { Verify-ContainerRegistry $r $resourceGroupName $standardRegistryName "Standard" $null $false }
				"Premium" { Verify-ContainerRegistry $r $resourceGroupName $premiumRegistryName "Premium" $null $false }
			}
		}

		
		Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName | Remove-AzContainerRegistry
		Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $standardRegistryName | Remove-AzContainerRegistry
		Remove-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName
		Remove-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $basicRegistryName
		$registries = Get-AzContainerRegistry -ResourceGroupName $resourceGroupName
		Assert-AreEqual 0 $registries.Count

		
		$classicRegistryName = Get-RandomRegistryName
		$classicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName -Sku "Classic" -StorageAccountName $storageAccountName
		Verify-ContainerRegistry $classicRegistry $resourceGroupName $classicRegistryName "Classic" $storageAccountName $false

		
		$premiumRegistryName = Get-RandomRegistryName
		Assert-Error {New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -Sku "Premium" -StorageAccountName $storageAccountName} "User cannot provide storage account in SKU Premium"
    
		
		$updatedClassicRegistry = Update-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName -EnableAdminUser -StorageAccountName $storageAccountName
		Verify-ContainerRegistry $updatedClassicRegistry $resourceGroupName $classicRegistryName "Classic" $storageAccountName $true
	
		
		$premiumRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -Sku "Premium"
		Assert-Error {Update-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -EnableAdminUser -StorageAccountName $storageAccountName} "Storage account cannot be updated in SKU Premium"

		Get-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName | Update-AzContainerRegistry -DisableAdminUser
		Verify-ContainerRegistry $premiumRegistry $resourceGroupName $premiumRegistryName "Premium" $null $false

		Remove-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName	
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}


function Verify-ContainerRegistry
{
	param([Microsoft.Azure.Commands.ContainerRegistry.PSContainerRegistry] $registry, [string] $resourceGroupName, [string] $registryName, [string] $sku, [string] $storageAccountName, [bool] $adminUserEnabled) 

	Assert-NotNull $registry
	Assert-AreEqual $resourceGroupName $registry.ResourceGroupName
    Assert-AreEqual $registryName  $registry.Name
    Assert-AreEqual "Microsoft.ContainerRegistry/registries" $registry.Type
    Assert-AreEqual $sku $registry.SkuName
    Assert-AreEqual $sku $registry.SkuTier 
    Assert-AreEqual "$($registryName.ToLower()).azurecr.io" $registry.LoginServer
    Assert-AreEqual "Succeeded" $registry.ProvisioningState
    Assert-AreEqual $adminUserEnabled $registry.AdminUserEnabled
	If($sku -eq 'Classic')
	{
		If(!$storageAccountName)
		{
			Assert-NotNull $registry.StorageAccountName
		}
		Else
		{
			Assert-AreEqual $storageAccountName $registry.StorageAccountName
		}
	}
	Else
	{
		Assert-Null $registry.StorageAccountName
	}
}


function Test-AzureContainerRegistryCredential
{
    
    $resourceGroupName = Get-RandomResourceGroupName    
    $location = Get-ProviderLocation "Microsoft.ContainerRegistry/registries"

    New-AzResourceGroup -Name $resourceGroupName -Location $location
	
	Test-AzureContainerRegistryCredentialBySku $resourceGroupName $location "Classic"

	Test-AzureContainerRegistryCredentialBySku $resourceGroupName $location "Basic"	

	Test-AzureContainerRegistryCredentialBySku $resourceGroupName $location "Standard"	

	Test-AzureContainerRegistryCredentialBySku $resourceGroupName $location "Premium"	

    Remove-AzResourceGroup -Name $resourceGroupName -Force
}

function Test-AzureContainerRegistryCredentialBySku
{
	param([string] $resourceGroupName, [string] $location, [string] $sku) 

	$registryName = Get-RandomRegistryName
    
    $registry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $registryName -Sku $sku -EnableAdminUser
	Verify-ContainerRegistry $registry $resourceGroupName $registryName $sku $null $true

    $credential = Get-AzContainerRegistryCredential -ResourceGroupName $resourceGroupName -Name $registryName
    Assert-AreEqual $registryName $credential.Username
    Assert-NotNull $credential.Password
    Assert-NotNull $credential.Password2

    $newCredential1 = Update-AzContainerRegistryCredential -ResourceGroupName $resourceGroupName -Name $registryName -PasswordName Password
    Assert-AreEqual $registryName $newCredential1.Username
    Assert-AreNotEqual $credential.Password $newCredential1.Password
    Assert-AreEqual $credential.Password2 $newCredential1.Password2

    $newCredential2 = Update-AzContainerRegistryCredential -ResourceGroupName $resourceGroupName -Name $registryName -PasswordName Password2
    Assert-AreEqual $registryName $newCredential2.Username
    Assert-AreEqual $newCredential1.Password $newCredential2.Password
    Assert-NotNull $newCredential1.Password2 $newCredential2.Password2
}


function Test-AzureContainerRegistryNameAvailability
{
    
    $nameStatus = Test-AzContainerRegistryNameAvailability -Name $(Get-RandomRegistryName)
    Assert-True {$nameStatus.nameAvailable}
    Assert-Null $nameStatus.Reason
    Assert-Null $nameStatus.Message

    $nameStatus = Test-AzContainerRegistryNameAvailability -Name "Microsoft"
    Assert-True {!$nameStatus.nameAvailable}
    Assert-AreEqual "Invalid" $nameStatus.Reason
    Assert-AreEqual "The specified resource name is disallowed" $nameStatus.Message
}


function Test-AzureContainerRegistryReplication
{
	
    $resourceGroupName = Get-RandomResourceGroupName    
    $location = Get-ProviderLocation "Microsoft.ContainerRegistry/registries"

	try
	{
		$replicationLocation = "centralus"
		$replicationLocation2 = "westus2"
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		$classicRegistryName = Get-RandomRegistryName
		$classicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName -Sku "Classic" -Location $location
		Assert-Error {New-AzContainerRegistryReplication -Registry $classicRegistry -Location $replicationLocation} "The resource type replications is not supported for the registry"

		
		$basicRegistryName = Get-RandomRegistryName
		$basicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $basicRegistryName -Sku "Basic" -Location $location
		Assert-Error {New-AzContainerRegistryReplication -Registry $basicRegistry -Location $replicationLocation} "The resource type replications is not supported for the registry"

		
		$standardRegistryName = Get-RandomRegistryName
		$standardRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $standardRegistryName -Sku "Standard" -Location $location
		Assert-Error {New-AzContainerRegistryReplication -Registry $standardRegistry -Location $replicationLocation} "The resource type replications is not supported for the registry"

		
		$premiumRegistryName = Get-RandomRegistryName
		$replicationName = Get-RandomReplicationName
		$premiumRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -Sku "Premium" -Location $location
		$replication = New-AzContainerRegistryReplication -ResourceGroupName $premiumRegistry.ResourceGroupName -RegistryName $premiumRegistry.Name -Location $replicationLocation -Name $replicationName -Tag @{key='val'}
		Verify-AzureContainerRegistryReplication $replication $replicationLocation @{key='val'} $replicationName

		$replication2 = New-AzContainerRegistryReplication -ResourceGroupName $premiumRegistry.ResourceGroupName -RegistryName $premiumRegistry.Name -Location $replicationLocation2
		Verify-AzureContainerRegistryReplication $replication2 $replicationLocation2

		
		
		$replications = Get-AzContainerRegistryReplication -Registry $premiumRegistry
		Assert-AreEqual 3 $replications.Count

		
		Remove-AzContainerRegistryReplication -ResourceGroupName $premiumRegistry.ResourceGroupName -RegistryName $premiumRegistry.Name -Name $replication2.Name
		$replications = Get-AzContainerRegistryReplication -ResourceGroupName $premiumRegistry.ResourceGroupName -RegistryName $premiumRegistry.Name
		Assert-AreEqual 2 $replications.Count
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}

function Verify-AzureContainerRegistryReplication
{
	param([Microsoft.Azure.Commands.ContainerRegistry.PSContainerRegistryReplication] $replication, [string] $location, [System.Collections.Hashtable] $tags = $null, [string] $name = $location)

	Assert-NotNull $replication
	Assert-AreEqual $name $replication.Name
	Assert-AreEqual $location $replication.Location
	Assert-AreEqual "Microsoft.ContainerRegistry/registries/replications" $replication.Type
	Assert-AreEqual "Succeeded"	$replication.ProvisioningState
	Assert-NotNull $replication.StatusTimestamp
	Assert-True { ($replication.Status -eq "Syncing") -or ($replication.Status -eq "Ready") }
	if($tags)
	{
		Verify-Dictionary $tags $replication.Tags
	}
}

function Verify-Dictionary
{
	param([System.Collections.Hashtable] $expected, [System.Collections.Generic.Dictionary`2[System.String,System.String]] $actual)

	Assert-AreEqualArray $expected.Keys $actual.Keys
	Assert-AreEqualArray $expected.Values $actual.Values
}

function Test-AzureContainerRegistryWebhook
{
	
    $resourceGroupName = Get-RandomResourceGroupName    
    $location = Get-ProviderLocation "Microsoft.ContainerRegistry/registries"

	try
	{
		$replicationLocation = "centralus"
		$replicationLocation2 = "westus2"
		$webhookUri = "http://bing.com/"
		$webhookUri2 = "http://microsoft.com/"
		New-AzResourceGroup -Name $resourceGroupName -Location $location		

		
		$classicRegistryName = Get-RandomRegistryName
		$webhookName = Get-RandomWebhookName
		$classicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $classicRegistryName -Sku "Classic" -Location $location
		Assert-Error {New-AzContainerRegistryWebhook -Registry $classicRegistry -Location $location -Name $webhookName -Action "push","delete" -Uri $webhookUri} "The resource type webhooks is not supported for the registry"

		
		$basicRegistryName = Get-RandomRegistryName
		$webhookName = Get-RandomWebhookName
		$basicRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $basicRegistryName -Sku "Basic" -Location $replicationLocation
		$webhook = New-AzContainerRegistryWebhook -Registry $basicRegistry -Name $webhookName -Action "push","delete" -Uri $webhookUri -Location $replicationLocation
		Verify-AzureContainerRegistryWebhook $webhook $webhookName $replicationLocation "push","delete"

		
		$standardRegistryName = Get-RandomRegistryName
		$webhookName = Get-RandomWebhookName
		$standardRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $standardRegistryName -Sku "Standard" -Location $replicationLocation
		$webhook = New-AzContainerRegistryWebhook -Registry $standardRegistry -Name $webhookName -Action "push","delete" -Uri $webhookUri
		Verify-AzureContainerRegistryWebhook $webhook $webhookName $replicationLocation "push","delete"

		
		$premiumRegistryName = Get-RandomRegistryName
		$webhookName = Get-RandomWebhookName
		$premiumRegistry = New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $premiumRegistryName -Sku "Premium" -Location $replicationLocation
		$webhook = New-AzContainerRegistryWebhook -Registry $premiumRegistry -Name $webhookName -Action "push","delete" -Uri $webhookUri -Tag @{key='val'} -Scope "foo:*"
		Verify-AzureContainerRegistryWebhook $webhook $webhookName $replicationLocation "push","delete" @{key='val'} "enabled" "foo:*"

		
		$webhookName2 = Get-RandomWebhookName
		$webhook2 = New-AzContainerRegistryWebhook  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName2 -Action "push" -Uri $webhookUri -Status "Disabled"
		Verify-AzureContainerRegistryWebhook $webhook2 $webhookName2 $replicationLocation "push" $null "disabled"
		$webhook2 = Get-AzContainerRegistryWebhook  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName2 -IncludeConfiguration
		Assert-AreEqual $webhookUri $webhook2.Config.ServiceUri

		
		$updatedWebhook = Update-AzContainerRegistryWebhook -Webhook $webhook2 -Action "push","delete" -Uri $webhookUri2 -Status "Enabled" -Tag @{key='val'} -Scope "foo:*" -Header @{customheader="abc";testheader="123"}
		Verify-AzureContainerRegistryWebhook $updatedWebhook $webhookName2 $replicationLocation "push","delete" @{key='val'} "enabled" "foo:*"
		$webhook2 = Get-AzContainerRegistryWebhook  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName2 -IncludeConfiguration
		Assert-AreEqual $webhookUri2 $webhook2.Config.ServiceUri
		Verify-Dictionary @{customheader="abc";testheader="123"} $webhook2.Config.CustomHeaders

		
		$webhookName3 = Get-RandomWebhookName
		Assert-Error {New-AzContainerRegistryWebhook  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName3 -Action "push" -Uri $webhookUri -Location $replicationLocation2} "The registry resource $($premiumRegistryName) could not be found"

		
		New-AzContainerRegistryReplication -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Location $replicationLocation2
		$webhook3 = New-AzContainerRegistryWebhook -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName3 -Action "push" -Uri $webhookUri -Location $replicationLocation2
		Verify-AzureContainerRegistryWebhook $webhook3 $webhookName3 $replicationLocation2 "push"

		
		$webhooks = Get-AzContainerRegistryWebhook -Registry $premiumRegistry
		Assert-AreEqual 3 $webhooks.Count

		
		Test-AzContainerRegistryWebhook -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName3
		Test-AzContainerRegistryWebhook -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName3		
		$pingEvents = Get-AzContainerRegistryWebhookEvent  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -WebhookName $webhookName3
		Assert-AreEqual 2 $pingEvents.Count

		$pingEvents = Get-AzContainerRegistryWebhookEvent  -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -WebhookName $webhookName2
		Assert-AreEqual 0 $pingEvents.Count


		
		Remove-AzContainerRegistryWebhook -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName2
		Remove-AzContainerRegistryWebhook -ResourceGroupName $resourceGroupName -RegistryName $premiumRegistryName -Name $webhookName3
		$webhooks = Get-AzContainerRegistryWebhook -Registry $premiumRegistry
		Assert-AreEqual 1 $webhooks.Count
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}

function Verify-AzureContainerRegistryWebhook
{
	param([Microsoft.Azure.Commands.ContainerRegistry.PSContainerRegistryWebhook] $webhook, [string] $name, [string] $location, [Array] $actions, [Hashtable] $tags = $null, [string] $status="enabled", [string] $scope = "")

	Assert-NotNull $webhook
	Assert-AreEqual $name $webhook.Name
	Assert-AreEqual "Microsoft.ContainerRegistry/registries/webhooks" $webhook.Type
	Assert-AreEqual $location $webhook.Location
	Assert-AreEqual $status $webhook.Status
	Assert-AreEqual "Succeeded" $webhook.ProvisioningState
	Assert-AreEqualArray $actions $webhook.Actions
	if($scope)
	{
		Assert-AreEqual $scope $webhook.Scope
	}
	if($tags)
	{
		Verify-Dictionary $tags $webhook.Tags
	}
}