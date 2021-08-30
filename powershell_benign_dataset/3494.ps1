














function Test-DefaultResourceGroup
{
	
	$rgname = Get-ResourceGroupName
	Clear-AzDefault -ResourceGroup

	try
	{
		
		$output = Get-AzDefault
		Assert-Null($output)
		$output = Get-AzDefault -ResourceGroup
		Assert-Null($output)
		$storedValue = (Get-AzContext).ExtendedProperties["Default Resource Group"]
		Assert-Null($storedValue)

		
		$output = Set-AzDefault -ResourceGroupName $rgname -Force
		$resourcegroup = Get-AzResourceGroup -Name $rgname
		Assert-AreEqual $output.Name $resourcegroup.ResourceGroupName
		$context = Get-AzContext
		$storedValue = $context.ExtendedProperties["Default Resource Group"]
		Assert-AreEqual $storedValue $output.Name

		
		$output = Get-AzDefault
		Assert-AreEqual $output.Name $resourceGroup.ResourceGroupName
		$output = Get-AzDefault -ResourceGroup
		Assert-AreEqual $output.Name $resourceGroup.ResourceGroupName

		
		Clear-AzDefault -Force
		$output = Get-AzDefault
		Assert-Null($output)
		$context = Get-AzContext
		$storedValue = $context.ExtendedProperties["Default Resource Group"]
		Assert-Null($storedValue)

		
		$output = Set-AzDefault -ResourceGroupName $rgname
		Assert-AreEqual $output.Name $resourcegroup.ResourceGroupName
		$context = Get-AzContext
		$storedValue = $context.ExtendedProperties["Default Resource Group"]
		Assert-AreEqual $storedValue $output.Name

		
		Clear-AzDefault -ResourceGroup
		$output = Get-AzDefault
		Assert-Null($output)
		$context = Get-AzContext
		$storedValue = $context.ExtendedProperties["Default Resource Group"]
		Assert-Null($storedValue)
	}
	finally
	{
		Clean-ResourceGroup($rgname)
	}
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Clean-ResourceGroup($rgname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}