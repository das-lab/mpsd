



















function Test-GetWorkspaceCollection_ListAll
{
    try {
		$resourceGroup = Create-ResourceGroup
		$workspaceCollectionNames = 1..2 |% { Get-WorkspaceCollectionName }
		$newWorkspaceCollections = $workspaceCollectionNames |% { New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $_ `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location }

		$allWorkspaceCollections = Get-AzPowerBIWorkspaceCollection

		Assert-True { $allWorkspaceCollections[$allWorkspaceCollections.Count - 2].Name -eq $workspaceCollectionNames[0] }
		Assert-True { $allWorkspaceCollections[$allWorkspaceCollections.Count - 1].Name -eq $workspaceCollectionNames[1] }
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}


function Test-GetWorkspaceCollection_ListByResourceGroup
{
    try {
		$resourceGroup = Create-ResourceGroup
		$workspaceCollectionNames = 1..2 |% { Get-WorkspaceCollectionName }
		$newWorkspaceCollections = $workspaceCollectionNames |% { New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $_ `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location }

		$filteredWorkspaceCollections = Get-AzPowerBIWorkspaceCollection -ResourceGroupName $resourceGroup.ResourceGroupName

		Assert-AreEqual $filteredWorkspaceCollections.Count $newWorkspaceCollections.Count
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}


function Test-GetWorkspaceCollection_ByName
{
    try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		$foundWorkspaceCollection = Get-AzPowerBIWorkspaceCollection `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

		Assert-AreEqual $newWorkspaceCollection.Name $foundWorkspaceCollection.Name
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}







function Test-GetWorkspace_EmptyCollection
{
    try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		$workspaces = Get-AzPowerBIWorkspace `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

        Assert-AreEqual 0 $workspaces.Count
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}







function Test-ResetWorkspaceCollectionAccessKeys_Key1
{
    try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		$k1 = Get-AzPowerBIWorkspaceCollectionAccessKeys `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

		$kr = Reset-AzPowerBIWorkspaceCollectionAccessKeys `
			-Key1 `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

		$k2 = Get-AzPowerBIWorkspaceCollectionAccessKeys `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

        Assert-AreEqual $k1[1].Value $kr[1].Value
        Assert-AreNotEqual $k1[0].Value $kr[0].Value

        Assert-AreEqual $kr[0].Value $k2[0].Value
        Assert-AreEqual $kr[1].Value $k2[1].Value
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}


function Test-ResetWorkspaceCollectionAccessKeys_Key2
{
    try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		$k1 = Get-AzPowerBIWorkspaceCollectionAccessKeys `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

		$kr = Reset-AzPowerBIWorkspaceCollectionAccessKeys `
			-Key2 `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

		$k2 = Get-AzPowerBIWorkspaceCollectionAccessKeys `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

        Assert-AreEqual $k1[0].Value $kr[0].Value
        Assert-AreNotEqual $k1[1].Value $kr[1].Value

        Assert-AreEqual $kr[0].Value $k2[0].Value
        Assert-AreEqual $kr[1].Value $k2[1].Value
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}


function Test-GetWorkspaceCollectionAccessKeys
{
    try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		$keys = Get-AzPowerBIWorkspaceCollectionAccessKeys `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-WorkspaceCollectionName $newWorkspaceCollection.Name

        Assert-AreNotEqual $null $keys
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}


function Test-RemoveWorkspaceCollection
{
	try {
		$resourceGroup = Create-ResourceGroup
		$newWorkspaceCollection = New-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $(Get-WorkspaceCollectionName) `
			-ResourceGroupName $resourceGroup.ResourceGroupName `
			-Location $resourceGroup.Location

		try {
			Remove-AzPowerBIWorkspaceCollection `
				-WorkspaceCollectionName $newWorkspaceCollection.Name `
				-ResourceGroupName $resourceGroup.ResourceGroupName
		}
		catch {}

		Assert-ThrowsContains { Get-AzPowerBIWorkspaceCollection `
			-WorkspaceCollectionName $newWorkspaceCollection.Name `
			-ResourceGroupName $resourceGroup.ResourceGroupName } `
			"NotFound"
	}
	finally {
		Clean-ResourceGroup $resourceGroup.ResourceGroupName
	}
}