function Register-PSFFeature
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$Description,
		
		[switch]
		$NotGlobal,
		
		[switch]
		$NotModuleSpecific,
		
		[string]
		$Owner = (Get-PSCallStack)[1].InvocationInfo.MyCommand.ModuleName
	)
	
	begin
	{
		$featureObject = New-Object PSFramework.Feature.FeatureItem -Property @{
			Name = $Name
			Owner = $Owner
			Global = (-not $NotGlobal)
			ModuleSpecific = (-not $NotModuleSpecific)
			Description = $Description
		}
	}
	process
	{
		[PSFramework.Feature.FeatureHost]::Features[$Name] = $featureObject
	}
}