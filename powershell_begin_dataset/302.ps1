function Stop-PSFRunspace
{

	[CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Stop-PSFRunspace')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RunspaceContainer[]]
		$Runspace,
		
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
				if ($PSCmdlet.ShouldProcess($item, "Stopping Runspace"))
				{
					try
					{
						Write-PSFMessage -Level Verbose -Message "Stopping runspace: <c='em'>$($item.ToLower())</c>" -Target $item.ToLower() -Tag "runspace", "stop"
						[PSFramework.Runspace.RunspaceHost]::Runspaces[$item.ToLower()].Stop()
					}
					catch
					{
						Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "stop" -Target $item.ToLower() -Continue -ErrorRecord $_
					}
				}
			}
			else
			{
				Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.ToLower())</c> | No runspace registered under this name!" -EnableException $EnableException -Category InvalidArgument -Tag "fail", "argument", "runspace", "stop" -Target $item.ToLower() -Continue
			}
		}
		
		foreach ($item in $Runspace)
		{
			if ($PSCmdlet.ShouldProcess($item.Name, "Stopping Runspace"))
			{
				try
				{
					Write-PSFMessage -Level Verbose -Message "Stopping runspace: <c='em'>$($item.Name.ToLower())</c>" -Target $item -Tag "runspace", "stop"
					$item.Stop()
				}
				catch
				{
					Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.Name.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "stop" -Target $item -Continue -ErrorRecord $_
				}
			}
		}
	}
}