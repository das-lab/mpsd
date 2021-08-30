function Register-PSFConfig
{

	[CmdletBinding(DefaultParameterSetName = "Default", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFConfig')]
	Param (
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
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault",
		
		[switch]
		$EnableException
	)
	
	begin
	{
		if ($script:NoRegistry -and ($Scope -band 14))
		{
			Stop-PSFFunction -Message "Cannot register configurations on non-windows machines to registry. Please specify a file-based scope" -Tag 'NotSupported' -Category NotImplemented
			return
		}
		
		
		if ($script:NoRegistry -and ($Scope -eq "UserDefault"))
		{
			$Scope = [PSFramework.Configuration.ConfigScope]::FileUserLocal
		}
		
		if ($script:NoRegistry -and ($Scope -eq "SystemDefault"))
		{
			$Scope = [PSFramework.Configuration.ConfigScope]::FileSystem
		}
		
		$parSet = $PSCmdlet.ParameterSetName
		
		function Write-Config
		{
			[CmdletBinding()]
			Param (
				[PSFramework.Configuration.Config]
				$Config,
				
				[PSFramework.Configuration.ConfigScope]
				$Scope,
				
				[bool]
				$EnableException,
				
				[string]
				$FunctionName = (Get-PSCallStack)[0].Command
			)
			
			if (-not $Config -or ($Config.RegistryData -eq "<type not supported>"))
			{
				Stop-PSFFunction -Message "Invalid Input, cannot export $($Config.FullName), type not supported" -EnableException $EnableException -Category InvalidArgument -Tag "config", "fail" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
			
			try
			{
				Write-PSFMessage -Level Verbose -Message "Registering $($Config.FullName) for $Scope" -Tag "Config" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				
				if (1 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryUserDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				
				
				
				if (2 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryUserEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				
				
				
				if (4 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryMachineDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				
				
				
				if (8 -band $Scope)
				{
					Ensure-RegistryPath -Path $script:path_RegistryMachineEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				
			}
			catch
			{
				Stop-PSFFunction -Message "Failed to export $($Config.FullName), to scope $Scope" -EnableException $EnableException -Tag "config", "fail" -Target $Config -ErrorRecord $_ -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
		}
		
		function Ensure-RegistryPath
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
			[CmdletBinding()]
			Param (
				[string]
				$Path
			)
			
			if (-not (Test-Path $Path))
			{
				$null = New-Item $Path -Force
			}
		}
		
		
		$configurationItems = @()
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		
		if ($Scope -band 15)
		{
			switch ($parSet)
			{
				"Default"
				{
					foreach ($item in $Config)
					{
						Write-Config -Config $item -Scope $Scope -EnableException $EnableException
					}
					
					foreach ($item in $FullName)
					{
						if ([PSFramework.Configuration.ConfigurationHost]::Configurations.ContainsKey($item.ToLower()))
						{
							Write-Config -Config ([PSFramework.Configuration.ConfigurationHost]::Configurations[$item.ToLower()]) -Scope $Scope -EnableException $EnableException
						}
					}
				}
				"Name"
				{
					foreach ($item in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object Module -EQ $Module | Where-Object Name -Like $Name))
					{
						Write-Config -Config $item -Scope $Scope -EnableException $EnableException
					}
				}
			}
		}
		
		
		
		else
		{
			switch ($parSet)
			{
				"Default"
				{
					foreach ($item in $Config)
					{
						if ($configurationItems.FullName -notcontains $item.FullName) { $configurationItems += $item }
					}
					
					foreach ($item in $FullName)
					{
						if (($configurationItems.FullName -notcontains $item) -and ([PSFramework.Configuration.ConfigurationHost]::Configurations.ContainsKey($item.ToLower())))
						{
							$configurationItems += [PSFramework.Configuration.ConfigurationHost]::Configurations[$item.ToLower()]
						}
					}
				}
				"Name"
				{
					foreach ($item in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object Module -EQ $Module | Where-Object Name -Like $Name))
					{
						if ($configurationItems.FullName -notcontains $item.FullName) { $configurationItems += $item }
					}
				}
			}
		}
		
	}
	end
	{
		
		if ($Scope -band 16)
		{
			Write-PsfConfigFile -Config $configurationItems -Path (Join-Path $script:path_FileUserLocal "psf_config.json")
		}
		if ($Scope -band 32)
		{
			Write-PsfConfigFile -Config $configurationItems -Path (Join-Path $script:path_FileUserShared "psf_config.json")
		}
		if ($Scope -band 64)
		{
			Write-PsfConfigFile -Config $configurationItems -Path (Join-Path $script:path_FileSystem "psf_config.json")
		}
		
	}
}
