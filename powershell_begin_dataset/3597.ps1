














function Get-TestResourceGroupName
{
	"myService1"
}


function Extract-ResourceLocation{
param(
	[string]$ResourceId
)
	$match = [Regex]::Match($ResourceId, "locations/(.*?)/")

	return $match.Captures.Groups[1].Value
}


function Extract-ResourceGroup{
param(
	[string]$ResourceId
)
	$match = [Regex]::Match($ResourceId, "resourceGroups/(.*?)/")

	return $match.Captures.Groups[1].Value
}