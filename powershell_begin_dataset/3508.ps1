














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Clean-ResourceGroup($rgname)
{
	Remove-AzResourceGroup -Name $rgname -Force
}
