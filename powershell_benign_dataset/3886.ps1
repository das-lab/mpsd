
function Test-PowerBIEmbeddedCapacity
{
	try
	{  
		
		$RGlocation = Get-RG-Location
		$location = Get-Location
		$resourceGroupName = Get-ResourceGroupName
		$capacityName = Get-PowerBIEmbeddedCapacityName

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation
		
		$capacityCreated = New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Location $location -Sku 'A1' -Administrator 'aztest0@stabletest.ccsctp.net','aztest1@stabletest.ccsctp.net'
    
		Assert-AreEqual $capacityName $capacityCreated.Name
		Assert-AreEqual $location $capacityCreated.Location
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityCreated.Type
		Assert-AreEqual 2 $capacityCreated.Administrator.Count
		Assert-True {$capacityCreated.Id -like "*$resourceGroupName*"}
	
		[array]$capacityGet = Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName
		$capacityGetItem = $capacityGet[0]

		Assert-True {$capacityGetItem.State -like "Succeeded"}
		Assert-AreEqual $capacityName $capacityGetItem.Name
		Assert-AreEqual $location $capacityGetItem.Location
		Assert-AreEqual $resourceGroupName $capacityGetItem.ResourceGroup
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityGetItem.Type
		Assert-True {$capacityGetItem.Id -like "*$resourceGroupName*"}

		
		Assert-True {Test-AzPowerBIEmbeddedCapacity -Name $capacityName}
		
		Assert-True {Test-AzPowerBIEmbeddedCapacity -Name $capacityName}
		
		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		$capacityUpdated = Update-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Tag $tagsToUpdate -PassThru
		Assert-NotNull $capacityUpdated.Tag "Tag do not exists"
		Assert-NotNull $capacityUpdated.Tag["TestTag"] "The updated tag 'TestTag' does not exist"
		Assert-AreEqual $capacityUpdated.Administrator.Count 2

		$capacityUpdated = Update-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Administrator 'aztest1@stabletest.ccsctp.net' -PassThru
		Assert-NotNull $capacityUpdated.Administrator "Capacity Administrator list is empty"
		Assert-AreEqual $capacityUpdated.Administrator.Count 1

		Assert-AreEqual $capacityName $capacityUpdated.Name
		Assert-AreEqual $location $capacityUpdated.Location
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityUpdated.Type
		Assert-True {$capacityUpdated.Id -like "*$resourceGroupName*"}

		
		[array]$capacitysInResourceGroup = Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName
		Assert-True {$capacitysInResourceGroup.Count -ge 1}

		$found = 0
		for ($i = 0; $i -lt $capacitysInResourceGroup.Count; $i++)
		{
			if ($capacitysInResourceGroup[$i].Name -eq $capacityName)
			{
				$found = 1
				Assert-AreEqual $location $capacitysInResourceGroup[$i].Location
				Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacitysInResourceGroup[$i].Type
				Assert-True {$capacitysInResourceGroup[$i].Id -like "*$resourceGroupName*"}

				break
			}
		}
		Assert-True {$found -eq 1} "capacity created earlier is not found when listing all in resource group: $resourceGroupName."

		
		[array]$capacitysInSubscription = Get-AzPowerBIEmbeddedCapacity
		Assert-True {$capacitysInSubscription.Count -ge 1}
		Assert-True {$capacitysInSubscription.Count -ge $capacitysInResourceGroup.Count}
    
		$found = 0
		for ($i = 0; $i -lt $capacitysInSubscription.Count; $i++)
		{
			if ($capacitysInSubscription[$i].Name -eq $capacityName)
			{
				$found = 1
				Assert-AreEqual $location $capacitysInSubscription[$i].Location
				Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacitysInSubscription[$i].Type
				Assert-True {$capacitysInSubscription[$i].Id -like "*$resourceGroupName*"}
    
				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in subscription."

		
		$capacityGetItem = Suspend-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru
		
		Assert-True {$capacityGetItem.State -like "Paused"}
		Assert-AreEqual $resourceGroupName $capacityGetItem.ResourceGroup

		
		$capacityGetItem = Resume-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru
		[array]$capacityGet = Get-AzPowerBIEmbeddedCapacity -ResourceId $capacityGetItem.Id
		$capacityGetItem = $capacityGet[0]
		Assert-AreEqual $capacityGetItem.Name $capacityGetItem.Name
		Assert-True {$capacityGetItem.State -like "Succeeded"}
		
		
		Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName | Remove-AzPowerBIEmbeddedCapacity -PassThru

		
		Assert-Throws {Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-PowerBIEmbeddedCapacityScale
{
	try
	{  
		
		$RGlocation = Get-RG-Location
		$location = Get-Location
		$resourceGroupName = Get-ResourceGroupName
		$capacityName = Get-PowerBIEmbeddedCapacityName

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation
		
		$capacityCreated = New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Location $location -Sku 'A1' -Administrator 'aztest0@stabletest.ccsctp.net','aztest1@stabletest.ccsctp.net'
		Assert-AreEqual $capacityName $capacityCreated.Name
		Assert-AreEqual $location $capacityCreated.Location
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityCreated.Type
		Assert-AreEqual A1 $capacityCreated.Sku
		Assert-True {$capacityCreated.Id -like "*$resourceGroupName*"}
	
		
		[array]$capacityGet = Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName
		$capacityGetItem = $capacityGet[0]

		Assert-True {$capacityGetItem.State -like "Succeeded"}
		Assert-AreEqual $capacityName $capacityGetItem.Name
		Assert-AreEqual $location $capacityGetItem.Location
		Assert-AreEqual A1 $capacityGetItem.Sku
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityGetItem.Type
		Assert-True {$capacityGetItem.Id -like "*$resourceGroupName*"}
		
		
		$capacityUpdated = Update-AzPowerBIEmbeddedCapacity -Name $capacityName -Sku A2 -PassThru
		Assert-AreEqual A2 $capacityUpdated.Sku

		$capacityGetItem = Suspend-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru
		
		Assert-True {$capacityGetItem.State -like "Paused"}

		
		$capacityUpdated = Update-AzPowerBIEmbeddedCapacity -Name $capacityName -Sku A1 -PassThru
		Assert-AreEqual A1 $capacityUpdated.Sku
		
		
		Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-NegativePowerBIEmbeddedCapacity
{
    param
	(
		$fakecapacityName = "psfakecapacitytest",
		$invalidSku = "INVALID"
	)
	
	try
	{
		
		$RGlocation = Get-RG-Location
		$location = Get-Location
		$resourceGroupName = Get-ResourceGroupName
		$capacityName = Get-PowerBIEmbeddedCapacityName
		
		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation
		$capacityCreated = New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Location $location -Sku 'A1' -Administrator 'aztest0@stabletest.ccsctp.net','aztest1@stabletest.ccsctp.net'

		Assert-AreEqual $capacityName $capacityCreated.Name
		Assert-AreEqual $location $capacityCreated.Location
		Assert-AreEqual "Microsoft.PowerBIDedicated/capacities" $capacityCreated.Type
		Assert-True {$capacityCreated.Id -like "*$resourceGroupName*"}

		
		Assert-Throws {New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Location $location}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		Assert-Throws {Update-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $fakecapacityName -Tag $tagsToUpdate}

		
		Assert-Throws {Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $fakecapacityName}

		
		Assert-Throws {New-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $fakecapacityName -Location $location -Sku $invalidSku -Administrator 'aztest0@stabletest.ccsctp.net','aztest1@stabletest.ccsctp.net'}

		
		Assert-Throws {Update-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -Sku $invalidSku}

		
		Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru

		
		Assert-Throws {Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -PassThru}

		
		Assert-Throws {Get-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzPowerBIEmbeddedCapacity -ResourceGroupName $resourceGroupName -Name $capacityName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}
