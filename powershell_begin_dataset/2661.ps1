
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
	
	
	
	
	
	[string]$appVendor = 'Adobe'
	[string]$appName = 'Reader'
	[string]$appVersion = '11.0.6'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '3.6.5'
	[string]$appScriptDate = '08/17/2015'
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
	
	
	
	
	
	
	
	If ($deploymentType -ine 'Uninstall') {
		
		
		
		[string]$installPhase = 'Pre-Installation'
		
		
	    Show-InstallationWelcome -CloseApps 'iexplore,AcroRd32,cidaemon' -AllowDefer -DeferTimes 3
	    
	    Show-InstallationProgress
	    
	    Remove-MSIApplications -Name 'Adobe Reader'
		
		
		
		
		
		[string]$installPhase = 'Installation'
		
		
	    Execute-MSI -Action Install -Path 'Adobe_Reader_11.0.0_EN.msi' -Transform 'Adobe_Reader_11.0.0_EN_01.mst'
	    
	    Execute-MSI -Action Patch -Path 'Adobe_Reader_11.0.6_EN.msp'
		
		
		
		
		
		[string]$installPhase = 'Post-Installation'
		
		
		
		
		Show-InstallationPrompt -Message 'You can customise text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		
		
		
		[string]$installPhase = 'Pre-Uninstallation'
		
		
	    Show-InstallationWelcome -CloseApps 'iexplore,AcroRd32,cidaemon' -AllowDefer -DeferTimes 3
		
		
	    Show-InstallationProgress -StatusMessage 'Uninstalling application [$installTitle]. Please Wait...'
		
		
		
		
		
		[string]$installPhase = 'Uninstallation'
		
	    
	    Execute-MSI -Action Uninstall -Path '{AC76BA86-7AD7-1033-7B44-AB0000000001}'
		
		
		
		
		
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
