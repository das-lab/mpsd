














$instanceLocation = "eastus"


function Test-CreateManagedInstance
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "vnet-newprovisioningtest3"
	$subnetName = "ManagedInstance"

	$managedInstanceName = Get-ManagedInstanceName
 	$version = "12.0"
 	$credentials = Get-ServerCredential
 	$licenseType = "BasePrice"
  	$storageSizeInGB = 32
 	$vCore = 16
 	$skuName = "GP_Gen4"
	$collation = "Serbian_Cyrillic_100_CS_AS"
	$timezoneId = "Central Europe Standard Time"
	$proxyOverride = "Proxy"
 	try
 	{
		
		$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location "newprovisioningtest"
		$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

 		
 		$job = New-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstanceName `
 			-Location $rg.Location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -SkuName $skuName -Collation $collation `
			-TimezoneId $timezoneId -PublicDataEndpointEnabled -ProxyOverride $proxyOverride -AsJob
 		$job | Wait-Job
 		$managedInstance1 = $job.Output

 		Assert-AreEqual $managedInstance1.ManagedInstanceName $managedInstanceName
		Assert-AreEqual $managedInstance1.Location $rg.Location
		Assert-AreEqual $managedInstance1.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $managedInstance1.Sku.Name $skuName
 		Assert-AreEqual $managedInstance1.AdministratorLogin $credentials.Username
		Assert-AreEqual $managedInstance1.SubnetId $subnetId
		Assert-AreEqual $managedInstance1.LicenseType $licenseType
		Assert-AreEqual $managedInstance1.VCores $vCore
		Assert-AreEqual $managedInstance1.StorageSizeInGB $storageSizeInGB
		Assert-AreEqual $managedInstance1.Collation $collation
		Assert-AreEqual $managedInstance1.TimezoneId $timezoneId
		Assert-AreEqual $managedInstance1.PublicDataEndpointEnabled $true
		Assert-AreEqual $managedInstance1.ProxyOverride $proxyOverride
 		Assert-StartsWith ($managedInstance1.ManagedInstanceName + ".") $managedInstance1.FullyQualifiedDomainName
        Assert-NotNull $managedInstance1.DnsZone

		$edition = "GeneralPurpose"
		$computeGeneration = "Gen4"
		$managedInstanceName = Get-ManagedInstanceName
		$dnsZonePartner = $managedInstance1.ResourceId
        $originalDnsZone = $managedInstance1.DnsZone

		
 		$job = New-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstanceName `
 			-Location $rg.Location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -Edition $edition -ComputeGeneration $computeGeneration  -DnsZonePartner $dnsZonePartner  -AsJob
 		$job | Wait-Job
 		$managedInstance1 = $job.Output

 		Assert-AreEqual $managedInstance1.ManagedInstanceName $managedInstanceName
		Assert-AreEqual $managedInstance1.Location $rg.Location
		Assert-AreEqual $managedInstance1.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $managedInstance1.Sku.Name $skuName
 		Assert-AreEqual $managedInstance1.AdministratorLogin $credentials.Username
		Assert-AreEqual $managedInstance1.SubnetId $subnetId
		Assert-AreEqual $managedInstance1.LicenseType $licenseType
		Assert-AreEqual $managedInstance1.VCores $vCore
		Assert-AreEqual $managedInstance1.StorageSizeInGB $storageSizeInGB
 		Assert-StartsWith ($managedInstance1.ManagedInstanceName + ".") $managedInstance1.FullyQualifiedDomainName
        Assert-AreEqual $managedInstance1.DnsZone $originalDnsZone
 	}
 	finally
 	{
		Remove-ResourceGroupForTest $rg
 	}
}


function Test-SetManagedInstance
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "vnet-newprovisioningtest3"
	$subnetName = "ManagedInstance"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location "newprovisioningtest"
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

	try
	{
		
		$credentials = Get-ServerCredential
		$licenseType = "BasePrice"
		$storageSizeInGB = 64
		$vCore = 8

		$managedInstance1 = Set-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstance.ManagedInstanceName `
			-AdministratorPassword $credentials.Password -LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -Force

		Assert-AreEqual $managedInstance1.ManagedInstanceName $managedInstance.ManagedInstanceName
		Assert-AreEqual $managedInstance1.AdministratorLogin $managedInstance.AdministratorLogin
		Assert-AreEqual $managedInstance1.LicenseType $licenseType
		Assert-AreEqual $managedInstance1.VCores $vCore
		Assert-AreEqual $managedInstance1.StorageSizeInGB $storageSizeInGB
		Assert-StartsWith ($managedInstance1.ManagedInstanceName + ".") $managedInstance1.FullyQualifiedDomainName

		
		$credentials = Get-ServerCredential

		$licenseType = "LicenseIncluded"
		$storageSizeInGB = 96
		$vCore = 16

		$managedInstance2 = $managedInstance | Set-AzSqlInstance -AdministratorPassword $credentials.Password `
			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -Force

		Assert-AreEqual $managedInstance2.ManagedInstanceName $managedInstance.ManagedInstanceName
		Assert-AreEqual $managedInstance2.AdministratorLogin $managedInstance.AdministratorLogin
		Assert-AreEqual $managedInstance2.LicenseType $licenseType
		Assert-AreEqual $managedInstance2.VCores $vCore
		Assert-AreEqual $managedInstance2.StorageSizeInGB $storageSizeInGB
		Assert-StartsWith ($managedInstance2.ManagedInstanceName + ".") $managedInstance2.FullyQualifiedDomainName

		
		$credentials = Get-ServerCredential
		$licenseType = "BasePrice"
		$storageSizeInGB = 64
		$vCore = 8

		$managedInstance3 = Set-AzSqlInstance -InputObject $managedInstance `
			-AdministratorPassword $credentials.Password -LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -Force

		Assert-AreEqual $managedInstance3.ManagedInstanceName $managedInstance.ManagedInstanceName
		Assert-AreEqual $managedInstance3.AdministratorLogin $managedInstance.AdministratorLogin
		Assert-AreEqual $managedInstance3.LicenseType $licenseType
		Assert-AreEqual $managedInstance3.VCores $vCore
		Assert-AreEqual $managedInstance3.StorageSizeInGB $storageSizeInGB
		Assert-StartsWith ($managedInstance3.ManagedInstanceName + ".") $managedInstance3.FullyQualifiedDomainName

		
		$credentials = Get-ServerCredential
		$licenseType = "BasePrice"
		$storageSizeInGB = 32
		$vCore = 16
		$publicDataEndpointEnabled = $true
		$proxyOverride = "Proxy"

		$managedInstance4 = Set-AzSqlInstance -ResourceId $managedInstance.Id `
			-AdministratorPassword $credentials.Password -LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore `
			-PublicDataEndpointEnabled $publicDataEndpointEnabled -ProxyOverride $proxyOverride -Force

		Assert-AreEqual $managedInstance4.ManagedInstanceName $managedInstance.ManagedInstanceName
		Assert-AreEqual $managedInstance4.AdministratorLogin $managedInstance.AdministratorLogin
		Assert-AreEqual $managedInstance4.LicenseType $licenseType
		Assert-AreEqual $managedInstance4.VCores $vCore
		Assert-AreEqual $managedInstance4.StorageSizeInGB $storageSizeInGB
		Assert-AreEqual $managedInstance4.PublicDataEndpointEnabled $publicDataEndpointEnabled
		Assert-AreEqual $managedInstance4.ProxyOverride $proxyOverride
		Assert-StartsWith ($managedInstance4.ManagedInstanceName + ".") $managedInstance4.FullyQualifiedDomainName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetManagedInstance
{
	
	$rg = Create-ResourceGroupForTest $instanceLocation
	$rg1 = Create-ResourceGroupForTest $instanceLocation
	$vnetName = "cl_initial"
	$subnetName = "CooL"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location "powershell_mi"
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance1 = Create-ManagedInstanceForTest $rg $subnetId
	$managedInstance2 = Create-ManagedInstanceForTest $rg1 $subnetId

	try
	{
		
		$resp1 = Get-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstance1.ManagedInstanceName
		Assert-AreEqual $managedInstance1.ManagedInstanceName $resp1.ManagedInstanceName
		Assert-AreEqual $managedInstance1.SqlAdministratorLogin $resp1.SqlAdministratorLogin
		Assert-StartsWith ($managedInstance1.ManagedInstanceName + ".") $resp1.FullyQualifiedDomainName
		Assert-AreEqual $managedInstance1.AdministratorLogin $resp1.AdministratorLogin
		Assert-AreEqual $managedInstance1.LicenseType $resp1.LicenseType
		Assert-AreEqual $managedInstance1.VCores $resp1.VCores
		Assert-AreEqual $managedInstance1.StorageSizeInGB $resp1.StorageSizeInGB

		$all = Get-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name *
		Assert-AreEqual 1 $all.Count

		
		$all2 = Get-AzSqlInstance -ResourceGroupName *

		
		
		($managedInstance1, $managedInstance2) | ForEach-Object { Assert-True {$_.ManagedInstanceName -in $all2.ManagedInstanceName} }
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $rg1
	}
}


function Test-RemoveManagedInstance
{
	
	$rg = Create-ResourceGroupForTest $instanceLocation
	$vnetName = "cl_initial"
	$subnetName = "CooL"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location "powershell_mi"
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	try
	{
		
		$managedInstance1 = Create-ManagedInstanceForTest $rg $subnetId
		Remove-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstance1.ManagedInstanceName -Force

		
		$managedInstance2 = Create-ManagedInstanceForTest $rg $subnetId
		Remove-AzSqlInstance -InputObject $managedInstance2 -Force

		
		$managedInstance3 = Create-ManagedInstanceForTest $rg $subnetId
		Remove-AzSqlInstance -ResourceId $managedInstance3.Id -Force

		
		$managedInstance4 = Create-ManagedInstanceForTest $rg $subnetId
		$managedInstance4 | Remove-AzSqlInstance -Force

		$all = Get-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateManagedInstanceWithIdentity
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "CooL"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

 	$managedInstanceName = Get-ManagedInstanceName
 	$version = "12.0"
 	$credentials = Get-ServerCredential
 	$licenseType = "BasePrice"
  	$storageSizeInGB = 32
 	$vCore = 16
 	$skuName = "GP_Gen4"

	try
	{
		$managedInstance1 = New-AzSqlInstance -ResourceGroupName $rg.ResourceGroupName -Name $managedInstanceName `
 			-Location $rg.Location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -SkuName $skuName -AssignIdentity

		Assert-AreEqual $managedInstance1.ManagedInstanceName $managedInstanceName
		Assert-AreEqual $managedInstance1.Identity.Type SystemAssigned
		Assert-NotNull $managedInstance1.Identity.PrincipalId
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}