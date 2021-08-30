function Start-PSFRunspace
{

	[CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Start-PSFRunspace')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RunspaceContainer[]]
		$Runspace,
		
		[switch]
		$NoMessage,
		
		[switch]
		$EnableException
	)
	
	process
	{
		foreach ($item in $Name)
		{
			
			if ($item -eq "psframework.runspace.runspacecontainer") { continue }
			
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($item.ToLower()))
			{
				if ($PSCmdlet.ShouldProcess($item, "Starting Runspace"))
				{
					try
					{
						if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.ToLower())</c>" -Target $item.ToLower() -Tag "runspace", "start" }
						[PSFramework.Runspace.RunspaceHost]::Runspaces[$item.ToLower()].Start()
					}
					catch
					{
						Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c>" -ErrorRecord $_ -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
					}
				}
			}
			else
			{
				Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c> | No runspace registered under this name!" -EnableException $EnableException -Category InvalidArgument -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
			}
		}
		
		foreach ($item in $Runspace)
		{
			if ($PSCmdlet.ShouldProcess($item.Name, "Starting Runspace"))
			{
				try
				{
					if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.Name.ToLower())</c>" -Target $item -Tag "runspace", "start" }
					$item.Start()
				}
				catch
				{
					Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.Name.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item -Continue
				}
			}
		}
	}
}