function Reset-PSFConfig
{

	[CmdletBinding(DefaultParameterSetName = 'Pipeline', SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Reset-PSFConfig')]
	param (
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[PSFramework.Configuration.Config[]]
		$ConfigurationItem,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = 'Module')]
		[string]
		$Name = "*",
		
		[switch]
		$EnableException
	)
	
	process
	{
		
		foreach ($item in $ConfigurationItem)
		{
			if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -Action 'Reset to default value')
			{
				try { $item.ResetValue() }
				catch { Stop-PSFFunction -Message "Failed to reset the configuration item." -ErrorRecord $_ -Cmdlet $PSCmdlet -Continue }
			}
		}
		
		
		
		foreach ($nameItem in $FullName)
		{
			
			
			if ($nameItem -ceq "PSFramework.Configuration.Config") { continue }
			
			foreach ($item in (Get-PSFConfig -FullName $nameItem))
			{
				if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -Action 'Reset to default value')
				{
					try { $item.ResetValue() }
					catch { Stop-PSFFunction -Message "Failed to reset the configuration item." -ErrorRecord $_ -Cmdlet $PSCmdlet -Continue }
				}
			}
		}
		
		if ($Module)
		{
			foreach ($item in (Get-PSFConfig -Module $Module -Name $Name))
			{
				if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -Action 'Reset to default value')
				{
					try { $item.ResetValue() }
					catch { Stop-PSFFunction -Message "Failed to reset the configuration item." -ErrorRecord $_ -Cmdlet $PSCmdlet -Continue }
				}
			}
		}
	}
}