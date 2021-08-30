
[CmdletBinding()]
param ()
begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	
	function Get-LoggedOnUserSID {
		
		[CmdletBinding()]
		param ()
		process {
			try {
				if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
					New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null
				}
				(Get-ChildItem HKU: | where { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' }).PSChildName
			} catch {
				Write-Warning -Message "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			}
		}
	}
	
	function Set-RegistryValueForAllUsers {
	    
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[hashtable[]]$RegistryInstance,
			[switch]$Remove
		)
		begin {
			if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
				New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null
			}
		}
		process {
			try {
				
				$LoggedOnSids = Get-LoggedOnUserSID
				if ($LoggedOnSids -is [string]) {
					Write-Verbose -Message "Found 1 logged on user SID"
				} else {
					Write-Verbose -Message "Found $($LoggedOnSids.Count) logged on user SIDs"
				}
				foreach ($sid in $LoggedOnSids) {
					Write-Verbose -Message "Loading the user registry hive for the logged on SID $sid"
					foreach ($instance in $RegistryInstance) {
						if ($Remove.IsPresent) {
							Write-Verbose -Message "Removing registry key '$($instance.path)'"
							Remove-Item -Path "HKU:\$sid\$($instance.Path)" -Recurse -Force -ea 'SilentlyContinue'
						} else {
							if (!(Get-Item -Path "HKU:\$sid\$($instance.Path)" -ea 'SilentlyContinue')) {
								Write-Verbose -Message "The registry key HKU:\$sid\$($instance.Path) does not exist.  Creating..."
								New-Item -Path "HKU:\$sid\$($instance.Path | Split-Path -Parent)" -Name ($instance.Path | Split-Path -Leaf) -Force | Out-Null
							} else {
								Write-Verbose -Message "The registry key HKU:\$sid\$($instance.Path) already exists. No need to create."
							}
							Write-Verbose -Message "Setting registry value $($instance.Name) at path HKU:\$sid\$($instance.Path) to $($instance.Value)"
							
							Set-ItemProperty -Path "HKU:\$sid\$($instance.Path)" -Name $instance.Name -Value $instance.Value -Type $instance.Type -Force
						}
					}
				}
				
				foreach ($instance in $RegistryInstance) {
					if ($Remove.IsPresent) {
						if ($instance.Path.Split('\')[0] -eq 'SOFTWARE' -and ((Get-Architecture) -eq 'x64')) {
							$Split = $instance.Path.Split('\')
							$x86Path = "HKCU\SOFTWARE\Wow6432Node\{0}" -f ($Split[1..($Split.Length)] -join '\')
							$CommandLine = "reg delete `"{0}`" /f && reg delete `"{1}`" /f" -f "HKCU\$($instance.Path)", $x86Path
						} else {
							$CommandLine = "reg delete `"{0}`" /f" -f "HKCU\$($instance.Path)"
						}
					} else {
						
						switch ($instance.Type) {
							'String' {
								$RegValueType = 'REG_SZ'
							}
							'Dword' {
								$RegValueType = 'REG_DWORD'
							}
							'Binary' {
								$RegValueType = 'REG_BINARY'
							}
							'ExpandString' {
								$RegValueType = 'REG_EXPAND_SZ'
							}
							'MultiString' {
								$RegValueType = 'REG_MULTI_SZ'
							}
							default {
								throw "Registry type '$($instance.Type)' not recognized"
							}
						}
						if (!(Get-Item -Path "HKCU:\$($instance.Path)" -ea 'SilentlyContinue')) {
							Write-Verbose -Message "The registry key 'HKCU:\$($instance.Path)'' does not exist.  Creating..."
							New-Item -Path "HKCU:\$($instance.Path) | Split-Path -Parent)" -Name ("HKCU:\$($instance.Path)" | Split-Path -Leaf) -Force | Out-Null
						}
						if (-not $instance.Value) {
							$instance.Value = '""'
						}
						$CommandLine = "reg add `"{0}`" /v {1} /t {2} /d {3} /f" -f "HKCU\$($instance.Path)", $instance.Name, $RegValueType, $instance.Value
					}
					Set-AllUserStartupAction -CommandLine $CommandLine
				}
			} catch {
				Write-Warning -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
				$false
			}
		}
	}
	
	function Set-AllUserStartupAction {
	
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]$CommandLine
		)
		process {
			try {
				
				
				
				$Guid = [guid]::NewGuid().Guid
				Write-Verbose -Message "Created GUID '$Guid' to use for Active Setup"
				$ActiveSetupRegParentPath = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'
				New-Item -Path $ActiveSetupRegParentPath -Name $Guid -Force | Out-Null
				$ActiveSetupRegPath = "HKLM:\Software\Microsoft\Active Setup\Installed Components\$Guid"
				Write-Verbose -Message "Using registry path '$ActiveSetupRegPath'"
				Write-Verbose -Message "Setting command line registry value to '$CommandLine'"
				Set-ItemProperty -Path $ActiveSetupRegPath -Name '(Default)' -Value 'All Users Startup Action' -Force
				Set-ItemProperty -Path $ActiveSetupRegPath -Name 'Version' -Value '1' -Force
				Set-ItemProperty -Path $ActiveSetupRegPath -Name 'StubPath' -Value $CommandLine -Force
				Write-Verbose -Message 'Done'
			} catch {
				Write-Warning -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
				$false
			}
		}
	}
}

process {
	try {
		$Instance = @{
			'Name' = 'AutoConfigURL';
			'Type' = 'String';
			'Path' = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings';
			'Value' = ''
		}
		Set-RegistryValueForAllUsers -RegistryInstance $Instance
	} catch {
		Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}