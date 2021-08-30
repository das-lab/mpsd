
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
