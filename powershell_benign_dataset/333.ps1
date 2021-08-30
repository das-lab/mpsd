function Get-PSFPath
{

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Name
	)
	
	process
	{
		Get-PSFConfigValue -FullName "PSFramework.Path.$Name"
	}
}