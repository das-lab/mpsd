function Get-PSFRunspace
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFRunspace')]
	Param (
		[string]
		$Name = "*"
	)
	
	[PSFramework.Runspace.RunspaceHost]::Runspaces.Values | Where-Object Name -Like $Name
}