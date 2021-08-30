function Get-PSFFeature
{

	[CmdletBinding()]
	param (
		[string]
		$Name = "*"
	)
	
	process
	{
		[PSFramework.Feature.FeatureHost]::Features.Values | Where-Object Name -Like $Name
	}
}