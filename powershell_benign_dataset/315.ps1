function Register-PSFSessionObjectType
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$DisplayName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TypeName
	)
	
	process
	{
		[PSFramework.ComputerManagement.ComputerManagementHost]::KnownSessionTypes[$TypeName] = $DisplayName
	}
}