















function Get-ResourceGroupLocation
{
    $namespace = "Microsoft.RecoveryServices"
    $type = "vaults"
    $resourceProvider = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}
  
    if ($resourceProvider -eq $null)
    {
        return "westus";
    }
	else
    {
		return $resourceProvider.Locations[0]
    }
}

function Get-RandomSuffix(
	[int] $size = 8)
{
	$variableName = "NamingSuffix"
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -eq [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Record)
	{
		if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables.ContainsKey($variableName))
		{
			$suffix = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables[$variableName]
		}
		else
		{
			$suffix = @((New-Guid).Guid)

			[Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables[$variableName] = $suffix
		}
	}
	else
	{
		$suffix = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables[$variableName]
	}

	return $suffix.Substring(0, $size)
}

function Create-ResourceGroup(
	[string] $location)
{
	$name = "PSTestRG" + @(Get-RandomSuffix)

	$resourceGroup = Get-AzResourceGroup -Name $name -ErrorAction Ignore
	
	if ($resourceGroup -eq $null)
	{
		New-AzResourceGroup -Name $name -Location $location | Out-Null
	}

	return $name
}

function Cleanup-ResourceGroup(
	[string] $resourceGroupName)
{
	$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Ignore

	if ($resourceGroup -ne $null)
	{
		
		$vaults = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName
		foreach ($vault in $vaults)
		{
			Remove-AzRecoveryServicesVault -Vault $vault
		}
	
		
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}


function Test-RecoveryServicesVaultCRUD
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location
	$name = "PSTestRSV" + @(Get-RandomSuffix)

	try
	{
	  
		$vault1 = New-AzRecoveryServicesVault -Name $name -ResourceGroupName $resourceGroupName -Location $location

		Assert-NotNull($vault1.Name)
		Assert-NotNull($vault1.ID)
		Assert-NotNull($vault1.Type)

		
		Set-AzRecoveryServicesVaultContext -Vault $vault1
		
		
		$vaults = Get-AzRecoveryServicesVault -Name $name -ResourceGroupName $resourceGroupName

		Assert-NotNull($vaults)
		Assert-True { $vaults.Count -gt 0 }
		foreach ($vault in $vaults)
		{
			Assert-NotNull($vault.Name)
			Assert-NotNull($vault.ID)
			Assert-NotNull($vault.Type)
		}

		
		$vaultBackupProperties = Get-AzRecoveryServicesBackupProperty -Vault $vault1

		Assert-NotNull($vaultBackupProperties.BackupStorageRedundancy)

		
		Set-AzRecoveryServicesBackupProperties -Vault $vault1 -BackupStorageRedundancy LocallyRedundant

		
		Remove-AzRecoveryServicesVault -Vault $vault1

		$vaults = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $name
		Assert-True { $vaults.Count -eq 0 } 
	}
	finally
	{
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-GetRSVaultSettingsFile
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location
	$name = "PSTestRSV" + @(Get-RandomSuffix)

	try
	{
  		
		$vault = New-AzRecoveryServicesVault -Name $name -ResourceGroupName $resourceGroupName -Location $location

		
		$file = Get-AzRecoveryServicesVaultSettingsFile -Vault $vault -Backup
		
		if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -eq [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Record)
		{
			Assert-NotNull $file
			Assert-NotNull $file.FilePath
		}
	}
	finally
	{
		Cleanup-ResourceGroup $resourceGroupName
	}
}
