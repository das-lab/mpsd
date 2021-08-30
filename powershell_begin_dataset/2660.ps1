
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
	[switch]$DisableLogging = $false,
	[switch]$addComponentsOnly = $false, 
	[switch]$addInfoPath = $false, 
	[switch]$addOneNote = $false, 
	[switch]$addOutlook = $false, 
	[switch]$addPublisher = $false, 
	[switch]$addSharepointWorkspace = $false 
)

Try {
	
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	
	
	
	
	[string]$appVendor = 'Microsoft'
	[string]$appName = 'Office'
	[string]$appVersion = '2013 SP1'
	[string]$appArch = 'x86'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '3.6.8'
	[string]$appScriptDate = '11/22/2015'
	[string]$appScriptAuthor = 'Dan Cunningham'
	
	
	
	
	
	
	[int32]$mainExitCode = 0
	
	
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.5'
	[string]$deployAppScriptDate = '08/17/2015'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	
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
	
	
	
	
	
	
	
	
	[string] $dirOffice = Join-Path -Path "$envProgramFilesX86" -ChildPath 'Microsoft Office'
	
	If ($deploymentType -ine 'Uninstall') {
		
		
		
		[string]$installPhase = 'Pre-Installation'
		
		
		If ($addComponentsOnly) {
			
			If ((-not $addInfoPath) -and (-not $addSharepointWorkspace) -and (-not $addOneNote) -and (-not $addOutlook) -and (-not $addPublisher)) {
				Show-InstallationPrompt -Message 'No addon components were specified' -ButtonRightText 'OK' -Icon 'Error'
				Exit-Script -ExitCode 9
			}
			
			
			$officeVersion = Get-ItemProperty -LiteralPath 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-0011-0000-0000-0000000FF1CE}' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty DisplayName
			
			
			If (-not $officeVersion) {
				Show-InstallationPrompt -Message 'Unable to add the requested components as Office 2013 is not currently installed' -ButtonRightText 'OK' -Icon 'Error'
			}
		}
		
		
		Show-InstallationWelcome -CloseApps "excel,groove,onenote,infopath,onenote,outlook,mspub,powerpnt,winword,winproj,visio" -AllowDefer -DeferTimes 3 -CheckDiskSpace
		
		
		If (($addComponentsOnly) -or ($isServerOS)) {
			Write-Log -Message "Installation of components has been skipped as one of the following options are enabled. addComponentsOnly: $addComponentsOnly isServerOS: $isServerOS" -Source $deployAppScriptFriendlyName
		}
		Else {
			
			[string[]]$officeFolders = 'Office12', 'Office13', 'Office14', 'Office15'
			ForEach ($officeFolder in $officeFolders) {
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "$officeFolder\groove.exe") -PathType 'Leaf') {
					Write-Log -Message 'Sharepoint Workspace / Groove was previously installed. Will be reinstalled' -Source $deployAppScriptFriendlyName
					$addSharepointWorkspace = $true
				}
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "$officeFolder\infopath.exe") -PathType 'Leaf') {
					Write-Log -Message 'InfoPath was previously installed. Will be reinstalled' -Source $deployAppScriptFriendlyName
					$addInfoPath = $true
				}
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "$officeFolder\onenote.exe") -PathType 'Leaf') {
					Write-Log -Message 'OneNote was previously installed. Will be reinstalled' -Source $deployAppScriptFriendlyName
					$addOneNote = $true
				}
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "$officeFolder\outlook.exe") -PathType 'Leaf') {
					Write-Log -Message 'Outlook was previously installed. Will be reinstalled' -Source $deployAppScriptFriendlyName
					$addOutlook = $true
				}
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "$officeFolder\mspub.exe") -PathType 'Leaf') {
					Write-Log -Message 'Publisher was previously installed. Will be reinstalled' -Source $deployAppScriptFriendlyName
					$addPublisher = $true
				}
			}
			
			
			Show-InstallationProgress -StatusMessage 'Performing Pre-Install cleanup. This may take some time. Please wait...'
			
			
			[string[]]$officeExecutables = 'excel.exe', 'groove.exe', 'infopath.exe', 'onenote.exe', 'outlook.exe', 'mspub.exe', 'powerpnt.exe', 'winword.exe', 'winproj.exe', 'visio.exe'
			ForEach ($officeExecutable in $officeExecutables) {
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "Office12\$officeExecutable") -PathType 'Leaf') {
					Write-Log -Message 'Microsoft Office 2007 was detected. Will be uninstalled.' -Source $deployAppScriptFriendlyName
					Execute-Process -Path 'cscript.exe' -Parameters "`"$dirSupportFiles\OffScrub07.vbs`" ClientAll /S /Q /NoCancel" -WindowStyle Hidden -IgnoreExitCodes '1,2,3'
					Break
				}
			}
			ForEach ($officeExecutable in $officeExecutables) {
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "Office14\$officeExecutable") -PathType 'Leaf') {
					Write-Log -Message 'Microsoft Office 2010 was detected. Will be uninstalled.' -Source $deployAppScriptFriendlyName
					Execute-Process -Path "cscript.exe" -Parameters "`"$dirSupportFiles\OffScrub10.vbs`" ClientAll /S /Q /NoCancel" -WindowStyle Hidden -IgnoreExitCodes '1,2,3'
					Break
				}
			}
			ForEach ($officeExecutable in $officeExecutables) {
				If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath "Office15\$officeExecutable") -PathType 'Leaf') {
					Write-Log -Message 'Microsoft Office 2013 was detected. Will be uninstalled.' -Source $deployAppScriptFriendlyName
					Execute-Process -Path "cscript.exe" -Parameters "`"$dirSupportFiles\OffScrub13.vbs`" ClientAll /S /Q /NoCancel" -WindowStyle Hidden -IgnoreExitCodes '1,2,3'
					Break
				}
			}
		}
		
		
		
		
		
		[string]$installPhase = 'Installation'
		
		
		If (-not $addComponentsOnly) {
	  		Show-InstallationProgress -StatusMessage 'Installing Office Professional. This may take some time. Please wait...'
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/adminfile `"$dirFiles\Config\Office2013ProPlus.MSP`" /config `"$dirFiles\ProPlus.WW\Config.xml`"" -WindowStyle Hidden -IgnoreExitCodes '3010'
		}
		
		
		If ($addInfoPath) {
			Show-InstallationProgress -StatusMessage 'Installing Office Infopath. This may take some time. Please wait...'
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/modify ProPlus /config `"$dirSupportFiles\AddInfoPath.xml`"" -WindowStyle Hidden
		}
		
		
		If ($addSharepointWorkspace) {
			Show-InstallationProgress -StatusMessage 'Installing Office Sharepoint Workspace. This may take some time. Please wait...'
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/modify ProPlus /config `"$dirSupportFiles\AddSharePointWorkspace.xml`"" -WindowStyle Hidden
		}
		
		
		If ($addOneNote) {
			Show-InstallationProgress -StatusMessage "Installing Office OneNote. This may take some time. Please wait..."
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/modify ProPlus /config `"$dirSupportFiles\AddOneNote.xml`"" -WindowStyle Hidden
		}
		
		
		If ($addOutlook) {
			Show-InstallationProgress -StatusMessage 'Installing Office Outlook. This may take some time. Please wait...'
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/modify ProPlus /config `"$dirSupportFiles\AddOutlook.xml`"" -WindowStyle Hidden
		}
		
		
		If ($addPublisher) {
			Show-InstallationProgress -StatusMessage 'Installing Office Publisher. This may take some time. Please wait...'
			Execute-Process -Path "$dirFiles\Setup.exe" -Parameters "/modify ProPlus /config `"$dirSupportFiles\AddPublisher.xml`"" -WindowStyle Hidden
		}
		
		
		
		
		
		[string]$installPhase = 'Post-Installation'
		
		
		If ($CurrentLoggedOnUserSession -or $CurrentConsoleUserSession -or $RunAsActiveUser) {
			If (Test-Path -LiteralPath (Join-Path -Path $dirOffice -ChildPath 'Office15\OSPP.VBS') -PathType 'Leaf') {
				Show-InstallationProgress -StatusMessage 'Activating Microsoft Office components. This may take some time. Please wait...'
				Execute-Process -Path 'cscript.exe' -Parameters "`"$dirOffice\Office15\OSPP.VBS`" /ACT" -WindowStyle Hidden
			}
		}
		
		
		If ((-not $addComponentsOnly) -and ($deployMode -eq 'Interactive') -and (-not $IsServerOS)) {
			Show-InstallationRestartPrompt
		}
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		
		
		
		[string]$installPhase = 'Pre-Uninstallation'
		
		
		Show-InstallationWelcome -CloseApps 'excel,groove,infopath,onenote,outlook,mspub,powerpnt,winword,winproj,visio'
		
		
		Show-InstallationProgress
		
		
		
		
		
		[string]$installPhase = 'Uninstallation'
		
		Execute-Process -Path "cscript.exe" -Parameters "`"$dirSupportFiles\OffScrub13.vbs`" ClientAll /S /Q /NoCancel" -WindowStyle Hidden -IgnoreExitCodes '1,2,3'
		
		
		
		
		
		[string]$installPhase = 'Post-Uninstallation'
		
		
	}

	
	
	

	
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 1
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
