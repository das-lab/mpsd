function Remove-PSFConfig
{

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Name", Position = 1)]
		[string]
		$Name = "*"
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			"Default"
			{
				
				foreach ($item in $Config)
				{
					if (-not (Test-PSFShouldProcess -ActionString 'PSFramework.Configuration.Remove-PSFConfig.ShouldRemove' -Target $item.FullName)) { continue }
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($item.FullName) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $item.FullName -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				
				if (Test-PSFParameterBinding -ParameterName Config) { break }
				
				
				
				foreach ($nameItem in $FullName)
				{
					if (-not (Test-PSFShouldProcess -ActionString 'PSFramework.Configuration.Remove-PSFConfig.ShouldRemove' -Target $nameItem)) { continue }
					$item = Get-PSFConfig -FullName $nameItem
					
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($nameItem) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $nameItem -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				
			}
			"Name"
			{
				
				foreach ($item in (Get-PSFConfig -Module $Module -Name $Name))
				{
					if (-not (Test-PSFShouldProcess -ActionString 'PSFramework.Configuration.Remove-PSFConfig.ShouldRemove' -Target $item.FullName)) { continue }
					
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($item.FullName) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $item.FullName -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				
			}
		}
	}
}