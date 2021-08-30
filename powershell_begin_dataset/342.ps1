function Unregister-PSFConfig
{

	[CmdletBinding(DefaultParameterSetName = 'Pipeline', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Unregister-PSFConfig')]
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
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault"
	)
	
	begin
	{
		if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*") -and ($Scope -band 15))
		{
			Stop-PSFFunction -Message "Cannot unregister configurations from registry on non-windows machines." -Tag 'NotSupported' -Category ResourceUnavailable
			return
		}
		
		
		$registryProperties = @()
		if ($Scope -band 1)
		{
			if (Test-Path $script:path_RegistryUserDefault) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryUserDefault }
		}
		if ($Scope -band 2)
		{
			if (Test-Path $script:path_RegistryUserEnforced) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryUserEnforced }
		}
		if ($Scope -band 4)
		{
			if (Test-Path $script:path_RegistryMachineDefault) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryMachineDefault }
		}
		if ($Scope -band 8)
		{
			if (Test-Path $script:path_RegistryMachineEnforced) { $registryProperties += Get-ItemProperty -Path $script:path_RegistryMachineEnforced }
		}
		$pathProperties = @()
		if ($Scope -band 16)
		{
			$fileUserLocalSettings = @()
			if (Test-Path (Join-Path $script:path_FileUserLocal "psf_config.json")) { $fileUserLocalSettings = Get-Content (Join-Path $script:path_FileUserLocal "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileUserLocalSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileUserLocal "psf_config.json")
					Properties = $fileUserLocalSettings
					Changed    = $false
				}
			}
		}
		if ($Scope -band 32)
		{
			$fileUserSharedSettings = @()
			if (Test-Path (Join-Path $script:path_FileUserShared "psf_config.json")) { $fileUserSharedSettings = Get-Content (Join-Path $script:path_FileUserShared "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileUserSharedSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileUserShared "psf_config.json")
					Properties = $fileUserSharedSettings
					Changed    = $false
				}
			}
		}
		if ($Scope -band 64)
		{
			$fileSystemSettings = @()
			if (Test-Path (Join-Path $script:path_FileSystem "psf_config.json")) { $fileSystemSettings = Get-Content (Join-Path $script:path_FileSystem "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
			if ($fileSystemSettings)
			{
				$pathProperties += [pscustomobject]@{
					Path	   = (Join-Path $script:path_FileSystem "psf_config.json")
					Properties = $fileSystemSettings
					Changed    = $false
				}
			}
		}
		
		
		$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not ($pathProperties -or $registryProperties)) { return }
		
		foreach ($item in $ConfigurationItem)
		{
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -eq $item.FullName }))
			{
				Remove-ItemProperty -Path $hive.PSPath -Name $item.FullName
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -contains $item.FullName }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NE $item.FullName
				$fileConfig.Changed = $true
			}
		}
		
		foreach ($item in $FullName)
		{
			
			if ($item -ceq "PSFramework.Configuration.Config") { continue }
			
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -eq $item }))
			{
				Remove-ItemProperty -Path $hive.PSPath -Name $item
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -contains $item }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NE $item
				$fileConfig.Changed = $true
			}
		}
		
		if ($Module)
		{
			$compoundName = "{0}.{1}" -f $Module, $Name
			
			
			foreach ($hive in ($registryProperties | Where-Object { $_.PSObject.Properties.Name -like $compoundName }))
			{
				foreach ($propName in $hive.PSObject.Properties.Name)
				{
					if ($propName -in $common) { continue }
					
					if ($propName -like $compoundName)
					{
						Remove-ItemProperty -Path $hive.PSPath -Name $propName
					}
				}
			}
			
			foreach ($fileConfig in ($pathProperties | Where-Object { $_.Properties.FullName -like $compoundName }))
			{
				$fileConfig.Properties = $fileConfig.Properties | Where-Object FullName -NotLike $compoundName
				$fileConfig.Changed = $true
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($fileConfig in $pathProperties)
		{
			if (-not $fileConfig.Changed) { continue }
			
			if ($fileConfig.Properties)
			{
				$fileConfig.Properties | ConvertTo-Json | Set-Content -Path $fileConfig.Path -Encoding UTF8
			}
			else
			{
				Remove-Item $fileConfig.Path
			}
		}
	}
}
