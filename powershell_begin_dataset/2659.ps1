
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
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	
	
	
	
	[string]$appVendor = 'PSAppDeployToolkit'
	[string]$appName = 'Test Script'
	[string]$appVersion = '1.0'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '3.6.8'
	[string]$appScriptDate = '02/06/2016'
	[string]$appScriptAuthor = 'Dan Cunningham'
	
	
	[string]$installName = ''
	[string]$installTitle = ''
	
	
	
	
	
	[int32]$mainExitCode = 0
	
	
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.8'
	[string]$deployAppScriptDate = '02/06/2016'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	If (-not (Test-Path -LiteralPath $scriptDirectory -PathType 'Leaf')) { [string]$scriptDirectory = Join-Path -Path (Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) -Parent) -ChildPath 'Toolkit' }
	
	
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	
	
	
	
	
	
	If ($deploymentType -ine 'Uninstall') {
		
		
		
		[string]$installPhase = 'Pre-Installation'
		
		
		Show-InstallationWelcome -AllowDefer -DeferTimes 100
		
		
		Show-InstallationWelcome -CloseApps 'iexplore,winword,excel,powerpnt' -CloseAppsCountdown 60 -CheckDiskSpace -PersistPrompt -BlockExecution
		
		
		
		
		
		[string]$installPhase = 'Installation'
		
		
		Show-InstallationProgress -StatusMessage 'BlockExecution Test: Open Internet Explorer or an Office application within 10 seconds...'
		Start-Sleep -Seconds 10
		
		
		Show-InstallationProgress -StatusMessage 'MSI Installation And Removal Test...'
		Execute-MSI -Action 'Install' -Path 'PSAppDeployToolkit_TestInstallation_1.0.0_EN_01.msi'
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
		
		
		
		
		
		[string]$installPhase = 'Post-Installation'
		
		
		Show-InstallationProgress -StatusMessage 'Execute Process Test: Close Notepad to proceed...'
		Execute-Process -Path 'Notepad'
		
		
		Show-InstallationPrompt -Message 'Asynchronous Installation Prompt Test: The installation should complete in the background. Click OK to dismiss...' -ButtonRightText 'OK' -Icon 'Information' -NoWait
		Start-Sleep -Seconds 10
		
		
		Remove-File -Path "$envProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk"
		
		
		Set-PinnedApplication -Action 'UnPinFromStartMenu' -FilePath "$envWinDir\Notepad.exe"
		Set-PinnedApplication -Action 'UnPinFromTaskBar' -FilePath "$envWinDir\Notepad.exe"
		
		

	}
	ElseIf ($deploymentType -ieq 'Uninstall') {
		
		
		
		[string]$installPhase = 'Pre-Uninstallation'
		
		
		Show-InstallationWelcome -CloseApps 'iexplore,winword,excel,powerpnt' -CloseAppsCountdown 60
		
		
		
		
		
		[string]$installPhase = 'Uninstallation'
		
		
		Show-InstallationProgress -StatusMessage 'MSI Uninstallation Test...'
		Execute-MSI -Action 'Uninstall' -Path 'PSAppDeployToolkit_TestInstallation_1.0.0_EN_01.msi'
		
		
		
		
		
		[string]$installPhase = 'Post-Uninstallation'
		
		
	}
	
	
	
	
	
	
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
