














function Clean-ResourceGroup($rgname)
{
	Remove-AzResourceGroup -Name $rgname -Force
}