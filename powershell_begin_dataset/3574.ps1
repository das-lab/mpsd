














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-Location
{
    return "West US"
}


function Get-OfferThroughput
{
    return 1000
}


function Get-Kind
{
    return "fhir-R4"
}


function Clean-ResourceGroup($rgname)
{
	Remove-AzResourceGroup -Name $rgname -Force
}


function Get-AccessPolicyObjectID
{
    return "9b52f7aa-85e9-47e2-8f10-af57e63a4ae1"
}
