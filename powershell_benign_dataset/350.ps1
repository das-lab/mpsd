function Set-PSFFeature
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidateSet(TabCompletion = 'PSFramework.Feature.Name')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[bool]
		$Value,
		
		[string]
		$ModuleName
	)
	process
	{
		foreach ($featureItem in $Name)
		{
			if ($ModuleName)
			{
				[PSFramework.Feature.FeatureHost]::WriteModuleFlag($ModuleName, $Name, $Value)
			}
			else
			{
				[PSFramework.Feature.FeatureHost]::WriteGlobalFlag($Name, $Value)
			}
		}
	}
}