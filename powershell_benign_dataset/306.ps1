function Register-PSFRunspace
{

	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFRunspace')]
	param
	(
		[Parameter(Mandatory = $true)]
		[Scriptblock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true)]
		[String]
		$Name,
		
		[switch]
		$NoMessage
	)
	
	if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($Name.ToLower()))
	{
		if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Updating runspace: <c='em'>$($Name.ToLower())</c>" -Target $Name.ToLower() -Tag 'runspace','register' }
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name.ToLower()].SetScript($ScriptBlock)
	}
	else
	{
		if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Registering runspace: <c='em'>$($Name.ToLower())</c>" -Target $Name.ToLower() -Tag 'runspace', 'register' }
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name.ToLower()] = New-Object PSFramework.Runspace.RunspaceContainer($Name.ToLower(), $ScriptBlock)
	}
}
