














function Get-ResourceGroupName
{
    return getAssetName
}



function Clean-ResourceGroup($rgname)
{
      Remove-AzResourceGroup -Name $rgname -Force
}


function Create-ResourceGroup
{
	$resourceGroupName = Get-ResourceGroupName
	return New-AzResourceGroup -Name $resourceGroupName -Location WestUS
}

