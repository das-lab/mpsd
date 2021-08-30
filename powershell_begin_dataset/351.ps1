function Test-PSFFeature
{

	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[PsfValidateSet(TabCompletion = 'PSFramework.Feature.Name')]
		[parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$ModuleName
	)
	
	begin
	{
		$featureItem = Get-PSFFeature -Name $Name
	}
	process
	{
		if (-not $featureItem.Global) { [PSFramework.Feature.FeatureHost]::ReadModuleFlag($Name, $ModuleName) }
		else { [PSFramework.Feature.FeatureHost]::ReadFlag($Name, $ModuleName) }
	}
}