
[CmdletBinding()]
Param
(
	
	[switch]$ShowInstallationPrompt = $false,
	[switch]$ShowInstallationRestartPrompt = $false,
	[switch]$CleanupBlockedApps = $false,
	[switch]$ShowBlockedAppDialog = $false,
	[switch]$DisableLogging = $false,
	[string]$ReferringApplication = '',
	[string]$Message = '',
	[string]$MessageAlignment = '',
	[string]$ButtonRightText = '',
	[string]$ButtonLeftText = '',
	[string]$ButtonMiddleText = '',
	[string]$Icon = '',
	[string]$Timeout = '',
	[switch]$ExitOnTimeout = $false,
	[boolean]$MinimizeWindows = $false,
	[switch]$PersistPrompt = $false,
	[int32]$CountdownSeconds,
	[int32]$CountdownNoHideSeconds,
	[switch]$NoCountdown = $false,
	[switch]$RelaunchToolkitAsUser = $false
)







[string]$appDeployToolkitName = 'PSAppDeployToolkit'
[string]$appDeployMainScriptFriendlyName = 'App Deploy Toolkit Main'


[version]$appDeployMainScriptVersion = [version]'3.6.0'
[version]$appDeployMainScriptMinimumConfigVersion = [version]'3.6.0'
[string]$appDeployMainScriptDate = '12/18/2014'
[hashtable]$appDeployMainScriptParameters = $PSBoundParameters


[string]$currentTime = (Get-Date -UFormat '%T').ToString()
[string]$currentDate = (Get-Date -UFormat '%d-%m-%Y').ToString()
[timespan]$currentTimeZoneBias = [System.TimeZone]::CurrentTimeZone.GetUtcOffset([datetime]::Now)
[Globalization.CultureInfo]$culture = Get-Culture
[string]$currentLanguage = $culture.TwoLetterISOLanguageName.ToUpper()


[psobject]$envHost = $Host
[string]$envAllUsersProfile = $env:ALLUSERSPROFILE
[string]$envAppData = $env:APPDATA
[string]$envArchitecture = $env:PROCESSOR_ARCHITECTURE
[string]$envCommonProgramFiles = $env:CommonProgramFiles
[string]$envCommonProgramFilesX86 = ${env:CommonProgramFiles(x86)}
[string]$envComputerName = $env:COMPUTERNAME | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
[string]$envComputerNameFQDN = ([System.Net.Dns]::GetHostEntry('')).HostName
[string]$envHomeDrive = $env:HOMEDRIVE
[string]$envHomePath = $env:HOMEPATH
[string]$envHomeShare = $env:HOMESHARE
[string]$envLocalAppData = $env:LOCALAPPDATA
[string]$envProgramFiles = $env:PROGRAMFILES
[string]$envProgramFilesX86 = ${env:ProgramFiles(x86)}
[string]$envProgramData = $env:PROGRAMDATA
[string]$envPublic = $env:PUBLIC
[string]$envSystemDrive = $env:SYSTEMDRIVE
[string]$envSystemRoot = $env:SYSTEMROOT
[string]$envTemp = $env:TEMP
[string]$envUserName = $env:USERNAME
[string]$envUserProfile = $env:USERPROFILE
[string]$envWinDir = $env:WINDIR

If (-not $envCommonProgramFilesX86) { [string]$envCommonProgramFilesX86 = $env:CommonProgramFiles }
If (-not $envProgramFilesX86) { [string]$envProgramFilesX86 = $env:PROGRAMFILES }


[boolean]$IsMachinePartOfDomain = (Get-WmiObject Win32_ComputerSystem -ErrorAction 'SilentlyContinue').PartOfDomain
[string]$envMachineWorkgroup = ''
[string]$envMachineADDomain = ''
[string]$envLogonServer = ''
[string]$MachineDomainController = ''
If ($IsMachinePartOfDomain) {
	[string]$envMachineADDomain = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction 'SilentlyContinue').Domain | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
	Try {
		[string]$envLogonServer = $env:LOGONSERVER | Where-Object { (($_) -and (-not $_.Contains('\\MicrosoftAccount'))) } | ForEach-Object { $_.TrimStart('\') } | ForEach-Object { ([System.Net.Dns]::GetHostEntry($_)).HostName }
		[string]$MachineDomainController = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().FindDomainController().Name
	}
	Catch { }
}
Else {
	[string]$envMachineWorkgroup = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction 'SilentlyContinue').Domain | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
}
[string]$envMachineDNSDomain = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
[string]$envUserDNSDomain = $env:USERDNSDOMAIN | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
[string]$envUserDomain = $env:USERDOMAIN | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }


[psobject]$envOS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction 'SilentlyContinue'
[string]$envOSName = $envOS.Caption.Trim()
[string]$envOSServicePack = $envOS.CSDVersion
[version]$envOSVersion = [System.Environment]::OSVersion.Version
[string]$envOSVersionMajor = $envOSVersion.Major
[string]$envOSVersionMinor = $envOSVersion.Minor
[string]$envOSVersionBuild = $envOSVersion.Build
[string]$envOSVersionRevision = $envOSVersion.Revision
[string]$envOSVersion = $envOSVersion.ToString()

[int32]$envOSProductType = $envOS.ProductType
[boolean]$IsServerOS = [boolean]($envOSProductType -eq 3)
[boolean]$IsDomainControllerOS = [boolean]($envOSProductType -eq 2)
[boolean]$IsWorkStationOS = [boolean]($envOSProductType -eq 1)
Switch ($envOSProductType) {
	3 { [string]$envOSProductTypeName = 'Server' }
	2 { [string]$envOSProductTypeName = 'Domain Controller' }
	1 { [string]$envOSProductTypeName = 'Workstation' }
	Default { [string]$envOSProductTypeName = 'Unknown' }
}

[boolean]$Is64Bit = [boolean]((Get-WmiObject -Class Win32_Processor | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty AddressWidth) -eq '64')
If ($Is64Bit) { [string]$envOSArchitecture = '64-bit' } Else { [string]$envOSArchitecture = '32-bit' }


[boolean]$Is64BitProcess = [boolean]([System.IntPtr]::Size -eq 8)
If ($Is64BitProcess) { [string]$psArchitecture = 'x64' } Else { [string]$psArchitecture = 'x86' }


[hashtable]$envPSVersionTable = $PSVersionTable

[version]$envPSVersion = $envPSVersionTable.PSVersion
[string]$envPSVersionMajor = $envPSVersion.Major
[string]$envPSVersionMinor = $envPSVersion.Minor
[string]$envPSVersionBuild = $envPSVersion.Build
[string]$envPSVersionRevision = $envPSVersion.Revision
[string]$envPSVersion = $envPSVersion.ToString()

[version]$envCLRVersion = $envPSVersionTable.CLRVersion
[string]$envCLRVersionMajor = $envCLRVersion.Major
[string]$envCLRVersionMinor = $envCLRVersion.Minor
[string]$envCLRVersionBuild = $envCLRVersion.Build
[string]$envCLRVersionRevision = $envCLRVersion.Revision
[string]$envCLRVersion = $envCLRVersion.ToString()


[System.Security.Principal.WindowsIdentity]$CurrentProcessToken = [System.Security.Principal.WindowsIdentity]::GetCurrent()
[System.Security.Principal.SecurityIdentifier]$CurrentProcessSID = $CurrentProcessToken.User
[string]$ProcessNTAccount = $CurrentProcessToken.Name
[string]$ProcessNTAccountSID = $CurrentProcessSID.Value
[boolean]$IsAdmin = [boolean]($CurrentProcessToken.Groups -contains [System.Security.Principal.SecurityIdentifier]'S-1-5-32-544')
[boolean]$IsLocalSystemAccount = $CurrentProcessSID.IsWellKnown([System.Security.Principal.WellKnownSidType]'LocalSystemSid')
[boolean]$IsLocalServiceAccount = $CurrentProcessSID.IsWellKnown([System.Security.Principal.WellKnownSidType]'LocalServiceSid')
[boolean]$IsNetworkServiceAccount = $CurrentProcessSID.IsWellKnown([System.Security.Principal.WellKnownSidType]'NetworkServiceSid')
[boolean]$IsServiceAccount = [boolean]($CurrentProcessToken.Groups -contains [System.Security.Principal.SecurityIdentifier]'S-1-5-6')
[boolean]$IsProcessUserInteractive = [System.Environment]::UserInteractive
[string]$LocalSystemNTAccount = (New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList ([Security.Principal.WellKnownSidType]::'LocalSystemSid', $null)).Translate([System.Security.Principal.NTAccount]).Value

If ($IsLocalSystemAccount -or $IsLocalServiceAccount -or $IsNetworkServiceAccount -or $IsServiceAccount) { $SessionZero = $true } Else { $SessionZero = $false }


[int32]$dpiPixels = Get-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty LogPixels -ErrorAction 'SilentlyContinue'
Switch ($dpiPixels) {
	96 { [int32]$dpiScale = 100 }
	120 { [int32]$dpiScale = 125 }
	144 { [int32]$dpiScale = 150 }
	192 { [int32]$dpiScale = 200 }
	Default { [int32]$dpiScale = 100 }
}


[string]$scriptPath = $MyInvocation.MyCommand.Definition
[string]$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
[string]$scriptFileName = Split-Path -Path $scriptPath -Leaf
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$invokingScript = (Get-Variable -Name MyInvocation).Value.ScriptName

If ($invokingScript) {
	
	[string]$scriptParentPath = Split-Path -Path $invokingScript -Parent
}
Else {
	
	[string]$scriptParentPath = (Get-Item -Path $scriptRoot).Parent.FullName
}


[string]$appDeployLogoIcon = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitLogo.ico'
[string]$appDeployLogoBanner = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitBanner.png'
[string]$appDeployConfigFile = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitConfig.xml'

[string]$appDeployToolkitDotSourceExtensions = 'AppDeployToolkitExtensions.ps1'

If (-not (Test-Path -Path $AppDeployLogoIcon -PathType Leaf)) { Throw 'App Deploy logo icon file not found.' }
If (-not (Test-Path -Path $AppDeployLogoBanner -PathType Leaf)) { Throw 'App Deploy logo banner file not found.' }
If (-not (Test-Path -Path $AppDeployConfigFile -PathType Leaf)) { Throw 'App Deploy XML configuration file not found.' }


[xml]$xmlConfigFile = Get-Content -Path $AppDeployConfigFile
$xmlConfig = $xmlConfigFile.AppDeployToolkit_Config

$configConfigDetails = $xmlConfig.Config_File
[string]$configConfigVersion = [version]$configConfigDetails.Config_Version
[string]$configConfigDate = $configConfigDetails.Config_Date

$xmlToolkitOptions = $xmlConfig.Toolkit_Options
[boolean]$configToolkitRequireAdmin = [boolean]::Parse($xmlToolkitOptions.Toolkit_RequireAdmin)
[boolean]$configToolkitAllowSystemInteraction = [boolean]::Parse($xmlToolkitOptions.Toolkit_AllowSystemInteraction)
[boolean]$configToolkitAllowSystemInteractionFallback = [boolean]::Parse($xmlToolkitOptions.Toolkit_AllowSystemInteractionFallback)
[boolean]$configToolkitAllowSystemInteractionForNonConsoleUser = [boolean]::Parse($xmlToolkitOptions.Toolkit_AllowSystemInteractionForNonConsoleUser)
[string]$configToolkitTempPath = $ExecutionContext.InvokeCommand.ExpandString($xmlToolkitOptions.Toolkit_TempPath)
[string]$configToolkitRegPath = $xmlToolkitOptions.Toolkit_RegPath
[string]$configToolkitLogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlToolkitOptions.Toolkit_LogPath)
[boolean]$configToolkitCompressLogs = [boolean]::Parse($xmlToolkitOptions.Toolkit_CompressLogs)
[string]$configToolkitLogStyle = $xmlToolkitOptions.Toolkit_LogStyle
[double]$configToolkitLogMaxSize = $xmlToolkitOptions.Toolkit_LogMaxSize
[boolean]$configToolkitLogWriteToHost = [boolean]::Parse($xmlToolkitOptions.Toolkit_LogWriteToHost)
[boolean]$configToolkitLogDebugMessage = [boolean]::Parse($xmlToolkitOptions.Toolkit_LogDebugMessage)

$xmlConfigMSIOptions = $xmlConfig.MSI_Options
[string]$configMSILoggingOptions = $xmlConfigMSIOptions.MSI_LoggingOptions
[string]$configMSIInstallParams = $xmlConfigMSIOptions.MSI_InstallParams
[string]$configMSISilentParams = $xmlConfigMSIOptions.MSI_SilentParams
[string]$configMSIUninstallParams = $xmlConfigMSIOptions.MSI_UninstallParams
[string]$configMSILogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigMSIOptions.MSI_LogPath)
[int32]$configMSIMutexWaitTime = $xmlConfigMSIOptions.MSI_MutexWaitTime

$xmlConfigUIOptions = $xmlConfig.UI_Options
[boolean]$configShowBalloonNotifications = [boolean]::Parse($xmlConfigUIOptions.ShowBalloonNotifications)
[int32]$configInstallationUITimeout = $xmlConfigUIOptions.InstallationUI_Timeout
[int32]$configInstallationUIExitCode = $xmlConfigUIOptions.InstallationUI_ExitCode
[int32]$configInstallationDeferExitCode = $xmlConfigUIOptions.InstallationDefer_ExitCode
[int32]$configInstallationPersistInterval = $xmlConfigUIOptions.InstallationPrompt_PersistInterval
[int32]$configInstallationRestartPersistInterval = $xmlConfigUIOptions.InstallationRestartPrompt_PersistInterval

[string]$xmlUIMessageLanguage = "UI_Messages_$currentLanguage"
If (-not ($xmlConfig.$xmlUIMessageLanguage)) { [string]$xmlUIMessageLanguage = 'UI_Messages_EN' }
$xmlUIMessages = $xmlConfig.$xmlUIMessageLanguage
[string]$configDiskSpaceMessage = $xmlUIMessages.DiskSpace_Message
[string]$configBalloonTextStart = $xmlUIMessages.BalloonText_Start
[string]$configBalloonTextComplete = $xmlUIMessages.BalloonText_Complete
[string]$configBalloonTextRestartRequired = $xmlUIMessages.BalloonText_RestartRequired
[string]$configBalloonTextFastRetry = $xmlUIMessages.BalloonText_FastRetry
[string]$configBalloonTextError = $xmlUIMessages.BalloonText_Error
[string]$configProgressMessageInstall = $xmlUIMessages.Progress_MessageInstall
[string]$configProgressMessageUninstall = $xmlUIMessages.Progress_MessageUninstall
[string]$configClosePromptMessage = $xmlUIMessages.ClosePrompt_Message
[string]$configClosePromptButtonClose = $xmlUIMessages.ClosePrompt_ButtonClose
[string]$configClosePromptButtonDefer = $xmlUIMessages.ClosePrompt_ButtonDefer
[string]$configClosePromptButtonContinue = $xmlUIMessages.ClosePrompt_ButtonContinue
[string]$configClosePromptCountdownMessage = $xmlUIMessages.ClosePrompt_CountdownMessage
[string]$configDeferPromptWelcomeMessage = $xmlUIMessages.DeferPrompt_WelcomeMessage
[string]$configDeferPromptExpiryMessage = $xmlUIMessages.DeferPrompt_ExpiryMessage
[string]$configDeferPromptWarningMessage = $xmlUIMessages.DeferPrompt_WarningMessage
[string]$configDeferPromptRemainingDeferrals = $xmlUIMessages.DeferPrompt_RemainingDeferrals
[string]$configDeferPromptDeadline = $xmlUIMessages.DeferPrompt_Deadline
[string]$configBlockExecutionMessage = $xmlUIMessages.BlockExecution_Message
[string]$configDeploymentTypeInstall = $xmlUIMessages.DeploymentType_Install
[string]$configDeploymentTypeUnInstall = $xmlUIMessages.DeploymentType_UnInstall
[string]$configRestartPromptTitle = $xmlUIMessages.RestartPrompt_Title
[string]$configRestartPromptMessage = $xmlUIMessages.RestartPrompt_Message
[string]$configRestartPromptMessageTime = $xmlUIMessages.RestartPrompt_MessageTime
[string]$configRestartPromptMessageRestart = $xmlUIMessages.RestartPrompt_MessageRestart
[string]$configRestartPromptTimeRemaining = $xmlUIMessages.RestartPrompt_TimeRemaining
[string]$configRestartPromptButtonRestartLater = $xmlUIMessages.RestartPrompt_ButtonRestartLater
[string]$configRestartPromptButtonRestartNow = $xmlUIMessages.RestartPrompt_ButtonRestartNow


[string]$dirFiles = Join-Path -Path $scriptParentPath -ChildPath 'Files'
[string]$dirSupportFiles = Join-Path -Path $scriptParentPath -ChildPath 'SupportFiles'
[string]$dirAppDeployTemp = Join-Path -Path $configToolkitTempPath -ChildPath $appDeployToolkitName


If (-not $appVendor) { [string]$appVendor = 'PS' }
If (-not $appName) { [string]$appName = $appDeployMainScriptFriendlyName }
If (-not $appVersion) { [string]$appVersion = $appDeployMainScriptVersion }
If (-not $appLang) { [string]$appLang = $currentLanguage }
If (-not $appRevision) { [string]$appRevision = '01' }
If (-not $appArch) { [string]$appArch = '' }
[string]$installTitle = "$appVendor $appName $appVersion"


[char[]]$invalidFileNameChars = [System.IO.Path]::GetInvalidFileNamechars()
[string]$appVendor = $appVendor -replace "[$invalidFileNameChars]",'' -replace ' ',''
[string]$appName = $appName -replace "[$invalidFileNameChars]",'' -replace ' ',''
[string]$appVersion = $appVersion -replace "[$invalidFileNameChars]",'' -replace ' ',''
[string]$appArch = $appArch -replace "[$invalidFileNameChars]",'' -replace ' ',''
[string]$appLang = $appLang -replace "[$invalidFileNameChars]",'' -replace ' ',''
[string]$appRevision = $appRevision -replace "[$invalidFileNameChars]",'' -replace ' ',''


If ($appArch) {
	[string]$installName = $appVendor + '_' + $appName + '_' + $appVersion + '_' + $appArch + '_' + $appLang + '_' + $appRevision
}
Else {
	[string]$installName = $appVendor + '_' + $appName + '_' + $appVersion + '_' + $appLang + '_' + $appRevision
}
[string]$installName = $installName.Trim('_') -replace '[_]+','_'


If (-not $deploymentType) { [string]$deploymentType = 'Install' }


[string]$exeWusa = 'wusa.exe' 
[string]$exeMsiexec = 'msiexec.exe' 
[string]$exeSchTasks = "$envWinDir\System32\schtasks.exe" 


[string]$MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'



[string[]]$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
If ($is64Bit) {
	[string]$regKeyLotusNotes = 'HKLM:SOFTWARE\Wow6432Node\Lotus\Notes'
}
Else {
	[string]$regKeyLotusNotes = 'HKLM:SOFTWARE\Lotus\Notes'
}
[string]$regKeyAppExecution = 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
[string]$regKeyDeferHistory = "$configToolkitRegPath\$appDeployToolkitName\DeferHistory\$installName"


[__comobject]$Shell = New-Object -ComObject WScript.Shell -ErrorAction 'SilentlyContinue'
[__comobject]$ShellApp = New-Object -ComObject Shell.Application -ErrorAction 'SilentlyContinue'


[boolean]$msiRebootDetected = $false
[boolean]$BlockExecution = $false
[boolean]$installationStarted = $false
[boolean]$runningTaskSequence = $false
If (Test-Path -Path 'variable:welcomeTimer') { Remove-Variable -Name welcomeTimer -Scope Script}

If (Test-Path -Path 'variable:deferHistory') { Remove-Variable -Name deferHistory }
If (Test-Path -Path 'variable:deferTimes') { Remove-Variable -Name deferTimes }
If (Test-Path -Path 'variable:deferDays') { Remove-Variable -Name deferDays }


[string]$logName = $installName + '_' + $appDeployToolkitName + '_' + $deploymentType + '.log'
[string]$logTempFolder = Join-Path -Path $envTemp -ChildPath $installName
If ($configToolkitCompressLogs) {
	
	
	[string]$logDirectory = $logTempFolder
	
	[string]$zipFileDate = (Get-Date -Format 'yyyy-MM-dd-hh-mm-ss').ToString()
	[string]$zipFileName = Join-Path -Path $configToolkitLogDir -ChildPath ($installName + '_' + $deploymentType + '_' + $zipFileDate + '.zip')
	
	
	If (Test-Path -Path $logTempFolder -PathType Container -ErrorAction 'SilentlyContinue') {
		Remove-Item -Path $logTempFolder -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
	}
}
Else {
	
	[string]$logDirectory = $configToolkitLogDir
}












Function Write-FunctionHeaderOrFooter {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$CmdletName,
		[Parameter(Mandatory=$true,ParameterSetName='Header')]
		[AllowEmptyCollection()]
		[hashtable]$CmdletBoundParameters,
		[Parameter(Mandatory=$true,ParameterSetName='Header')]
		[switch]$Header,
		[Parameter(Mandatory=$true,ParameterSetName='Footer')]
		[switch]$Footer
	)
	
	If ($Header) {
		Write-Log -Message 'Function Start' -Source ${CmdletName} -DebugMessage
		
		
		[string]$CmdletBoundParameters = $CmdletBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
		If ($CmdletBoundParameters) {
			Write-Log -Message "Function invoked with bound parameter(s): `n$CmdletBoundParameters" -Source ${CmdletName} -DebugMessage
		}
		Else {
			Write-Log -Message 'Function invoked without any bound parameters' -Source ${CmdletName} -DebugMessage
		}
	}
	ElseIf ($Footer) {
		Write-Log -Message 'Function End' -Source ${CmdletName} -DebugMessage
	}
}




Function Write-Log {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyCollection()]
		[string[]]$Message,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateRange(1,3)]
		[int16]$Severity = 1,
		[Parameter(Mandatory=$false,Position=2)]
		[ValidateNotNull()]
		[string]$Source = '',
		[Parameter(Mandatory=$false,Position=3)]
		[ValidateNotNullorEmpty()]
		[string]$ScriptSection = $script:installPhase,
		[Parameter(Mandatory=$false,Position=4)]
		[ValidateSet('CMTrace','Legacy')]
		[string]$LogType = $configToolkitLogStyle,
		[Parameter(Mandatory=$false,Position=5)]
		[ValidateNotNullorEmpty()]
		[string]$LogFileDirectory = $logDirectory,
		[Parameter(Mandatory=$false,Position=6)]
		[ValidateNotNullorEmpty()]
		[string]$LogFileName = $logName,
		[Parameter(Mandatory=$false,Position=7)]
		[ValidateNotNullorEmpty()]
		[decimal]$MaxLogFileSizeMB = $configToolkitLogMaxSize,
		[Parameter(Mandatory=$false,Position=8)]
		[ValidateNotNullorEmpty()]
		[boolean]$WriteHost = $configToolkitLogWriteToHost,
		[Parameter(Mandatory=$false,Position=9)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true,
		[Parameter(Mandatory=$false,Position=10)]
		[switch]$PassThru = $false,
		[Parameter(Mandatory=$false,Position=11)]
		[switch]$DebugMessage = $false,
		[Parameter(Mandatory=$false,Position=12)]
		[boolean]$LogDebugMessage = $configToolkitLogDebugMessage,
		[Parameter(Mandatory=$false,Position=13)]
		[switch]$DisableOnRelaunchToolkitAsUser = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

		
		[string]$LogTime = (Get-Date -Format HH:mm:ss.fff).ToString()
		[string]$LogDate = (Get-Date -Format MM-dd-yyyy).ToString()
		If (-not (Test-Path -Path 'variable:LogTimeZoneBias')) { [int32]$script:LogTimeZoneBias = [System.TimeZone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes }
		[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
		[boolean]$ExitLoggingFunction = $false

		
		If ($DisableOnRelaunchToolkitAsUser -and $RelaunchToolkitAsUser) { [boolean]$ExitLoggingFunction = $true; Return }

		
		If (($DebugMessage) -and (-not $LogDebugMessage)) { [boolean]$ExitLoggingFunction = $true; Return }
		
		
		If (-not (Test-Path -Path $LogFileDirectory -PathType Container)) {
			Try {
				New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop' | Out-Null
			}
			Catch {
				[boolean]$ExitLoggingFunction = $true
				
				If (-not $ContinueOnError) {
					Write-Host "[$LogDate $LogTime] [${CmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `n$(Resolve-Error)" -ForegroundColor 'Red'
				}
				Return
			}
		}

		
		If ($script:MyInvocation.Value.ScriptName) { [string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf } Else { [string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf }
		
		
		[boolean]$ScriptSectionDefined = [boolean](-not [string]::IsNullOrEmpty($ScriptSection))
		
		
		If (-not (Test-Path -Path 'variable:DisableLogging')) { $DisableLogging = $false }
		
		
		[scriptblock]$CMTraceLogString = {
			Param (
				[string]$lMessage,
				[string]$lSource,
				[int16]$lSeverity
			)
			"<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
		}
		
		
		[scriptblock]$WriteLogLineToHost = {
			Param (
				[string]$lTextLogLine,
				[int16]$lSeverity
			)
			If ($WriteHost) {
				
				If ($Host.UI.RawUI.ForegroundColor) {
					Switch ($lSeverity) {
						3 { Write-Host $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black' }
						2 { Write-Host $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black' }
						1 { Write-Host $lTextLogLine }
					}
				}
				
				Else {
					Write-Output $lTextLogLine
				}
			}
		}
		
		
		[string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
	}
	Process {
		
		If ($ExitLoggingFunction) { Return }
		
		ForEach ($Msg in $Message) {
			
			[string]$CMTraceMsg = ''
			[string]$ConsoleLogLine = ''
			[string]$LegacyTextLogLine = ''
			If ($Msg) {
				
				If ($ScriptSectionDefined) { [string]$CMTraceMsg = "[$ScriptSection] :: $Msg" }
				
				
				[string]$LegacyMsg = "[$LogDate $LogTime]"
				If ($ScriptSectionDefined) { [string]$LegacyMsg += " [$ScriptSection]" }
				If ($Source) {
					[string]$ConsoleLogLine = "$LegacyMsg [$Source] :: $Msg"
					Switch ($Severity) {
						3 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Error] :: $Msg" }
						2 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Warning] :: $Msg" }
						1 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Info] :: $Msg" }
					}
				}
				Else {
					[string]$ConsoleLogLine = "$LegacyMsg :: $Msg"
					Switch ($Severity) {
						3 { [string]$LegacyTextLogLine = "$LegacyMsg [Error] :: $Msg" }
						2 { [string]$LegacyTextLogLine = "$LegacyMsg [Warning] :: $Msg" }
						1 { [string]$LegacyTextLogLine = "$LegacyMsg [Info] :: $Msg" }
					}
				}
			}
			
			
			[string]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lSource $Source -lSeverity $Severity
			
			
			If ($LogType -ieq 'CMTrace') {
				[string]$LogLine = $CMTraceLogLine
			}
			Else {
				[string]$LogLine = $LegacyTextLogLine
			}
			
			
			If (-not $DisableLogging) {
				Try {
					$LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
				}
				Catch {
					If (-not $ContinueOnError) {
						Write-Host "[$LogDate $LogTime] [$ScriptSection] [${CmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `n$(Resolve-Error)" -ForegroundColor 'Red'
					}
				}
			}
			
			
			& $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
		}
	}
	End {
		
		Try {
			If (-not $ExitLoggingFunction) {
				[System.IO.FileInfo]$LogFile = Get-ChildItem -Path $LogFilePath -ErrorAction 'Stop'
				[decimal]$LogFileSizeMB = $LogFile.Length/1MB
				If (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
					
					[string]$ArchivedOutLogFile = [System.IO.Path]::ChangeExtension($LogFilePath, 'lo_')
					[hashtable]$ArchiveLogParams = @{ ScriptSection = $ScriptSection; Source = ${CmdletName}; Severity = 2; LogFileDirectory = $LogFileDirectory; LogFileName = $LogFilePath; LogType = $LogType; MaxLogFileSizeMB = 0; WriteHost = $WriteHost; ContinueOnError = $ContinueOnError; PassThru = $false }
					
					
					$ArchiveLogMessage = "Maximum log file size [$MaxLogFileSizeMB MB] reached. Rename log file to [$ArchivedOutLogFile]."
					Write-Log -Message $ArchiveLogMessage @ArchiveLogParams
					
					
					Move-Item -Path $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'
					
					
					$NewLogMessage = "Previous log file was renamed to [$ArchivedOutLogFile] because maximum log file size of [$MaxLogFileSizeMB MB] was reached."
					Write-Log -Message $NewLogMessage @ArchiveLogParams
				}
			}
		}
		Catch {
			
		}
		Finally {
			If ($PassThru) { Write-Output $Message }
		}
	}
}




Function Exit-Script {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$ExitCode = 0
	)
	
	
	[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	
	
	If ($formCloseApps) { $formCloseApps.Close }
	
	
	
	If (Test-Path -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -PathType 'Leaf') {
		[string]$StatusMessage = '_CloseRunspace'
		$StatusMessage | Export-Clixml -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -Force
	}
	Start-Sleep -Seconds 5
	Close-InstallationProgress
	
	
	If (($BlockExecution) -and (-not $RelaunchToolkitAsUser)) { Unblock-AppExecution }
	
	
	If (($terminalServerMode) -and (-not $RelaunchToolkitAsUser)) { Disable-TerminalServerInstallMode }
	
	
	Switch ($exitCode) {
		$configInstallationUIExitCode { $installSuccess = $false }
		$configInstallationDeferExitCode { $installSuccess = $false }
		3010 { $installSuccess = $true }
		1641 { $installSuccess = $true }
		0 { $installSuccess = $true }
		Default { $installSuccess = $false }
	}
	
	
	If ($deployModeSilent) { [boolean]$configShowBalloonNotifications = $false }
	
	If ($installSuccess) {
		If (Test-Path -Path $regKeyDeferHistory -ErrorAction 'SilentlyContinue') {
			Write-Log -Message 'Remove deferral history...' -Source ${CmdletName}
			Remove-RegistryKey -Key $regKeyDeferHistory
		}
		
		[string]$balloonText = "$deploymentTypeName $configBalloonTextComplete"
		
		If (($msiRebootDetected) -and ($AllowRebootPassThru)) {
			Write-Log -Message 'A restart has been flagged as required.' -Source ${CmdletName}
			[string]$balloonText = "$deploymentTypeName $configBalloonTextRestartRequired"
			[int32]$exitCode = 3010
		}
		Else {
			[int32]$exitCode = 0
		}
		
		Write-Log -Message "$installName $deploymentTypeName completed with exit code [$exitcode]." -Source ${CmdletName}
		If ($configShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Info' -BalloonTipText $balloonText }
	}
	ElseIf (-not $installSuccess) {
		Write-Log -Message "$installName $deploymentTypeName completed with exit code [$exitcode]." -Source ${CmdletName}
		If (($exitCode -eq $configInstallationUIExitCode) -or ($exitCode -eq $configInstallationDeferExitCode)) {
			[string]$balloonText = "$deploymentTypeName $configBalloonTextFastRetry"
			If ($configShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Warning' -BalloonTipText $balloonText }
		}
		Else {
			[string]$balloonText = "$deploymentTypeName $configBalloonTextError"
			If ($configShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Error' -BalloonTipText $balloonText }
		}
	}
	
	[string]$LogDash = '-' * 79
	Write-Log -Message $LogDash -Source ${CmdletName}
	
	
	If (($configToolkitCompressLogs) -and (-not $RelaunchToolkitAsUser)) {
		Try {
			
			Set-Content -Path $zipFileName -Value ('PK' + [char]5 + [char]6 + ("$([char]0)" * 18)) -ErrorAction 'Stop'
			
			$zipFile = $shellApp.NameSpace($zipFileName)
			ForEach ($file in (Get-ChildItem -Path $logTempFolder -ErrorAction 'Stop')) {
				Write-Log -Message "Compress log file [$($file.Name)] to [$zipFileName]..." -Source ${CmdletName}
				$zipFile.CopyHere($file.FullName)
				Start-Sleep -Milliseconds 500
			}
			
			If (Test-Path -Path $logTempFolder -PathType Container -ErrorAction 'Stop') {
				Remove-Item -Path $logTempFolder -Recurse -Force -ErrorAction 'Stop' | Out-Null
			}
		}
		Catch {
			Write-Log -Message "Failed to compress the log file(s). `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	
	
	Exit $exitCode
}




Function Resolve-Error {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyCollection()]
		[array]$ErrorRecord,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
		[string[]]$Property = ('Message','InnerException','FullyQualifiedErrorId','ScriptStackTrace','PositionMessage'),
		[Parameter(Mandatory=$false,Position=2)]
		[switch]$GetErrorRecord = $true,
		[Parameter(Mandatory=$false,Position=3)]
		[switch]$GetErrorInvocation = $true,
		[Parameter(Mandatory=$false,Position=4)]
		[switch]$GetErrorException = $true,
		[Parameter(Mandatory=$false,Position=5)]
		[switch]$GetErrorInnerException = $true
	)
	
	Begin {
		
		If (-not $ErrorRecord) {
			If ($global:Error.Count -eq 0) {
				
				Return
			}
			Else {
				[array]$ErrorRecord = $global:Error[0]
			}
		}
		
		
		[scriptblock]$SelectProperty = {
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				$InputObject,
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string[]]$Property
			)
			
			[string[]]$ObjectProperty = $InputObject | Get-Member -MemberType *Property | Select-Object -ExpandProperty Name
			ForEach ($Prop in $Property) {
				If ($Prop -eq '*') {
					[string[]]$PropertySelection = $ObjectProperty
					Break
				}
				ElseIf ($ObjectProperty -contains $Prop) {
					[string[]]$PropertySelection += $Prop
				}
			}
			Write-Output $PropertySelection
		}
		
		
		$LogErrorRecordMsg = $null
		$LogErrorInvocationMsg = $null
		$LogErrorExceptionMsg = $null
		$LogErrorMessageTmp = $null
		$LogInnerMessage = $null
	}
	Process {
		If (-not $ErrorRecord) { Return }
		ForEach ($ErrRecord in $ErrorRecord) {
			
			If ($GetErrorRecord) {
				[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord -Property $Property
				$LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
			}
			
			
			If ($GetErrorInvocation) {
				If ($ErrRecord.InvocationInfo) {
					[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
					$LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
				}
			}
			
			
			If ($GetErrorException) {
				If ($ErrRecord.Exception) {
					[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.Exception -Property $Property
					$LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
				}
			}
			
			
			If ($Property -eq '*') {
				
				If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
				If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
				If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
			}
			Else {
				
				If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
				If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
				If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
			}
			
			If ($LogErrorMessageTmp) {
				$LogErrorMessage = 'Error Record:'
				$LogErrorMessage += "`n-------------"
				$LogErrorMsg = $LogErrorMessageTmp | Format-List | Out-String
				$LogErrorMessage += $LogErrorMsg
			}
			
			
			If ($GetErrorInnerException) {
				If ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException) {
					$LogInnerMessage = 'Error Inner Exception(s):'
					$LogInnerMessage += "`n-------------------------"
					
					$ErrorInnerException = $ErrRecord.Exception.InnerException
					$Count = 0
					
					While ($ErrorInnerException) {
						[string]$InnerExceptionSeperator = '~' * 40
						
						[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrorInnerException -Property $Property
						$LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String
						
						If ($Count -gt 0) { $LogInnerMessage += $InnerExceptionSeperator }
						$LogInnerMessage += $LogErrorInnerExceptionMsg
						
						$Count++
						$ErrorInnerException = $ErrorInnerException.InnerException
					}
				}
			}
			
			If ($LogErrorMessage) { $Output = $LogErrorMessage }
			If ($LogInnerMessage) { $Output += $LogInnerMessage }
			
			Write-Output $Output
			
			If (Test-Path -Path 'variable:Output') { Clear-Variable -Name Output }
			If (Test-Path -Path 'variable:LogErrorMessage') { Clear-Variable -Name LogErrorMessage }
			If (Test-Path -Path 'variable:LogInnerMessage') { Clear-Variable -Name LogInnerMessage }
			If (Test-Path -Path 'variable:LogErrorMessageTmp') { Clear-Variable -Name LogErrorMessageTmp }
		}
	}
	End {
	}
}




Function Show-InstallationPrompt {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Title = $installTitle,
		[Parameter(Mandatory=$false)]
		[string]$Message = '',
		[Parameter(Mandatory=$false)]
		[ValidateSet('Left','Center','Right')]
		[string]$MessageAlignment = 'Center',
		[Parameter(Mandatory=$false)]
		[string]$ButtonRightText = '',
		[Parameter(Mandatory=$false)]
		[string]$ButtonLeftText = '',
		[Parameter(Mandatory=$false)]
		[string]$ButtonMiddleText = '',
		[Parameter(Mandatory=$false)]
		[ValidateSet('Application','Asterisk','Error','Exclamation','Hand','Information','None','Question','Shield','Warning','WinLogo')]
		[string]$Icon = 'None',
		[Parameter(Mandatory=$false)]
		[switch]$NoWait = $false,
		[Parameter(Mandatory=$false)]
		[switch]$PersistPrompt = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$MinimizeWindows = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$Timeout = $configInstallationUITimeout,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ExitOnTimeout = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) {
			Write-Log -Message "Bypassing Installation Prompt [Mode: $deployMode]... $Message" -Source ${CmdletName}
			Return
		}

		
		If (-not $IsProcessUserInteractive) {
			$ShowInstallPromptResult = Invoke-PSCommandAsUser -PassThru -Command ([scriptblock]::Create("Show-InstallationPrompt -Title '$Title' -Message '$Message' -MessageAlignment '$MessageAlignment' -ButtonRightText '$ButtonRightText' -ButtonLeftText '$ButtonLeftText' -ButtonMiddleText '$ButtonMiddleText' -Icon '$Icon' -NoWait:`$$NoWait -PersistPrompt:`$$PersistPrompt -MinimizeWindows `$$MinimizeWindows -Timeout $Timeout -ExitOnTimeout `$$ExitOnTimeout"))
			If ($ShowInstallPromptResult) {
				Return $ShowInstallPromptResult
			}
			Else {
				Return
			}
		}

		
		[hashtable]$installPromptParameters = $psBoundParameters
		
		
		If ($timeout -gt $configInstallationUITimeout) {
			[string]$CountdownTimeoutErr = "The installation UI dialog timeout cannot be longer than the timeout specified in the XML configuration file."
			Write-Log -Message $CountdownTimeoutErr -Severity 3 -Source ${CmdletName}
			Throw $CountdownTimeoutErr
		}
		
		[System.Windows.Forms.Application]::EnableVisualStyles()
		$formInstallationPrompt = New-Object -TypeName System.Windows.Forms.Form
		$pictureBanner = New-Object -TypeName System.Windows.Forms.PictureBox
		$pictureIcon = New-Object -TypeName System.Windows.Forms.PictureBox
		$labelText = New-Object -TypeName System.Windows.Forms.Label
		$buttonRight = New-Object -TypeName System.Windows.Forms.Button
		$buttonMiddle = New-Object -TypeName System.Windows.Forms.Button
		$buttonLeft = New-Object -TypeName System.Windows.Forms.Button
		$buttonAbort = New-Object -TypeName System.Windows.Forms.Button
		$InitialFormInstallationPromptWindowState = New-Object -TypeName System.Windows.Forms.FormWindowState
		
		[scriptblock]$Form_Cleanup_FormClosed = {
			
			Try {
				$labelText.remove_Click($handler_labelText_Click)
				$buttonLeft.remove_Click($buttonLeft_OnClick)
				$buttonRight.remove_Click($buttonRight_OnClick)
				$buttonMiddle.remove_Click($buttonMiddle_OnClick)
				$buttonAbort.remove_Click($buttonAbort_OnClick)
				$timer.remove_Tick($timer_Tick)
				$timer.dispose()
				$timer = $null
				$timerPersist.remove_Tick($timerPersist_Tick)
				$timerPersist.dispose()
				$timerPersist = $null
				$formInstallationPrompt.remove_Load($Form_StateCorrection_Load)
				$formInstallationPrompt.remove_FormClosed($Form_Cleanup_FormClosed)
			}
			Catch { }
		}
		
		[scriptblock]$Form_StateCorrection_Load = {
			
			$formInstallationPrompt.WindowState = 'Normal'
			$formInstallationPrompt.AutoSize = $true
			$formInstallationPrompt.TopMost = $true
			$formInstallationPrompt.BringToFront()
			
			Set-Variable -Name formInstallationPromptStartPosition -Value $formInstallationPrompt.Location -Scope Script
		}
		
		
		$formInstallationPrompt.Controls.Add($pictureBanner)
		
		
		
		$paddingNone = New-Object -TypeName System.Windows.Forms.Padding
		$paddingNone.Top = 0
		$paddingNone.Bottom = 0
		$paddingNone.Left = 0
		$paddingNone.Right = 0
		
		
		$labelPadding = '20,0,20,0'
		
		
		$buttonWidth = 110
		$buttonHeight = 23
		$buttonPadding = 50
		$buttonSize = New-Object -TypeName System.Drawing.Size
		$buttonSize.Width = $buttonWidth
		$buttonSize.Height = $buttonHeight
		$buttonPadding = New-Object -TypeName System.Windows.Forms.Padding
		$buttonPadding.Top = 0
		$buttonPadding.Bottom = 5
		$buttonPadding.Left = 50
		$buttonPadding.Right = 0
		
		
		$pictureBanner.DataBindings.DefaultDataSourceUpdateMode = 0
		$pictureBanner.ImageLocation = $appDeployLogoBanner
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 0
		$System_Drawing_Point.Y = 0
		$pictureBanner.Location = $System_Drawing_Point
		$pictureBanner.Name = 'pictureBanner'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 50
		$System_Drawing_Size.Width = 450
		$pictureBanner.Size = $System_Drawing_Size
		$pictureBanner.SizeMode = 'CenterImage'
		$pictureBanner.Margin = $paddingNone
		$pictureBanner.TabIndex = 0
		$pictureBanner.TabStop = $false
		
		
		$pictureIcon.DataBindings.DefaultDataSourceUpdateMode = 0
		If ($icon -ne 'None') { $pictureIcon.Image = ([System.Drawing.SystemIcons]::$Icon).ToBitmap() }
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 15
		$System_Drawing_Point.Y = 105
		$pictureIcon.Location = $System_Drawing_Point
		$pictureIcon.Name = 'pictureIcon'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 32
		$System_Drawing_Size.Width = 32
		$pictureIcon.Size = $System_Drawing_Size
		$pictureIcon.AutoSize = $true
		$pictureIcon.Margin = $paddingNone
		$pictureIcon.TabIndex = 0
		$pictureIcon.TabStop = $false
		
		
		$labelText.DataBindings.DefaultDataSourceUpdateMode = 0
		$labelText.Name = 'labelText'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 148
		$System_Drawing_Size.Width = 385
		$labelText.Size = $System_Drawing_Size
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 25
		$System_Drawing_Point.Y = 50
		$labelText.Location = $System_Drawing_Point
		$labelText.Margin = '0,0,0,0'
		$labelText.Padding = $labelPadding
		$labelText.TabIndex = 1
		$labelText.Text = $message
		$labelText.TextAlign = "Middle$($MessageAlignment)"
		$labelText.Anchor = 'Top'
		$labelText.add_Click($handler_labelText_Click)
		
		
		$buttonLeft.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonLeft.Location = '15,200'
		$buttonLeft.Name = 'buttonLeft'
		$buttonLeft.Size = $buttonSize
		$buttonLeft.TabIndex = 5
		$buttonLeft.Text = $buttonLeftText
		$buttonLeft.DialogResult = 'No'
		$buttonLeft.AutoSize = $false
		$buttonLeft.UseVisualStyleBackColor = $true
		$buttonLeft.add_Click($buttonLeft_OnClick)
		
		
		$buttonMiddle.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonMiddle.Location = '170,200'
		$buttonMiddle.Name = 'buttonMiddle'
		$buttonMiddle.Size = $buttonSize
		$buttonMiddle.TabIndex = 6
		$buttonMiddle.Text = $buttonMiddleText
		$buttonMiddle.DialogResult = 'Ignore'
		$buttonMiddle.AutoSize = $true
		$buttonMiddle.UseVisualStyleBackColor = $true
		$buttonMiddle.add_Click($buttonMiddle_OnClick)
		
		
		$buttonRight.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonRight.Location = '325,200'
		$buttonRight.Name = 'buttonRight'
		$buttonRight.Size = $buttonSize
		$buttonRight.TabIndex = 7
		$buttonRight.Text = $ButtonRightText
		$buttonRight.DialogResult = 'Yes'
		$buttonRight.AutoSize = $true
		$buttonRight.UseVisualStyleBackColor = $true
		$buttonRight.add_Click($buttonRight_OnClick)
		
		
		$buttonAbort.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonAbort.Name = 'buttonAbort'
		$buttonAbort.Size = '1,1'
		$buttonAbort.DialogResult = 'Abort'
		$buttonAbort.TabIndex = 5
		$buttonAbort.UseVisualStyleBackColor = $true
		$buttonAbort.add_Click($buttonAbort_OnClick)
		
		
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 270
		$System_Drawing_Size.Width = 450
		$formInstallationPrompt.Size = $System_Drawing_Size
		$formInstallationPrompt.Padding = '0,0,0,10'
		$formInstallationPrompt.Margin = $paddingNone
		$formInstallationPrompt.DataBindings.DefaultDataSourceUpdateMode = 0
		$formInstallationPrompt.Name = 'WelcomeForm'
		$formInstallationPrompt.Text = $title
		$formInstallationPrompt.StartPosition = 'CenterScreen'
		$formInstallationPrompt.FormBorderStyle = 'FixedDialog'
		$formInstallationPrompt.MaximizeBox = $false
		$formInstallationPrompt.MinimizeBox = $false
		$formInstallationPrompt.TopMost = $true
		$formInstallationPrompt.TopLevel = $true
		$formInstallationPrompt.Icon = New-Object -TypeName System.Drawing.Icon -ArgumentList $AppDeployLogoIcon
		$formInstallationPrompt.Controls.Add($pictureBanner)
		$formInstallationPrompt.Controls.Add($pictureIcon)
		$formInstallationPrompt.Controls.Add($labelText)
		$formInstallationPrompt.Controls.Add($buttonAbort)
		If ($buttonLeftText) { $formInstallationPrompt.Controls.Add($buttonLeft) }
		If ($buttonMiddleText) { $formInstallationPrompt.Controls.Add($buttonMiddle) }
		If ($buttonRightText) { $formInstallationPrompt.Controls.Add($buttonRight) }
		
		
		$timer = New-Object -TypeName System.Windows.Forms.Timer
		$timer.Interval = ($timeout * 1000)
		$timer.Add_Tick({
			Write-Log -Message 'Installation action not taken within a reasonable amount of time.' -Source ${CmdletName}
			$buttonAbort.PerformClick()
		})
		
		
		If ($persistPrompt) {
			$timerPersist = New-Object -TypeName System.Windows.Forms.Timer
			$timerPersist.Interval = ($configInstallationPersistInterval * 1000)
			[scriptblock]$timerPersist_Tick = { Refresh-InstallationPrompt }
			$timerPersist.add_Tick($timerPersist_Tick)
			$timerPersist.Start()
		}
		
		
		$InitialFormInstallationPromptWindowState = $formInstallationPrompt.WindowState
		
		$formInstallationPrompt.add_Load($Form_StateCorrection_Load)
		
		$formInstallationPrompt.add_FormClosed($Form_Cleanup_FormClosed)
		
		
		$timer.Start()
		
		Function Refresh-InstallationPrompt {
			$formInstallationPrompt.BringToFront()
			$formInstallationPrompt.Location = "$($formInstallationPromptStartPosition.X),$($formInstallationPromptStartPosition.Y)"
			$formInstallationPrompt.Refresh()
		}
		
		
		Close-InstallationProgress
		
		[string]$installPromptLoggedParameters = ($installPromptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' '
		Write-Log -Message "Displaying custom installation prompt with the non-default parameters: [$installPromptLoggedParameters]..." -Source ${CmdletName}
		
		
		If ($NoWait) {
			
			$installPromptParameters.Remove('NoWait')
			
			[string]$installPromptParameters = ($installPromptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' '
			Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -Command `"$scriptPath`" -ReferringApplication `"$installName`" -ShowInstallationPrompt $installPromptParameters" -WindowStyle Hidden -ErrorAction 'SilentlyContinue'
		}
		
		Else {
			$showDialog = $true
			While ($showDialog) {
				
				If ($minimizeWindows) { $shellApp.MinimizeAll() | Out-Null }
				
				$result = $formInstallationPrompt.ShowDialog()
				If (($result -eq 'Yes') -or ($result -eq 'No') -or ($result -eq 'Ignore') -or ($result -eq 'Abort')) {
					$showDialog = $false
				}
			}
			$formInstallationPrompt.Dispose()
			Switch ($result) {
				'Yes' { Write-Output $buttonRightText }
				'No' { Write-Output $buttonLeftText }
				'Ignore' { Write-Output $buttonMiddleText }
				'Abort' {
					
					$shellApp.UndoMinimizeAll() | Out-Null
					If ($ExitOnTimeout) {
						Exit-Script -ExitCode $configInstallationUIExitCode
					}
					Else {
						Write-Log -Message "UI timed out but `$ExitOnTimeout set to `$false. Continue..." -Source ${CmdletName}
					}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-DialogBox {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,HelpMessage='Enter a message for the dialog box')]
		[ValidateNotNullorEmpty()]
		[string]$Text,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Title = $installTitle,
		[Parameter(Mandatory=$false)]
		[ValidateSet('OK','OKCancel','AbortRetryIgnore','YesNoCancel','YesNo','RetryCancel','CancelTryAgainContinue')]
		[string]$Buttons = 'OK',
		[Parameter(Mandatory=$false)]
		[ValidateSet('First','Second','Third')]
		[string]$DefaultButton = 'First',
		[Parameter(Mandatory=$false)]
		[ValidateSet('Exclamation','Information','None','Stop','Question')]
		[string]$Icon = 'None',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Timeout = $configInstallationUITimeout,
		[Parameter(Mandatory=$false)]
		[switch]$TopMost = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) {
			Write-Log -Message "Bypassing Dialog Box [Mode: $deployMode]: $Text..." -Source ${CmdletName}
			Return
		}
		
		
		If (-not $IsProcessUserInteractive) {
			[string]$DialogBoxResponse = Invoke-PSCommandAsUser -PassThru -Command ([scriptblock]::Create("Show-DialogBox -Text '$Test' -Title '$Title' -Buttons '$Buttons' -DefaultButton '$DefaultButton' -Icon '$Icon' -Timeout '$Timeout' -Topmost:`$$Topmost"))
			Return $DialogBoxResponse
		}
		
		Write-Log -Message "Display Dialog Box with message: $Text..." -Source ${CmdletName}
		
		[hashtable]$dialogButtons = @{
			'OK' = 0
			'OKCancel' = 1
			'AbortRetryIgnore' = 2
			'YesNoCancel' = 3
			'YesNo' = 4
			'RetryCancel' = 5
			'CancelTryAgainContinue' = 6
		}
		
		[hashtable]$dialogIcons = @{
			'None' = 0
			'Stop' = 16
			'Question' = 32
			'Exclamation' = 48
			'Information' = 64
		}
		
		[hashtable]$dialogDefaultButton = @{
			'First' = 0
			'Second' = 256
			'Third' = 512
		}
		
		Switch ($TopMost) {
			$true { $dialogTopMost = 4096 }
			$false { $dialogTopMost = 0 }
		}
		
		$response = $Shell.Popup($Text, $Timeout, $Title, ($dialogButtons[$Buttons] + $dialogIcons[$Icon] + $dialogDefaultButton[$DefaultButton] + $dialogTopMost))
		
		Switch ($response) {
			1 {
				Write-Log -Message 'Dialog Box Response: OK' -Source ${CmdletName}
				Write-Output 'OK'
			}
			2 {
				Write-Log -Message 'Dialog Box Response: Cancel' -Source ${CmdletName}
				Write-Output 'Cancel'
			}
			3 {
				Write-Log -Message 'Dialog Box Response: Abort' -Source ${CmdletName}
				Write-Output 'Abort'
			}
			4 {
				Write-Log -Message 'Dialog Box Response: Retry' -Source ${CmdletName}
				Write-Output 'Retry'
			}
			5 {
				Write-Log -Message 'Dialog Box Response: Ignore' -Source ${CmdletName}
				Write-Output 'Ignore'
			}
			6 {
				Write-Log -Message 'Dialog Box Response: Yes' -Source ${CmdletName}
				Write-Output 'Yes'
			}
			7 {
				Write-Log -Message 'Dialog Box Response: No' -Source ${CmdletName}
				Write-Output 'No'
			}
			10 {
				Write-Log -Message 'Dialog Box Response: Try Again' -Source ${CmdletName}
				Write-Output 'Try Again'
			}
			11 {
				Write-Log -Message 'Dialog Box Response: Continue' -Source ${CmdletName}
				Write-Output 'Continue'
			}
			-1 {
				Write-Log -Message 'Dialog Box Timed Out...' -Source ${CmdletName}
				Write-Output 'Timeout'
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-HardwarePlatform {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Retrieve hardware platform information.' -Source ${CmdletName}
			$hwBios = Get-WmiObject -Class Win32_BIOS -ErrorAction 'Stop' | Select-Object -Property Version, SerialNnumber
			$hwMakeModel = Get-WMIObject -Class Win32_ComputerSystem -ErrorAction 'Stop' | Select-Object -Property Model, Manufacturer
			
			If ($hwBIOS.Version -match 'VRTUAL') { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwBIOS.Version -match 'A M I') { $hwType = 'Virtual:Virtual PC' }
			ElseIf ($hwBIOS.Version -like '*Xen*') { $hwType = 'Virtual:Xen' }
			ElseIf ($hwBIOS.SerialNumber -like '*VMware*') { $hwType = 'Virtual:VMWare' }
			ElseIf ($hwMakeModel.Manufacturer -like '*Microsoft*') { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwMakeModel.Manufacturer -like '*VMWare*') { $hwType = 'Virtual:VMWare' }
			ElseIf ($hwMakeModel.Model -like '*Virtual*') { $hwType = 'Virtual' }
			Else { $hwType = 'Physical' }
			
			Write-Output $hwType
		}
		Catch {
			Write-Log -Message "Failed to retrieve hardware platform information. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve hardware platform information: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-FreeDiskSpace {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Drive = $envSystemDrive,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Retrieve free disk space for drive [$Drive]." -Source ${CmdletName}
			$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$Drive'" -ErrorAction 'Stop'
			[double]$freeDiskSpace = [math]::Round($disk.FreeSpace / 1MB)

			Write-Log -Message "Free disk space for drive [$Drive]: [$freeDiskSpace MB]." -Source ${CmdletName}
			Write-Output $freeDiskSpace
		}
		Catch {
			Write-Log -Message "Failed to retrieve free disk space for drive [$Drive]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve free disk space for drive [$Drive]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-InstalledApplication {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string[]]$Name,
		[Parameter(Mandatory=$false)]
		[switch]$Exact = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$ProductCode,
		[Parameter(Mandatory=$false)]
		[switch]$IncludeUpdatesAndHotfixes
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($name) {
			Write-Log -Message "Get information for installed Application Name(s) [$($name -join ', ')]..." -Source ${CmdletName}
		}
		If ($productCode) {
			Write-Log -Message "Get information for installed Product Code [$ProductCode]..." -Source ${CmdletName}
		}
		
		[psobject[]]$installedApplication = @()
		ForEach ($regKey in $regKeyApplications) {
			Try {
				If (Test-Path -Path $regKey -ErrorAction 'Stop') {
					[psobject[]]$regKeyApplication = Get-ChildItem -Path $regKey -ErrorAction 'Stop' | ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction 'SilentlyContinue' | Where-Object { $_.DisplayName } }
					ForEach ($regKeyApp in $regKeyApplication) {
						Try {
							[string]$appDisplayName = ''
							[string]$appDisplayVersion = ''
							[string]$appPublisher = ''
							
							
							If (-not $IncludeUpdatesAndHotfixes) {
								If ($regKeyApp.DisplayName -match '(?i)kb\d+') { Continue }
								If ($regKeyApp.DisplayName -match 'Cumulative Update') { Continue }
								If ($regKeyApp.DisplayName -match 'Security Update') { Continue }
								If ($regKeyApp.DisplayName -match 'Hotfix') { Continue }
							}
							
							
							$appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]',''
							$appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]',''
							$appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]',''

							
							[boolean]$Is64BitApp = If (($is64Bit) -and ($regKey -notmatch '^HKLM:SOFTWARE\\Wow6432Node')) { $true } Else { $false }
							
							If ($ProductCode) {
								
								If ($regKeyApp.PSChildName -match [regex]::Escape($productCode)) {
									Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] matching product code [$productCode]" -Source ${CmdletName}
									$installedApplication += New-Object -TypeName PSObject -Property @{
										ProductCode = $regKeyApp.PSChildName
										DisplayName = $appDisplayName
										DisplayVersion = $appDisplayVersion
										UninstallString = $regKeyApp.UninstallString
										InstallSource = $regKeyApp.InstallSource
										InstallLocation = $regKeyApp.InstallLocation
										InstallDate = $regKeyApp.InstallDate
										Publisher = $appPublisher
										Is64BitApplication = $Is64BitApp
									}
								}
							}
							
							If ($name) {
								
								ForEach ($application in $Name) {
									$applicationMatched = $false
									If ($exact) {
										
										If ($regKeyApp.DisplayName -eq $application) {
											$applicationMatched = $true
											Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] exactly matching application name [$application]" -Source ${CmdletName}
										}
									}
									
									ElseIf ($regKeyApp.DisplayName -match [regex]::Escape($application)) {
										$applicationMatched = $true
										Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] matching application name [$application]" -Source ${CmdletName}
									}
									
									If ($applicationMatched) {
										$installedApplication += New-Object -TypeName PSObject -Property @{
											ProductCode = $regKeyApp.PSChildName
											DisplayName = $appDisplayName
											DisplayVersion = $appDisplayVersion
											UninstallString = $regKeyApp.UninstallString
											InstallSource = $regKeyApp.InstallSource
											InstallLocation = $regKeyApp.InstallLocation
											InstallDate = $regKeyApp.InstallDate
											Publisher = $appPublisher
											Is64BitApplication = $Is64BitApp
										}
									}
								}
							}
						}
						Catch {
							Write-Log -Message "Failed to resolve application details from registry for [$appDisplayName]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
							Continue
						}
					}
				}
			}
			Catch {
				Write-Log -Message "Failed to resolve registry path [$regKey]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Continue
			}
		}
		Write-Output $installedApplication
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Execute-MSI {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('Install','Uninstall','Patch','Repair','ActiveSetup')]
		[string]$Action,
		[Parameter(Mandatory=$true,HelpMessage='Please enter either the path to the MSI/MSP file or the ProductCode')]
		[ValidateScript({($_ -match $MSIProductCodeRegExPattern) -or ('.msi','.msp' -contains [System.IO.Path]::GetExtension($_))})]
		[Alias('FilePath')]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Transform,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Patch,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$private:LogName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		[boolean]$PathIsProductCode = $false
		
		
		If ($Path -match $MSIProductCodeRegExPattern) {
			
			[boolean]$PathIsProductCode = $true
			
			
			Write-Log -Message 'Resolve product code to a publisher, application name, and version.' -Source ${CmdletName}
			[psobject]$productCodeNameVersion = Get-InstalledApplication -ProductCode $path | Select-Object -Property Publisher, DisplayName, DisplayVersion -First 1 -ErrorAction 'SilentlyContinue'
			
			
			If (-not $logName) {
				If ($productCodeNameVersion) {
					If ($productCodeNameVersion.Publisher) {
						$logName = ($productCodeNameVersion.Publisher + '_' + $productCodeNameVersion.DisplayName + '_' + $productCodeNameVersion.DisplayVersion) -replace "[$invalidFileNameChars]",'' -replace ' ',''
					}
					Else {
						$logName = ($productCodeNameVersion.DisplayName + '_' + $productCodeNameVersion.DisplayVersion) -replace "[$invalidFileNameChars]",'' -replace ' ',''
					}
				}
				Else {
					
					$logName = $Path
				}
			}
		}
		Else {
			
			If (-not $logName) { $logName = ([System.IO.FileInfo]$path).BaseName } ElseIf ('.log','.txt' -contains [System.IO.Path]::GetExtension($logName)) { $logName = [System.IO.Path]::GetFileNameWithoutExtension($logName) }
		}
		
		If ($configToolkitCompressLogs) {
			
			[string]$logPath = Join-Path -Path $logTempFolder -ChildPath $logName
		}
		Else {
			
			If (-not (Test-Path -Path $configMSILogDir -PathType Container -ErrorAction 'SilentlyContinue')) {
				New-Item -Path $configMSILogDir -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
			}
			
			[string]$logPath = Join-Path -Path $configMSILogDir -ChildPath $logName
		}
		
		
		If ($deployModeSilent) {
			$msiInstallDefaultParams = $configMSISilentParams
			$msiUninstallDefaultParams = $configMSISilentParams
		}
		Else {
			$msiInstallDefaultParams = $configMSIInstallParams
			$msiUninstallDefaultParams = $configMSIUninstallParams
		}
		
		
		Switch ($action) {
			'Install' { $option = '/i'; [string]$msiLogFile = "$logPath" + '_Install'; $msiDefaultParams = $msiInstallDefaultParams }
			'Uninstall' { $option = '/x'; [string]$msiLogFile = "$logPath" + '_Uninstall'; $msiDefaultParams = $msiUninstallDefaultParams }
			'Patch' { $option = '/update'; [string]$msiLogFile = "$logPath" + '_Patch'; $msiDefaultParams = $msiInstallDefaultParams }
			'Repair' { $option = '/f'; [string]$msiLogFile = "$logPath" + '_Repair'; $msiDefaultParams = $msiInstallDefaultParams }
			'ActiveSetup' { $option = '/fups'; [string]$msiLogFile = "$logPath" + '_ActiveSetup' }
		}
		
		
		If ([System.IO.Path]::GetExtension($msiLogFile) -ne '.log') {
			[string]$msiLogFile = $msiLogFile + '.log'
			[string]$msiLogFile = "`"$msiLogFile`""
		}
		
		
		If (Test-Path -Path (Join-Path -Path $dirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType Leaf -ErrorAction 'SilentlyContinue') {
			[string]$msiFile = Join-Path -Path $dirFiles -ChildPath $path
		}
		Else {
			[string]$msiFile = $Path
		}
		
		
		If ((-not $PathIsProductCode) -and (-not $workingDirectory)) { [string]$workingDirectory = Split-Path -Path $msiFile -Parent }
		
		
		If ($PathIsProductCode) {
			[string]$MSIProductCode = $path
		}
		Else {
			Try {
				[string]$MSIProductCode = Get-MsiTableProperty -Path $msiFile -Table 'Property' -ContinueOnError $false | Select-Object -ExpandProperty ProductCode -ErrorAction 'Stop'
			}
			Catch {
				Write-Log -Message "Failed to get the ProductCode from the MSI file. Continue with requested action [$Action]..." -Source ${CmdletName}
			}
		}
		
		
		[string]$msiFile = "`"$msiFile`""
		
		[string]$mstFile = "`"$transform`""
		
		[string]$mspFile = "`"$patch`""

		
		[string]$argsMSI = "$option $msiFile"
		
		If ($transform) { $argsMSI = "$argsMSI TRANSFORMS=$mstFile TRANSFORMSSECURE=1" }
		
		If ($patch) { $argsMSI = "$argsMSI PATCH=$mspFile" }
		
		If ($Parameters) { $argsMSI = "$argsMSI $Parameters" } Else { $argsMSI = "$argsMSI $msiDefaultParams" }
		
		$argsMSI = "$argsMSI $configMSILoggingOptions $msiLogFile"
		
		
		If ($MSIProductCode) {
			[psobject]$IsMsiInstalled = Get-InstalledApplication -ProductCode $MSIProductCode
		}
		Else {
			If ($Action -eq 'Install') { [boolean]$IsMsiInstalled = $false } Else { [boolean]$IsMsiInstalled = $true }
		}
		
		If (($IsMsiInstalled) -and ($Action -eq 'Install')) {
			Write-Log -Message "The MSI is already installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
		}
		ElseIf (((-not $IsMsiInstalled) -and ($Action -eq 'Install')) -or ($IsMsiInstalled)) {
			
			Write-Log -Message "Executing MSI action [$Action]..." -Source ${CmdletName}
			If ($ContinueOnError) {
				If ($WorkingDirectory) {
					Execute-Process -Path $exeMsiexec -Parameters $argsMSI -WorkingDirectory $WorkingDirectory -WindowStyle Normal -ContinueOnError $true
				}
				Else {
					Execute-Process -Path $exeMsiexec -Parameters $argsMSI -WindowStyle Normal -ContinueOnError $true
				}
			}
			Else {
				If ($WorkingDirectory) {
					Execute-Process -Path $exeMsiexec -Parameters $argsMSI -WorkingDirectory $WorkingDirectory -WindowStyle Normal
				}
				Else {
					Execute-Process -Path $exeMsiexec -Parameters $argsMSI -WindowStyle Normal
				}
			}
		}
		Else {
			Write-Log -Message "The MSI is not installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Remove-MSIApplications {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[switch]$Exact = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($Exact) {
			[psobject[]]$installedApplications = Get-InstalledApplication -Name $name -Exact
		}
		Else {
			[psobject[]]$installedApplications = Get-InstalledApplication -Name $name
		}
		
		If (($null -ne $installedApplications) -and ($installedApplications.Count)) {
			ForEach ($installedApplication in $installedApplications) {
				If ($installedApplication.UninstallString -match 'msiexec') {
					Write-Log -Message "Remove application [$($installedApplication.DisplayName) $($installedApplication.Version)]." -Source ${CmdletName}
					If ($ContinueOnError) {
						Execute-MSI -Action Uninstall -Path $installedApplication.ProductCode -ContinueOnError $true
					}
					Else {
						Execute-MSI -Action Uninstall -Path $installedApplication.ProductCode
					}
				}
				Else {
					Write-Log -Message "[$($installedApplication.DisplayName)] uninstall string [$($installedApplication.UninstallString)] does not match `"msiexec`", so removal will not proceed." -Severity 2 -Source ${CmdletName}
				}
			}
		}
		Else {
			Write-Log -Message 'No applications found for removal. Continue...' -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Execute-Process {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[Alias('FilePath')]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string[]]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Normal','Hidden','Maximized','Minimized')]
		[System.Diagnostics.ProcessWindowStyle]$WindowStyle = 'Normal',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$CreateNoWindow = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[switch]$NoWait = $false,
		[Parameter(Mandatory=$false)]
		[switch]$PassThru = $false,
		[Parameter(Mandatory=$false)]
		[switch]$WaitForMsiExec = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[timespan]$MsiExecWaitTime = $(New-TimeSpan -Seconds $configMSIMutexWaitTime),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$returnCode = $null
			
			
			If (([System.IO.Path]::IsPathRooted($Path)) -and ([System.IO.Path]::HasExtension($Path))) {
				Write-Log -Message "[$Path] is a valid fully qualified path, continue." -Source ${CmdletName}
				If (-not (Test-Path -Path $Path -PathType Leaf -ErrorAction 'Stop')) {
					Throw "File [$Path] not found."
				}
			}
			Else {
				
				[string]$PathFolders = $dirFiles
				
				[string]$PathFolders = $PathFolders + ';' + (Get-Location -PSProvider 'FileSystem').Path
				
				$env:PATH = $PathFolders + ';' + $env:PATH
				
				
				[string]$FullyQualifiedPath = Get-Command -Name $Path -CommandType 'Application' -TotalCount 1 -Syntax -ErrorAction 'SilentlyContinue'
				
				
				$env:PATH = $env:PATH -replace [regex]::Escape($PathFolders + ';'), ''
				
				If ($FullyQualifiedPath) {
					Write-Log -Message "[$Path] successfully resolved to fully qualified path [$FullyQualifiedPath]." -Source ${CmdletName}
					$Path = $FullyQualifiedPath
				}
				Else {
					Throw "[$Path] contains an invalid path or file name."
				}
			}
			
			
			If (-not $WorkingDirectory) { $WorkingDirectory = Split-Path -Path $Path -Parent -ErrorAction 'Stop' }
			
			
			
			
			If (($Path -match 'msiexec') -or ($WaitForMsiExec)) {
				[boolean]$MsiExecAvailable = Test-MsiExecMutex -MsiExecWaitTime $MsiExecWaitTime
				Start-Sleep -Seconds 1
				If (-not $MsiExecAvailable) {
					
					[int32]$returnCode = 1618
					Throw 'Please complete in progress MSI installation before proceeding with this install.'
				}
			}
			
			Try {
				
				$env:SEE_MASK_NOZONECHECKS = 1
				
				
				$private:ErrorActionPreference = 'Stop'
				
				
				$processStartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ErrorAction 'Stop'
				$processStartInfo.FileName = $Path
				$processStartInfo.WorkingDirectory = $WorkingDirectory
				$processStartInfo.UseShellExecute = $false
				$processStartInfo.ErrorDialog = $false
				$processStartInfo.RedirectStandardOutput = $true
				$processStartInfo.RedirectStandardError = $true
				$processStartInfo.CreateNoWindow = $CreateNoWindow
				If ($Parameters) { $processStartInfo.Arguments = $Parameters }
				If ($windowStyle) { $processStartInfo.WindowStyle = $WindowStyle }
				$process = New-Object -TypeName System.Diagnostics.Process -ErrorAction 'Stop'
				$process.StartInfo = $processStartInfo
				
				
				[scriptblock]$processEventHandler = { If (-not [string]::IsNullOrEmpty($EventArgs.Data)) { $Event.MessageData.AppendLine($EventArgs.Data) } }
				$stdOutBuilder = New-Object -TypeName System.Text.StringBuilder -ArgumentList ''
				$stdOutEvent = Register-ObjectEvent -InputObject $process -Action $processEventHandler -EventName 'OutputDataReceived' -MessageData $stdOutBuilder -ErrorAction 'Stop'
				
				
				Write-Log -Message "Working Directory is [$WorkingDirectory]" -Source ${CmdletName}
				If ($Parameters) {
					If ($Parameters -match '-Command \&') {
						Write-Log -Message "Executing [$Path [PowerShell ScriptBlock]]..." -Source ${CmdletName}
					}
					Else{
						Write-Log -Message "Executing [$Path $Parameters]..." -Source ${CmdletName}
					}
				}
				Else {
					Write-Log -Message "Executing [$Path]..." -Source ${CmdletName}
				}
				[boolean]$processStarted = $process.Start()
				
				If ($NoWait) {
					Write-Log -Message 'NoWait parameter specified. Continuing without waiting for exit code...' -Source ${CmdletName}
				}
				Else {
					$process.BeginOutputReadLine()
					$stdErr = $($process.StandardError.ReadToEnd()).ToString() -replace $null,''
					
					
					$process.WaitForExit()
					
					
					While (-not ($process.HasExited)) { $process.Refresh(); Start-Sleep -Seconds 1 }
					
					
					[int32]$returnCode = $process.ExitCode
					
					
					If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop'; $stdOutEvent = $null }
					$stdOut = $stdOutBuilder.ToString() -replace $null,''
					
					If ($stdErr.Length -gt 0) {
						Write-Log -Message "Standard error output from the process: $stdErr" -Severity 3 -Source ${CmdletName}
					}
				}
			}
			Finally {
				
				If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop'}
				
				
				If ($process) { $process.Close() }
				
				
				Remove-Item -Path env:SEE_MASK_NOZONECHECKS -ErrorAction 'SilentlyContinue'
			}
			
			If (-not $NoWait) {
				
				$ignoreExitCodeMatch = $false
				If ($ignoreExitCodes) {
					
					[int32[]]$ignoreExitCodesArray = $ignoreExitCodes -split ','
					ForEach ($ignoreCode in $ignoreExitCodesArray) {
						If ($returnCode -eq $ignoreCode) { $ignoreExitCodeMatch = $true }
					}
				}
				
				If ($ContinueOnError) { $ignoreExitCodeMatch = $true }
				
				
				If ($PassThru) {
					Write-Log -Message "Execution completed with exit code [$returnCode]" -Source ${CmdletName}
					[psobject]$ExecutionResults = New-Object -TypeName PSObject -Property @{ ExitCode = $returnCode; StdOut = $stdOut; StdErr = $stdErr }
					Write-Output $ExecutionResults
				}
				ElseIf ($ignoreExitCodeMatch) {
					Write-Log -Message "Execution complete and the exit code [$returncode] is being ignored" -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq 3010) -or ($returnCode -eq 1641)) {
					Write-Log -Message "Execution completed successfully with exit code [$returnCode]. A reboot is required." -Severity 2 -Source ${CmdletName}
					Set-Variable -Name msiRebootDetected -Value $true -Scope Script
				}
				ElseIf (($returnCode -eq 1605) -and ($Path -match 'msiexec')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the product is not currently installed." -Severity 3 -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq -2145124329) -and ($Path -match 'wusa')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the Windows Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq 17025) -and ($Path -match 'fullfile')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the Office Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
				}
				ElseIf ($returnCode -eq 0) {
					Write-Log -Message "Execution completed successfully with exit code [$returnCode]" -Source ${CmdletName}
				}
				Else {
					[string]$MsiExitCodeMessage = ''
					If ($Path -match 'msiexec') {
						[string]$MsiExitCodeMessage = Get-MsiExitCodeMessage -MsiExitCode $returnCode
					}
					
					If ($MsiExitCodeMessage) {
						Write-Log -Message "Execution failed with exit code [$returnCode]: $MsiExitCodeMessage" -Severity 3 -Source ${CmdletName}
					}
					Else {
						Write-Log -Message "Execution failed with exit code [$returnCode]" -Severity 3 -Source ${CmdletName}
					}
					Exit-Script -ExitCode $returnCode
				}
			}
		}
		Catch {
			If ([string]::IsNullOrEmpty([string]$returnCode)) {
				[int32]$returnCode = 999
				Write-Log -Message "Function failed, setting exit code to [$returnCode]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Execution completed with exit code [$returnCode]. Function failed. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			If ($PassThru) {
				[psobject]$ExecutionResults = New-Object -TypeName PSObject -Property @{ ExitCode = $returnCode; StdOut = If ($stdOut) { $stdOut } Else { '' }; StdErr = If ($stdErr) { $stdErr } Else { '' } }
				Write-Output $ExecutionResults
			}
			Else {
				Exit-Script -ExitCode $returnCode
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-MsiExitCodeMessage {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[int32]$MsiExitCode
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$MsiExitCodeMsgSource = @'
		using System;
		using System.Text;
		using System.Runtime.InteropServices;
		public class MsiExitCode
		{
			enum LoadLibraryFlags : int
			{
				DONT_RESOLVE_DLL_REFERENCES         = 0x00000001,
				LOAD_IGNORE_CODE_AUTHZ_LEVEL        = 0x00000010,
				LOAD_LIBRARY_AS_DATAFILE            = 0x00000002,
				LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE  = 0x00000040,
				LOAD_LIBRARY_AS_IMAGE_RESOURCE      = 0x00000020,
				LOAD_WITH_ALTERED_SEARCH_PATH       = 0x00000008
			}
			
			[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
			static extern IntPtr LoadLibraryEx(string lpFileName, IntPtr hFile, LoadLibraryFlags dwFlags);
			
			[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
			static extern int LoadString(IntPtr hInstance, int uID, StringBuilder lpBuffer, int nBufferMax);
			
			// Get MSI exit code message from msimsg.dll resource dll
			public static string GetMessageFromMsiExitCode(int errCode)
			{
				IntPtr hModuleInstance = LoadLibraryEx("msimsg.dll", IntPtr.Zero, LoadLibraryFlags.LOAD_LIBRARY_AS_DATAFILE);
				
				StringBuilder sb = new StringBuilder(255);
				LoadString(hModuleInstance, errCode, sb, sb.Capacity + 1);
				
				return sb.ToString();
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'MsiExitCode').Type) {
			Add-Type -TypeDefinition $MsiExitCodeMsgSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			Write-Log -Message "Get message for exit code [$MsiExitCode]." -Source ${CmdletName}
			[string]$MsiExitCodeMsg = [MsiExitCode]::GetMessageFromMsiExitCode($MsiExitCode)
			Write-Output $MsiExitCodeMsg
		}
		Catch {
			Write-Log -Message "Failed to get message for exit code [$MsiExitCode]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-MsiExecMutex {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[timespan]$MsiExecWaitTime = $(New-TimeSpan -Seconds $configMSIMutexWaitTime)
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$IsMsiExecFreeSource = @'
		using System;
		using System.Threading;
		public class MsiExec
		{
			public static bool IsMsiExecFree(TimeSpan maxWaitTime)
			{
				// Wait (up to a timeout) for the MSI installer service to become free.
				// Returns true for a successful wait, when the installer service has become free.
				// Returns false when waiting for the installer service has exceeded the timeout.
				const string installerServiceMutexName = "Global\\_MSIExecute";
				Mutex MSIExecuteMutex = null;
				bool isMsiExecFree = false;
				
				try
				{
					MSIExecuteMutex = Mutex.OpenExisting(installerServiceMutexName, System.Security.AccessControl.MutexRights.Synchronize);
					isMsiExecFree   = MSIExecuteMutex.WaitOne(maxWaitTime, false);
				}
				catch (WaitHandleCannotBeOpenedException)
				{
					// Mutex doesn't exist, do nothing
					isMsiExecFree = true;
				}
				catch (ObjectDisposedException)
				{
					// Mutex was disposed between opening it and attempting to wait on it, do nothing
					isMsiExecFree = true;
				}
				finally
				{
					if (MSIExecuteMutex != null && isMsiExecFree)
					MSIExecuteMutex.ReleaseMutex();
				}
				return isMsiExecFree;
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'MsiExec').Type) {
			Add-Type -TypeDefinition $IsMsiExecFreeSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			If ($MsiExecWaitTime.TotalMinutes -gt 1) {
				[string]$WaitLogMsg = "$($MsiExecWaitTime.TotalMinutes) minutes"
			}
			ElseIf ($MsiExecWaitTime.TotalMinutes -eq 1) {
				[string]$WaitLogMsg = "$($MsiExecWaitTime.TotalMinutes) minute"
			}
			Else {
				[string]$WaitLogMsg = "$($MsiExecWaitTime.TotalSeconds) seconds"
			}
			Write-Log -Message "Check to see if mutex [Global\\_MSIExecute] is available. Wait up to [$WaitLogMsg] for the mutex to become available." -Source ${CmdletName}
			[boolean]$IsMsiExecInstallFree = [MsiExec]::IsMsiExecFree($MsiExecWaitTime)
			
			If ($IsMsiExecInstallFree) {
				Write-Log -Message 'Mutex [Global\\_MSIExecute] is available.' -Source ${CmdletName}
			}
			Else {
				
				[string]$msiInProgressCmdLine = Get-WmiObject -Class Win32_Process -Filter "name = 'msiexec.exe'" | Select-Object -ExpandProperty CommandLine | Where-Object { $_ -match '\.msi' } | ForEach-Object { $_.Trim() }
				Write-Log -Message "Mutex [Global\\_MSIExecute] is not available because the following MSI installation is in progress [$msiInProgressCmdLine]" -Severity 2 -Source ${CmdletName}
			}
			Write-Output $IsMsiExecInstallFree
		}
		Catch {
			Write-Log -Message "Failed check for availability of mutex [Global\\_MSIExecute]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			
			Write-Output $true
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function New-Folder {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If (-not (Test-Path -Path $Path -PathType Container)) {
				Write-Log -Message "Create folder [$Path]." -Source ${CmdletName}
				New-Item -Path $Path -ItemType Directory -ErrorAction 'Stop'
			}
			Else {
				Write-Log -Message "Folder [$Path] already exists." -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to create folder [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create folder [$Path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Remove-Folder {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If (Test-Path -Path $Path -PathType Container) {
				Write-Log -Message "Delete folder(s) and file(s) recursively from path [$path]..." -Source ${CmdletName}
				Remove-Item -Path $Path -Force -Recurse -ErrorAction 'Stop' | Out-Null
			}
			Else {
				Write-Log -Message "Folder [$Path] does not exists..." -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to delete folder(s) and file(s) recursively from path [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to delete folder(s) and file(s) recursively from path [$path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Copy-File {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Destination,
		[Parameter(Mandatory=$false)]
		[switch]$Recurse = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If ((-not ([System.IO.Path]::HasExtension($Destination))) -and (-not (Test-Path -Path $Destination -PathType Container))) {
				New-Item -Path $Destination -Type 'Directory' -Force -ErrorAction 'Stop' | Out-Null
			}
			
			If ($Recurse) {
				Write-Log -Message "Copy file(s) recursively in path [$path] to destination [$destination]" -Source ${CmdletName}
				Copy-Item -Path $Path -Destination $destination -Force -Recurse -ErrorAction 'Stop' | Out-Null
			}
			Else {
				Write-Log -Message "Copy file in path [$path] to destination [$destination]" -Source ${CmdletName}
				Copy-Item -Path $Path -Destination $destination -Force -ErrorAction 'Stop' | Out-Null
			}
		}
		Catch {
			Write-Log -Message "Failed to copy file(s) in path [$path] to destination [$destination]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to copy file(s) in path [$path] to destination [$destination]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Remove-File {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[switch]$Recurse,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If ($Recurse) {
				Write-Log -Message "Delete file(s) recursively in path [$path]..." -Source ${CmdletName}
				Remove-Item -Path $path -Force -Recurse -ErrorAction 'Stop' | Out-Null
			}
			Else {
				Write-Log -Message "Delete file in path [$path]..." -Source ${CmdletName}
				Remove-Item -Path $path -Force -ErrorAction 'Stop' | Out-Null
			}
		}
		Catch {
			Write-Log -Message "Failed to delete file(s) in path [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to delete file(s) in path [$path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Convert-RegistryPath {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($Key -match '^HKLM:\\|^HKCU:\\|^HKCR:\\|^HKU:\\|^HKCC:\\|^HKPD:\\') {
			
			$key = $key -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU:\\', 'HKEY_USERS\'
			$key = $key -replace '^HKCC:\\', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD:\\', 'HKEY_PERFORMANCE_DATA\'
		}
		ElseIf ($Key -match '^HKLM:|^HKCU:|^HKCR:|^HKU:|^HKCC:|^HKPD:') {
			
			$key = $key -replace '^HKLM:', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR:', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU:', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU:', 'HKEY_USERS\'
			$key = $key -replace '^HKCC:', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD:', 'HKEY_PERFORMANCE_DATA\'
		}
		ElseIf ($Key -match '^HKLM\\|^HKCU\\|^HKCR\\|^HKU\\|^HKCC\\|^HKPD\\') {
			
			$key = $key -replace '^HKLM\\', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR\\', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU\\', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU\\', 'HKEY_USERS\'
			$key = $key -replace '^HKCC\\', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD\\', 'HKEY_PERFORMANCE_DATA\'
		}
		
		
		If ($PSBoundParameters.ContainsKey('SID')) {
			If ($key -match '^HKEY_CURRENT_USER\\') { $key = $key -replace '^HKEY_CURRENT_USER\\', "HKEY_USERS\$SID\" }
		}
		
		
		If ($key -notmatch '^Registry::') { [string]$key = "Registry::$key" }
		
		Write-Log -Message "Return fully qualified registry key path [$key]" -Source ${CmdletName}
		Write-Output $key
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-RegistryKey {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Value,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$ReturnEmptyKeyIfExists,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			Else {
				[string]$key = Convert-RegistryPath -Key $key
			}
			
			
			If (-not (Test-Path -Path $key -ErrorAction 'Stop')) {
				Write-Log -Message "Registry key [$key] does not exist" -Severity 2 -Source ${CmdletName}
				$regKeyValue = $null
			}
			Else {
				If (-not $Value) {
					
					Write-Log -Message "Get registry key [$key] and all property values" -Source ${CmdletName}
					$regKeyValue = Get-ItemProperty -Path $key -ErrorAction 'Stop'
					If ((-not $regKeyValue) -and ($ReturnEmptyKeyIfExists)) {
						Write-Log -Message "No property values found for registry key. Get registry key [$key]" -Source ${CmdletName}
						$regKeyValue = Get-Item -Path $key -Force -ErrorAction 'Stop'
					}
				}
				Else {
					
					Write-Log -Message "Get registry key [$key] value [$value]" -Source ${CmdletName}
					$regKeyValue = Get-ItemProperty -Path $key -ErrorAction 'Stop' | Select-Object -ExpandProperty $Value -ErrorAction 'SilentlyContinue'
				}
			}
			
			If ($regKeyValue) { Write-Output $regKeyValue } Else { Write-Output $null }
		}
		Catch {
			If (-not $Value) {
				Write-Log -Message "Failed to read registry key [$key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to read registry key [$key]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to read registry key [$key] value [$value]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to read registry key [$key] value [$value]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-RegistryKey {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		$Value,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Binary','DWord','ExpandString','MultiString','None','QWord','String','Unknown')]
		[Microsoft.Win32.RegistryValueKind]$Type = 'String',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			[string]$RegistryValueWriteAction = 'set'
			
			
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			Else {
				[string]$key = Convert-RegistryPath -Key $key
			}
			
			
			If (-not (Test-Path -Path $key -ErrorAction 'Stop')) {
				Try {
					Write-Log -Message "Create registry key [$key]." -Source ${CmdletName}
					New-Item -Path $key -ItemType Registry -Force -ErrorAction 'Stop' | Out-Null
				}
				Catch {
					Throw
				}
			}
			
			If ($Name) {
				
				If (-not (Get-ItemProperty -Path $key -Name $Name -ErrorAction 'SilentlyContinue')) {
					Write-Log -Message "Set registry key value: [$key] [$name = $value]" -Source ${CmdletName}
					New-ItemProperty -Path $key -Name $name -Value $value -PropertyType $Type -ErrorAction 'Stop' | Out-Null
				}
				
				Else {
					[string]$RegistryValueWriteAction = 'update'
					Write-Log -Message "Update registry key value: [$key] [$name = $value]" -Source ${CmdletName}
					Set-ItemProperty -Path $key -Name $name -Value $value -ErrorAction 'Stop' | Out-Null
				}
			}
		}
		Catch {
			If ($Name) {
				Write-Log -Message "Failed to $RegistryValueWriteAction value [$value] for registry key [$key] [$name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to $RegistryValueWriteAction value [$value] for registry key [$key] [$name]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to set registry key [$key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to set registry key [$key]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Remove-RegistryKey {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[switch]$Recurse,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			Else {
				[string]$key = Convert-RegistryPath -Key $key
			}
			
			If (-not ($name)) {
				If ($Recurse) {
					Write-Log -Message "Delete registry key recursively [$key]" -Source ${CmdletName}
					Remove-Item -Path $Key -ErrorAction 'Stop' -Force -Recurse | Out-Null
				}
				Else {
					Write-Log -Message "Delete registry key [$key]" -Source ${CmdletName}
					Remove-Item -Path $Key -ErrorAction 'Stop' -Force | Out-Null
				}
			}
			Else {
				Write-Log -Message "Delete registry value [$key] [$name]" -Source ${CmdletName}
				Remove-ItemProperty -Path $Key -Name $Name -ErrorAction 'Stop' -Force | Out-Null
			}
		}
		Catch {
			If (-not ($name)) {
				Write-Log -Message "Failed to delete registry key [$key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to delete registry key [$key]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to delete registry value [$key] [$name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to delete registry value [$key] [$name]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Invoke-HKCURegistrySettingsForAllUsers {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[scriptblock]$RegistrySettings,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[psobject[]]$UserProfiles = (Get-UserProfiles)
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		ForEach ($UserProfile in $UserProfiles) {
			Try {
				
				[string]$UserRegistryPath = "Registry::HKEY_USERS\$($UserProfile.SID)"
				
				
				[string]$UserRegistryHiveFile = Join-Path -Path $UserProfile.ProfilePath -ChildPath 'NTUSER.DAT'
				
				
				[boolean]$ManuallyLoadedRegHive = $false
				If (-not (Test-Path -Path $UserRegistryPath)) {
					
					If (Test-Path -Path $UserRegistryHiveFile -PathType Leaf) {
						Write-Log -Message "Load the User [$($UserProfile.NTAccount)] registry hive in path [HKEY_USERS\$($UserProfile.SID)]" -Source ${CmdletName}
						[string]$HiveLoadResult = & reg.exe load "`"HKEY_USERS\$($UserProfile.SID)`"" "`"$UserRegistryHiveFile`""
						
						If ($global:LastExitCode -ne 0) {
							Throw "Failed to load the registry hive for User [$($UserProfile.NTAccount)] with SID [$($UserProfile.SID)]. Failure message [$HiveLoadResult]. Continue..."
						}
						
						[boolean]$ManuallyLoadedRegHive = $true
					}
					Else {
						Throw "Failed to find the registry hive file [$UserRegistryHiveFile] for User [$($UserProfile.NTAccount)] with SID [$($UserProfile.SID)]. Continue..."
					}
				}
				Else {
					Write-Log -Message "The User [$($UserProfile.NTAccount)] registry hive is already loaded in path [HKEY_USERS\$($UserProfile.SID)]" -Source ${CmdletName}
				}
				
				
				
				
				Write-Log -Message 'Execute ScriptBlock to modify HKCU registry settings for all users.' -Source ${CmdletName}
				& $RegistrySettings
			}
			Catch {
				Write-Log -Message "Failed to modify the registry hive for User [$($UserProfile.NTAccount)] with SID [$($UserProfile.SID)] `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			Finally {
				If ($ManuallyLoadedRegHive) {
					Try {
						Write-Log -Message "Unload the User [$($UserProfile.NTAccount)] registry hive in path [HKEY_USERS\$($UserProfile.SID)]" -Source ${CmdletName}
						[string]$HiveLoadResult = & reg.exe unload "`"HKEY_USERS\$($UserProfile.SID)`""
						
						If ($global:LastExitCode -ne 0) { Throw "$HiveLoadResult" }
					}
					Catch {
						Write-Log -Message "Failed to unload the registry hive for User [$($UserProfile.NTAccount)] with SID [$($UserProfile.SID)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function ConvertTo-NTAccountOrSID {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ParameterSetName='NTAccountToSID',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$AccountName,
		[Parameter(Mandatory=$true,ParameterSetName='SIDToNTAccount',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$true,ParameterSetName='WellKnownName',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$WellKnownSIDName,
		[Parameter(Mandatory=$false,ParameterSetName='WellKnownName')]
		[ValidateNotNullOrEmpty()]
		[switch]$WellKnownToNTAccount
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Switch ($PSCmdlet.ParameterSetName) {
				'SIDToNTAccount' {
					[string]$msg = "the SID [$SID] to an NT Account name"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					$NTAccountSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $SID
					$NTAccount = $NTAccountSID.Translate([System.Security.Principal.NTAccount])
					Write-Output $NTAccount
				}
				'NTAccountToSID' {
					[string]$msg = "the NT Account [$AccountName] to a SID"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					$NTAccount = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $AccountName
					$NTAccountSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier])
					Write-Output $NTAccountSID
				}
				'WellKnownName' {
					If ($WellKnownToNTAccount) {
						[string]$ConversionType = 'NTAccount'
					}
					Else {
						[string]$ConversionType = 'SID'
					}
					[string]$msg = "the Well Known SID Name [$WellKnownSIDName] to a $ConversionType"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					
					Try {
						$MachineRootDomain = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction 'Stop').Domain.ToLower()
						$ADDomainObj = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList "LDAP://$MachineRootDomain"
						$DomainSidInBinary = $ADDomainObj.ObjectSid
						$DomainSid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList ($DomainSidInBinary[0], 0)
					}
					Catch {
						Write-Log -Message 'Unable to get Domain SID from Active Directory. Setting Domain SID to $null.' -Severity 2 -Source ${CmdletName}
						$DomainSid = $null
					}
					
					
					$WellKnownSidType = [Security.Principal.WellKnownSidType]::$WellKnownSIDName
					$NTAccountSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList ($WellKnownSidType, $DomainSid)
					
					If ($WellKnownToNTAccount) {
						$NTAccount = $NTAccountSID.Translate([System.Security.Principal.NTAccount])
						Write-Output $NTAccount
					}
					Else {
						Write-Output $NTAccountSID
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to convert $msg. It may not be a valid account anymore or there is some other problem. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-UserProfiles {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string[]]$ExcludeNTAccount,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ExcludeSystemProfiles = $true,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$ExcludeDefaultUser = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Get the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine.' -Source ${CmdletName}
			
			
			[string]$UserProfileListRegKey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
			[psobject[]]$UserProfiles = Get-ChildItem -Path $UserProfileListRegKey -ErrorAction 'Stop' |
			ForEach-Object {
				Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction 'Stop' | Where-Object { ($_.ProfileImagePath) } |
				Select-Object @{ Label = 'NTAccount'; Expression = { $(ConvertTo-NTAccountOrSID -SID $_.PSChildName).Value } }, @{ Label = 'SID'; Expression = { $_.PSChildName } }, @{ Label = 'ProfilePath'; Expression = { $_.ProfileImagePath } }
			}
			If ($ExcludeSystemProfiles) {
				[string[]]$SystemProfiles = 'S-1-5-18', 'S-1-5-19', 'S-1-5-20'
				[psobject[]]$UserProfiles = $UserProfiles | Where-Object { $SystemProfiles -notcontains $_.SID }
			}
			If ($ExcludeNTAccount) {
				[psobject[]]$UserProfiles = $UserProfiles | Where-Object { $ExcludeNTAccount -notcontains $_.NTAccount }
			}
			
			
			If (-not $ExcludeDefaultUser) {
				[string]$UserProfilesDirectory = Get-ItemProperty -LiteralPath $UserProfileListRegKey -Name ProfilesDirectory -ErrorAction 'Stop' | Select-Object -ExpandProperty ProfilesDirectory

				
				If ([System.Environment]::OSVersion.Version.Major -gt 5) {
					
					[string]$DefaultUserProfileDirectory = Get-ItemProperty -LiteralPath $UserProfileListRegKey -Name 'Default' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Default'
				}
				
				Else {
					
					[string]$DefaultUserProfileName = Get-ItemProperty -LiteralPath $UserProfileListRegKey -Name 'DefaultUsersProfile' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'DefaultUsersProfile'
					
					
					[string]$DefaultUserProfileDirectory = Join-Path -Path $UserProfilesDirectory -ChildPath $DefaultUserProfileName
				}
				
				
				
				
				$DefaultUserProfile = New-Object -TypeName PSObject
				$DefaultUserProfile | Add-Member -MemberType NoteProperty -Name NTAccount -Value 'Default User' -Force -ErrorAction 'Stop'
				$DefaultUserProfile | Add-Member -MemberType NoteProperty -Name SID -Value 'S-1-5-21-Default-User' -Force -ErrorAction 'Stop'
				$DefaultUserProfile | Add-Member -MemberType NoteProperty -Name ProfilePath -Value $DefaultUserProfileDirectory -Force -ErrorAction 'Stop'
				
				
				$UserProfiles += $DefaultUserProfile
			}
			
			Write-Output $UserProfiles
		}
		Catch {
			Write-Log -Message "Failed to create a custom object representing all user profiles on the machine. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-FileVersion {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$File,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get file version info for file [$file]" -Source ${CmdletName}
			
			If (Test-Path -Path $File -PathType Leaf) {
				$fileVersion = (Get-Command -Name $file -ErrorAction 'Stop').FileVersionInfo.FileVersion
				If ($fileVersion) {
					
					$fileVersion = ($fileVersion -split ' ' | Select-Object -First 1)
					
					Write-Log -Message "File version is [$fileVersion]" -Source ${CmdletName}
					Write-Output $fileVersion
				}
				Else {
					Write-Log -Message 'No file version information found.' -Source ${CmdletName}
				}
			}
			Else {
				Throw "File path [$file] does not exist."
			}
		}
		Catch {
			Write-Log -Message "Failed to get file version info. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to get file version info: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function New-Shortcut {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$TargetPath,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Arguments,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IconLocation,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IconIndex,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Description,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Normal','Maximized','Minimized')]
		[string]$WindowStyle,
		[Parameter(Mandatory=$false)]
		[switch]$RunAsAdmin,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		If (-not $Shell) { [__comobject]$Shell = New-Object -ComObject WScript.Shell -ErrorAction 'Stop' }
	}
	Process {
		Try {
			Try {
				[System.IO.FileInfo]$Path = [System.IO.FileInfo]$Path
				[string]$PathDirectory = $Path.DirectoryName
				
				If (-not (Test-Path -Path $PathDirectory -PathType Container -ErrorAction 'Stop')) {
					Write-Log -Message "Create shortcut directory [$PathDirectory]" -Source ${CmdletName}
					New-Item -Path $PathDirectory -ItemType Directory -Force -ErrorAction 'Stop' | Out-Null
				}
			}
			Catch {
				Write-Log -Message "Failed to create shortcut directory [$PathDirectory]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw
			}
			
			Write-Log -Message "Create shortcut [$($path.FullName)]" -Source ${CmdletName}
			If (($path.FullName).EndsWith('.url')) {
				[string[]]$URLFile = '[InternetShortcut]'
				$URLFile += "URL=$targetPath"
				If ($iconIndex) { $URLFile += "IconIndex=$iconIndex" }
				If ($IconLocation) { $URLFile += "IconFile=$iconLocation" }
				$URLFile | Out-File -FilePath $path.FullName -Force -Encoding default -ErrorAction 'Stop'
			}
			ElseIf (($path.FullName).EndsWith('.lnk')) {
				If (($iconLocation -and $iconIndex) -and (-not ($iconLocation.Contains(',')))) {
					$iconLocation = $iconLocation + ",$iconIndex"
				}
				Switch ($windowStyle) {
					'Normal' { $windowStyleInt = 1 }
					'Maximized' { $windowStyleInt = 3 }
					'Minimized' { $windowStyleInt = 7 }
					Default { $windowStyleInt = 1 }
				}
				$shortcut = $shell.CreateShortcut($path.FullName)
				$shortcut.TargetPath = $targetPath
				$shortcut.Arguments = $arguments
				$shortcut.Description = $description
				$shortcut.WorkingDirectory = $workingDirectory
				$shortcut.WindowStyle = $windowStyleInt
				If ($iconLocation) { $shortcut.IconLocation = $iconLocation }
				$shortcut.Save()
				
				
				If ($RunAsAdmin) {
					Write-Log -Message 'Set shortcut to run program as administrator.' -Source ${CmdletName}
					$TempFileName = [System.IO.Path]::GetRandomFileName()
					$TempFile = [System.IO.FileInfo][IO.Path]::Combine($Path.Directory, $TempFileName)
					$Writer = New-Object -TypeName System.IO.FileStream -ArgumentList ($TempFile, ([System.IO.FileMode]::Create)) -ErrorAction 'Stop'
					$Reader = $Path.OpenRead()
					While ($Reader.Position -lt $Reader.Length) {
						$Byte = $Reader.ReadByte()
						If ($Reader.Position -eq 22) { $Byte = 34 }
						$Writer.WriteByte($Byte)
					}
					$Reader.Close()
					$Writer.Close()
					$Path.Delete()
					Rename-Item -Path $TempFile -NewName $Path.Name -Force -ErrorAction 'Stop' | Out-Null
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to create shortcut [$($path.FullName)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create shortcut [$($path.FullName)]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Execute-ProcessAsUser {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Parameters = '',
		[Parameter(Mandatory=$false)]
		[ValidateSet('HighestAvailable','LeastPrivilege')]
		[string]$RunLevel = 'HighestAvailable',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$Wait = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If (Test-Path -Path 'variable:executeProcessAsUserExitCode') { Remove-Variable -Name executeProcessAsUserExitCode -Scope Global}
		$global:executeProcessAsUserExitCode = $null
		
		
		If (($RunLevel -eq 'HighestAvailable') -and (-not $IsAdmin)) {
			Write-Log -Message "The function [${CmdletName}] requires the toolkit to be running with Administrator privileges if the [-RunLevel] parameter is set to 'HighestAvailable'." -Severity 3 -Source ${CmdletName}
			If ($ContinueOnError) {
				Return
			}
			Else {
				[int32]$global:executeProcessAsUserExitCode = 1
				Exit
			}
		}
		
		
		[string]$schTaskName = "$appDeployToolkitName-ExecuteAsUser"
		
		
		If (-not (Test-Path -Path $dirAppDeployTemp -PathType Container)) {
			New-Item -Path $dirAppDeployTemp -ItemType Directory -Force -ErrorAction 'Stop'
		}
		
		
		If (($Path -eq 'PowerShell.exe') -or ((Split-Path -Path $Path -Leaf) -eq 'PowerShell.exe')) {
			[string]$executeProcessAsUserParametersVBS = 'chr(34) & ' + "`"$($Path)`"" + ' & chr(34) & ' + '" ' + ($Parameters -replace '"', "`" & chr(34) & `"" -replace ' & chr\(34\) & "$','') + '"'
			[string[]]$executeProcessAsUserScript = "strCommand = $executeProcessAsUserParametersVBS"
			$executeProcessAsUserScript += 'set oWShell = CreateObject("WScript.Shell")'
			$executeProcessAsUserScript += 'intReturn = oWShell.Run(strCommand, 0, true)'
			$executeProcessAsUserScript += 'WScript.Quit intReturn'
			$executeProcessAsUserScript | Out-File -FilePath "$dirAppDeployTemp\$($schTaskName).vbs" -Force -Encoding default -ErrorAction 'SilentlyContinue'
			$Path = 'wscript.exe'
			$Parameters = "`"$dirAppDeployTemp\$($schTaskName).vbs`""
		}
		
		
		[string]$xmlSchTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo />
  <Triggers />
  <Settings>
	<MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
	<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
	<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
	<AllowHardTerminate>true</AllowHardTerminate>
	<StartWhenAvailable>false</StartWhenAvailable>
	<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
	<IdleSettings />
	<AllowStartOnDemand>true</AllowStartOnDemand>
	<Enabled>true</Enabled>
	<Hidden>false</Hidden>
	<RunOnlyIfIdle>false</RunOnlyIfIdle>
	<WakeToRun>false</WakeToRun>
	<ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
	<Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
	<Exec>
	  <Command>$Path</Command>
	  <Arguments>$Parameters</Arguments>
	</Exec>
  </Actions>
  <Principals>
	<Principal id="Author">
	  <UserId>$UserName</UserId>
	  <LogonType>InteractiveToken</LogonType>
	  <RunLevel>$RunLevel</RunLevel>
	</Principal>
  </Principals>
</Task>
"@
		
		Try {
			
			[string]$xmlSchTaskFilePath = "$dirAppDeployTemp\$schTaskName.xml"
			[string]$xmlSchTask | Out-File -FilePath $xmlSchTaskFilePath -Force -ErrorAction Stop
		}
		Catch {
			Write-Log -Message "Failed to export the scheduled task XML file. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If ($ContinueOnError) {
				Return
			}
			Else {
				[int32]$global:executeProcessAsUserExitCode = $schTaskResult.ExitCode
				Exit
			}
		}
		
		
		Try {
			If ($Parameters) {
				Write-Log -Message "Create scheduled task to run the process [$Path $Parameters] as the logged-on user [$userName]..." -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Create scheduled task to run the process [$Path] as the logged-on user [$userName]..." -Source ${CmdletName}
			}
			
			[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/create /f /tn $schTaskName /xml `"$xmlSchTaskFilePath`"" -WindowStyle Hidden -CreateNoWindow -PassThru
			If ($schTaskResult.ExitCode -ne 0) {
				If ($ContinueOnError) {
					Return
				}
				Else {
					[int32]$global:executeProcessAsUserExitCode = $schTaskResult.ExitCode
					Exit
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to create scheduled task. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If ($ContinueOnError) {
				Return
			}
			Else {
				[int32]$global:executeProcessAsUserExitCode = $schTaskResult.ExitCode
				Exit
			}
		}
		
		
		Try {
			If ($Parameters) {
				Write-Log -Message "Trigger execution of scheduled task with command [$Path $Parameters] as the logged-on user [$userName]..." -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Trigger execution of scheduled task with command [$Path] as the logged-on user [$userName]..." -Source ${CmdletName}
			}
			[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/run /i /tn $schTaskName" -WindowStyle Hidden -CreateNoWindow -Passthru
			If ($schTaskResult.ExitCode -ne 0) {
				If ($ContinueOnError) {
					Return
				}
				Else {
					[int32]$global:executeProcessAsUserExitCode = $schTaskResult.ExitCode
					Exit
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to trigger scheduled task. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			
			Write-Log -Message 'Delete the scheduled task which did not to trigger.' -Source ${CmdletName}
			Execute-Process -Path $exeSchTasks -Parameters "/delete /tn $schTaskName /f" -WindowStyle Hidden -CreateNoWindow -ContinueOnError $true
			If ($ContinueOnError) {
				Return
			}
			Else {
				[int32]$global:executeProcessAsUserExitCode = $schTaskResult.ExitCode
				Exit
			}
		}
		
		
		If ($Wait) {
			Write-Log -Message "Waiting for the process launched by the scheduled task [$schTaskName] to complete execution (this may take some time)..." -Source ${CmdletName}
			Start-Sleep -Seconds 1
			While ((($exeSchTasksResult = & $exeSchTasks /query /TN $schTaskName /V /FO CSV) | ConvertFrom-CSV | Select-Object -ExpandProperty 'Status' | Select-Object -First 1) -eq 'Running') {
				Start-Sleep -Seconds 5
			}
			
			[int32]$global:executeProcessAsUserExitCode = ($exeSchTasksResult = & $exeSchTasks /query /TN $schTaskName /V /FO CSV) | ConvertFrom-CSV | Select-Object -ExpandProperty 'Last Result' | Select-Object -First 1
			Write-Log -Message "Exit code from process launched by scheduled task [$global:executeProcessAsUserExitCode]" -Source ${CmdletName}
		}
		
		
		Try {
			Write-Log -Message "Delete scheduled task [$schTaskName]." -Source ${CmdletName}
			Execute-Process -Path $exeSchTasks -Parameters "/delete /tn $schTaskName /f" -WindowStyle Hidden -CreateNoWindow -ErrorAction 'Stop'
		}
		Catch {
			Write-Log -Message "Failed to delete scheduled task [$schTaskName]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
		
		
		Exit
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Refresh-Desktop {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$refreshDesktopSource = @'
		private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
		private const int WM_SETTINGCHANGE = 0x1a;
		private const int SMTO_ABORTIFHUNG = 0x0002;
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		static extern bool SendNotifyMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
		
		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, IntPtr lpdwResult);
		
		[DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = false)]
		private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
		
		public static void Refresh()
		{
			// Update desktop icons
			SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);
			// Update environment variables
			SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, null, SMTO_ABORTIFHUNG, 100, IntPtr.Zero);
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'MyWinAPI.Explorer').Type) {
			Add-Type -MemberDefinition $refreshDesktopSource -Namespace MyWinAPI -Name Explorer -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			Write-Log -Message 'Refresh the Desktop and the Windows Explorer environment process block' -Source ${CmdletName}
			[MyWinAPI.Explorer]::Refresh()
		}
		Catch {
			Write-Log -Message "Failed to refresh the Desktop and the Windows Explorer environment process block. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to refresh the Desktop and the Windows Explorer environment process block: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Refresh-SessionEnvironmentVariables {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[scriptblock]$GetEnvironmentVar = {
			Param (
				$Key,
				$Scope
			)
			[System.Environment]::GetEnvironmentVariable($Key, $Scope)
		}
	}
	Process {
		Try {
			Write-Log -Message 'Refresh the environment variables for this PowerShell session.' -Source ${CmdletName}
			
			[string]$CurrentUserEnvironmentSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
			[string]$MachineEnvironmentVars = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
			[string]$UserEnvironmentVars = "Registry::HKEY_USERS\$CurrentUserEnvironmentSID\Environment"
			
			
			$MachineEnvironmentVars, $UserEnvironmentVars | Get-Item | Where-Object { $_ } | ForEach-Object { $envRegPath = $_.PSPath; $_ | Select-Object -ExpandProperty Property | ForEach-Object { Set-Item -Path "env:$($_)" -Value (Get-ItemProperty -Path $envRegPath -Name $_).$_ } }
			
			
			[string[]]$PathFolders = 'Machine', 'User' | ForEach-Object { (& $GetEnvironmentVar -Key 'PATH' -Scope $_) } | Where-Object { $_ } | ForEach-Object { $_.Trim(';') } | ForEach-Object { $_.Split(';') } | ForEach-Object { $_.Trim() } | ForEach-Object { $_.Trim('"') } | Select-Object -Unique
			$env:PATH = $PathFolders -join ';'
		}
		Catch {
			Write-Log -Message "Failed to refresh the environment variables for this PowerShell session. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to refresh the environment variables for this PowerShell session: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-ScheduledTask {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$TaskName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		If (-not $exeSchTasks) { [string]$exeSchTasks = "$env:WINDIR\system32\schtasks.exe" }
		[psobject[]]$ScheduledTasks = @()
	}
	Process {
		Try {
			Write-Log -Message 'Retrieve Scheduled Tasks' -Source ${CmdletName}
			[string[]]$exeSchtasksResults = & $exeSchTasks /Query /V /FO CSV
			If ($global:LastExitCode -ne 0) { Throw "Failed to retrieve scheduled tasks using [$exeSchTasks]." }
			[psobject[]]$SchtasksResults = $exeSchtasksResults | ConvertFrom-CSV -ErrorAction 'Stop'
			
			If ($SchtasksResults) {
				ForEach ($SchtasksResult in $SchtasksResults) {
					If ($SchtasksResult.TaskName -match $TaskName) {
						$SchtasksResult  | Get-Member -MemberType Properties |
						ForEach -Begin { 
							[hashtable]$Task = @{}
						} -Process {
							
							($Task.($($_.Name).Replace(' ','').Replace(':',''))) = If ($_.Name -ne $SchtasksResult.($_.Name)) { $SchtasksResult.($_.Name) }
						} -End {
							
							If (($Task.Values | Select-Object -Unique | Measure-Object).Count) {
								$ScheduledTasks += New-Object -TypeName PSObject -Property $Task
							}
						}
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to retrieve scheduled tasks. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve scheduled tasks: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-Output $ScheduledTasks
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Block-AppExecution {

	[CmdletBinding()]
	Param (
		
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string[]]$ProcessName
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) {
			Write-Log -Message "Bypassing Function [${CmdletName}] [Mode: $deployMode]" -Source ${CmdletName}
			Return
		}
		
		[string]$schTaskBlockedAppsName = $installName + '_BlockedApps'
		
		
		If (-not (Test-Path -Path $dirAppDeployTemp -PathType Container -ErrorAction 'SilentlyContinue')) {
			New-Item -Path $dirAppDeployTemp -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
		}
		Copy-Item -Path "$scriptRoot\*.*" -Destination $dirAppDeployTemp -Exclude 'thumbs.db' -Force -Recurse -ErrorAction 'SilentlyContinue'
		
		
		[string]$debuggerBlockMessageCmd = "`"powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -File `" & chr(34) & `"$dirAppDeployTemp\$scriptFileName`" & chr(34) & `" -ShowBlockedAppDialog -ReferringApplication `" & chr(34) & `"$installName`" & chr(34)"
		[string[]]$debuggerBlockScript = "strCommand = $debuggerBlockMessageCmd"
		$debuggerBlockScript += 'set oWShell = CreateObject("WScript.Shell")'
		$debuggerBlockScript += 'oWShell.Run strCommand, 0, false'
		$debuggerBlockScript | Out-File -FilePath "$dirAppDeployTemp\AppDeployToolkit_BlockAppExecutionMessage.vbs" -Force -Encoding default -ErrorAction 'SilentlyContinue'
		[string]$debuggerBlockValue = "wscript.exe `"$dirAppDeployTemp\AppDeployToolkit_BlockAppExecutionMessage.vbs`""
		
		
		Write-Log -Message 'Create scheduled task to cleanup blocked applications in case installation is interrupted.' -Source ${CmdletName}
		If (Get-ScheduledTask -ContinueOnError $true | Select-Object -Property TaskName | Where-Object { $_.TaskName -eq "\$schTaskBlockedAppsName" }) {
			Write-Log -Message "Scheduled task [$schTaskBlockedAppsName] already exists." -Source ${CmdletName}
		}
		Else {
			[string[]]$schTaskCreationBatchFile = '@ECHO OFF'
			$schTaskCreationBatchFile += "powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -File `"$dirAppDeployTemp\$scriptFileName`" -CleanupBlockedApps -ReferringApplication `"$installName`""
			$schTaskCreationBatchFile | Out-File -FilePath "$dirAppDeployTemp\AppDeployToolkit_UnBlockApps.bat" -Force -Encoding default -ErrorAction 'SilentlyContinue'
			$schTaskCreation = Execute-Process -Path $exeSchTasks -Parameters "/Create /TN $schTaskBlockedAppsName /RU `"$LocalSystemNTAccount`" /SC ONSTART /TR `"$dirAppDeployTemp\AppDeployToolkit_UnBlockApps.bat`"" -PassThru
		}
		
		[string[]]$blockProcessName = $processName
		
		[string[]]$blockProcessName = $blockProcessName | ForEach-Object { $_ + '.exe' } -ErrorAction 'SilentlyContinue'
		
		
		ForEach ($blockProcess in $blockProcessName) {
			Write-Log -Message "Set the Image File Execution Option registry key to block execution of [$blockProcess]." -Source ${CmdletName}
			Set-RegistryKey -Key (Join-Path -Path $regKeyAppExecution -ChildPath $blockProcess) -Name 'Debugger' -Value $debuggerBlockValue -ContinueOnError $true
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Unblock-AppExecution {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) {
			Write-Log -Message "Bypassing Function [${CmdletName}] [Mode: $deployMode]" -Source ${CmdletName}
			Return
		}
		
		
		[psobject[]]$unblockProcesses = $null
		[psobject[]]$unblockProcesses += (Get-ChildItem -Path $regKeyAppExecution -Recurse -ErrorAction 'SilentlyContinue' | ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction 'SilentlyContinue'})
		ForEach ($unblockProcess in ($unblockProcesses | Where-Object { $_.Debugger -like '*AppDeployToolkit_BlockAppExecutionMessage*' })) {
			Write-Log -Message "Remove the Image File Execution Options registry key to unblock execution of [$($unblockProcess.PSChildName)]." -Source ${CmdletName} 
			$unblockProcess | Remove-ItemProperty -Name Debugger -ErrorAction 'SilentlyContinue'
		}
		
		
		If ($BlockExecution) {
			
			Set-Variable -Name BlockExecution -Value $false -Scope Script
		}
		
		
		[string]$schTaskBlockedAppsName = $installName + '_BlockedApps'
		If (Get-ScheduledTask -ContinueOnError $true | Select-Object -Property TaskName | Where-Object { $_.TaskName -eq "\$schTaskBlockedAppsName" }) {
			Write-Log -Message "Delete Scheduled Task [$schTaskBlockedAppsName]." -Source ${CmdletName}
			Execute-Process -Path $exeSchTasks -Parameters "/Delete /TN $schTaskBlockedAppsName /F"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-DeferHistory {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message 'Get deferral history...' -Source ${CmdletName}
		Get-RegistryKey -Key $regKeyDeferHistory -ContinueOnError $true
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-DeferHistory {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[string]$deferTimesRemaining,
		[Parameter(Mandatory=$false)]
		[string]$deferDeadline
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($deferTimesRemaining -and ($deferTimesRemaining -ge 0)) {
			Write-Log -Message "Set deferral history: [DeferTimesRemaining = $deferTimes]" -Source ${CmdletName}
			Set-RegistryKey -Key $regKeyDeferHistory -Name 'DeferTimesRemaining' -Value $deferTimesRemaining -ContinueOnError $true
		}
		If ($deferDeadline) {
			Write-Log -Message "Set deferral history: [DeferDeadline = $deferDeadline]" -Source ${CmdletName}
			Set-RegistryKey -Key $regKeyDeferHistory -Name 'DeferDeadline' -Value $deferDeadline -ContinueOnError $true
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-UniversalDate {

	[CmdletBinding()]
	Param (
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$DateTime = ((Get-Date -Format ($culture).DateTimeFormat.FullDateTimePattern).ToString()),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$ContinueOnError = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If ($DateTime -match 'Z$') { $DateTime = $DateTime -replace 'Z$', '' }
			[datetime]$DateTime = [datetime]::Parse($DateTime, $culture)
			
			
			Write-Log -Message "Convert the date [$DateTime] to a universal sortable date time pattern based on the current culture [$($culture.Name)]" -Source ${CmdletName}
			[string]$universalDateTime = (Get-Date -Date $DateTime -Format ($culture).DateTimeFormat.UniversalSortableDateTimePattern -ErrorAction 'Stop').ToString()
			Write-Output $universalDateTime
		}
		Catch {
			Write-Log -Message "The specified date/time [$DateTime] is not in a format recognized by the current culture [$($culture.Name)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "The specified date/time [$DateTime] is not in a format recognized by the current culture: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-RunningProcesses {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[psobject[]]$ProcessObjects
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($processObjects) {
			[string]$runningAppsCheck = ($processObjects | ForEach-Object { $_.ProcessName }) -join ','
			Write-Log -Message "Check for running application(s) [$runningAppsCheck]..." -Source ${CmdletName}
			
			
			
			[string]$processNames = ($processObjects | ForEach-Object { [regex]::Escape($_.ProcessName) }) -join '|'
			
			
			[System.Diagnostics.Process[]]$runningProcesses = Get-Process | Where-Object { $_.ProcessName -match $processNames }
			
			[array]$runningProcesses = $runningProcesses | ForEach-Object { $_ } | Select-Object -Property ProcessName, Description, ID
			If ($runningProcesses) {
				[string]$runningProcessList = ($runningProcesses | ForEach-Object { $_.ProcessName } | Select-Object -Unique) -join ','
				Write-Log -Message "The following processes are running: [$runningProcessList]" -Source ${CmdletName}
				Write-Log -Message 'Resolve process descriptions...' -Source ${CmdletName}
				
				
				
				
				ForEach ($runningProcess in $runningProcesses) {
					ForEach ($processObject in $processObjects) {
						If ($runningProcess.ProcessName -eq ($processObject.ProcessName -replace '.exe', '')) {
							If ($processObject.ProcessDescription) {
								$runningProcess | Add-Member -MemberType NoteProperty -Name Description -Value $processObject.ProcessDescription -Force -ErrorAction 'SilentlyContinue'
							}
						}
					}
					
					If (-not ($runningProcess.Description)) {
						$runningProcess | Add-Member -MemberType NoteProperty -Name Description -Value $runningProcess.ProcessName -Force -ErrorAction 'SilentlyContinue'
					}
				}
			}
			Else {
				Write-Log -Message 'Application(s) are not running.' -Source ${CmdletName}
			}
			
			Write-Log -Message 'Finished checking running application(s).' -Source ${CmdletName}
			Write-Output $runningProcesses
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-InstallationWelcome {

	[CmdletBinding()]
	Param (
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$CloseApps,
		
		[Parameter(Mandatory=$false)]
		[switch]$Silent = $false,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$CloseAppsCountdown = 0,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$ForceCloseAppsCountdown = 0,
		
		[Parameter(Mandatory=$false)]
		[switch]$PersistPrompt = $false,
		
		[Parameter(Mandatory=$false)]
		[switch]$BlockExecution = $false,
		
		[Parameter(Mandatory=$false)]
		[switch]$AllowDefer = $false,
		
		[Parameter(Mandatory=$false)]
		[switch]$AllowDeferCloseApps = $false,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$DeferTimes = 0,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$DeferDays = 0,
		
		[Parameter(Mandatory=$false)]
		[string]$DeferDeadline = '',
		
		[Parameter(Mandatory=$false)]
		[switch]$CheckDiskSpace = $false,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$RequiredDiskSpace = 0,
		
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$MinimizeWindows = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) { $Silent = $true }
		
		
		If ($CheckDiskSpace) {
			Write-Log -Message 'Evaluate disk space requirements.' -Source ${CmdletName}
			[double]$freeDiskSpace = Get-FreeDiskSpace
			If ($RequiredDiskSpace -eq 0) {
				Try {
					
					$fso = New-Object -ComObject Scripting.FileSystemObject -ErrorAction 'Stop'
					$RequiredDiskSpace = [math]::Round((($fso.GetFolder($scriptParentPath).Size) / 1MB))
				}
				Catch {
					Write-Log -Message "Failed to calculate disk space requirement from source files. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				}
			}
			If ($freeDiskSpace -lt $RequiredDiskSpace) {
				Write-Log -Message "Failed to meet minimum disk space requirement. Space Required [$RequiredDiskSpace MB], Space Available [$freeDiskSpace MB]." -Severity 3 -Source ${CmdletName}
				If (-not $Silent) {
					Show-InstallationPrompt -Message ($configDiskSpaceMessage -f $installTitle, $RequiredDiskSpace, ($freeDiskSpace)) -ButtonRightText 'OK' -Icon 'Error'
				}
				Exit-Script -ExitCode $configInstallationUIExitCode
			}
			Else {
				Write-Log -Message 'Successfully passed minimum disk space requirement check.' -Source ${CmdletName}
			}
		}
		
		If ($CloseApps) {
			
			[psobject[]]$processObjects = @()
			
			ForEach ($process in ($CloseApps -split ',' | Where-Object { -not ([string]::IsNullOrEmpty($_)) })) {
				$process = $process -split '='
				$processObjects += New-Object -TypeName PSObject -Property @{
					ProcessName = $process[0]
					ProcessDescription = $process[1]
				}
			}
		}
		
		
		If (($allowDefer) -or ($AllowDeferCloseApps)) {
			
			$allowDefer = $true
			
			
			$deferHistory = Get-DeferHistory
			$deferHistoryTimes = $deferHistory | Select-Object -ExpandProperty DeferTimesRemaining -ErrorAction 'SilentlyContinue'
			$deferHistoryDeadline = $deferHistory | Select-Object -ExpandProperty DeferDeadline -ErrorAction 'SilentlyContinue'
			
			
			$checkDeferDays = $false
			$checkDeferDeadline = $false
			If ($DeferDays -ne 0) { $checkDeferDays = $true }
			If ($DeferDeadline) { $checkDeferDeadline = $true }
			If ($DeferTimes -ne 0) {
				If ($deferHistoryTimes -ge 0) {
					Write-Log -Message "Defer history shows [$($deferHistory.DeferTimesRemaining)] deferrals remaining." -Source ${CmdletName}
					$DeferTimes = $deferHistory.DeferTimesRemaining - 1
				}
				Else {
					$DeferTimes = $DeferTimes - 1
				}
				Write-Log -Message "User has [$deferTimes] deferrals remaining." -Source ${CmdletName}
				If ($DeferTimes -lt 0) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			Else {
				[string]$DeferTimes = ''
			}
			If ($checkDeferDays -and $allowDefer) {
				If ($deferHistoryDeadline) {
					Write-Log -Message "Defer history shows a deadline date of [$deferHistoryDeadline]." -Source ${CmdletName}
					[string]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferHistoryDeadline
				}
				Else {
					[string]$deferDeadlineUniversal = Get-UniversalDate -DateTime (Get-Date -Date ((Get-Date).AddDays($deferDays)) -Format ($culture).DateTimeFormat.FullDateTimePattern)
				}
				Write-Log -Message "User has until [$deferDeadlineUniversal] before deferral expires." -Source ${CmdletName}
				If ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			If ($checkDeferDeadline -and $allowDefer) {
				
				Try {
					[string]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferDeadline -ErrorAction 'Stop'
				}
				Catch {
					Write-Log -Message "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z'. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					Throw "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z': $($_.Exception.Message)"
				}
				Write-Log -Message "User has until [$deferDeadlineUniversal] remaining." -Source ${CmdletName}
				If ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
		}
		If (($deferTimes -lt 0) -and (-not ($deferDeadlineUniversal))) { $AllowDefer = $false }
		
		
		If (-not ($deployModeSilent) -and (-not ($silent))) {
			If ($forceCloseAppsCountdown -gt 0) {
				
				$closeAppsCountdown = $forceCloseAppsCountdown
				
				[boolean]$forceCloseAppsCountdown = $true
			}
			Set-Variable -Name closeAppsCountdownGlobal -Value $closeAppsCountdown -Scope Script
			While ((Get-RunningProcesses -ProcessObjects $processObjects | Select-Object -Property * -OutVariable RunningProcesses) -or (($promptResult -ne 'Defer') -and ($promptResult -ne 'Close'))) {
				[string]$runningProcessDescriptions = ($runningProcesses | Select-Object -ExpandProperty Description | Select-Object -Unique | Sort-Object) -join ','
				
				If ($allowDefer) {
					
					If ($AllowDeferCloseApps -and ($runningProcessDescriptions -eq '')) {
						Break
					}
					
					ElseIf (($promptResult -ne 'Close') -or (($runningProcessDescriptions -ne '') -and ($promptResult -ne 'Continue'))) {
						[string]$promptResult = Show-WelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -ForceCloseAppsCountdown $forceCloseAppsCountdown -PersistPrompt $PersistPrompt -AllowDefer -DeferTimes $deferTimes -DeferDeadline $deferDeadlineUniversal -MinimizeWindows $minimizeWindows
					}
				}
				
				ElseIf ($runningProcessDescriptions -ne '') {
					[string]$promptResult = Show-WelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -ForceCloseAppsCountdown $forceCloseAppsCountdown -PersistPrompt $PersistPrompt -MinimizeWindows $minimizeWindows
				}
				
				Else {
					Break
				}
				
				
				If ($promptResult -eq 'Continue') {
					Write-Log -Message 'User selected to continue...' -Source ${CmdletName}
					Start-Sleep -Seconds 2
					
					
					If (-not ($runningProcesses)) { Break }
				}
				
				ElseIf ($promptResult -eq 'Close') {
					Write-Log -Message 'User selected to force the application(s) to close...' -Source ${CmdletName}
					ForEach ($runningProcess in $runningProcesses) {
						Write-Log -Message "Stop process $($runningProcess.Name)..." -Source ${CmdletName}
						Stop-Process -Id ($runningProcess | Select-Object -ExpandProperty Id) -Force -ErrorAction 'SilentlyContinue'
					}
					Start-Sleep -Seconds 2
				}
				
				ElseIf ($promptResult -eq 'Timeout') {
					Write-Log -Message 'Installation not actioned before the timeout value.' -Source ${CmdletName}
					$BlockExecution = $false
					
					If (($deferTimes) -or ($deferDeadlineUniversal)) {
						Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal
					}
					
					If ($script:welcomeTimer) {
						Try {
							$script:welcomeTimer.Dispose()
							$script:welcomeTimer = $null
						}
						Catch { }
					}
					
					Exit-Script -ExitCode $configInstallationUIExitCode
				}
				
				ElseIf ($promptResult -eq 'Defer') {
					Write-Log -Message 'Installation deferred by the user.' -Source ${CmdletName}
					$BlockExecution = $false
					
					Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal
					
					Exit-Script -ExitCode $configInstallationDeferExitCode
				}
			}
		}
		
		
		If (($Silent -or $deployModeSilent) -and $CloseApps) {
			[array]$runningProcesses = $null
			[array]$runningProcesses = Get-RunningProcesses $processObjects
			If ($runningProcesses) {
				[string]$runningProcessDescriptions = ($runningProcesses | Select-Object -ExpandProperty Description | Select-Object -Unique | Sort-Object) -join ','
				Write-Log -Message "Force close application(s) [$($runningProcessDescriptions)] without prompting user." -Source ${CmdletName}
				$runningProcesses | Stop-Process -Force -ErrorAction 'SilentlyContinue'
				Start-Sleep -Seconds 2
			}
		}
		
		
		If (($processObjects | ForEach-Object { $_.ProcessName }) -match 'notes') {
			[string]$notesPath = Get-Item -Path $regKeyLotusNotes -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -ExpandProperty Path
			
			If ($notesPath) {
				[string]$notesNSDExecutable = Join-Path -Path $notesPath -ChildPath 'NSD.Exe'
				Try {
					If (Test-Path -Path $notesNSDExecutable -PathType Leaf -ErrorAction 'Stop') {
						Write-Log -Message "Execute [$notesNSDExecutable] with the -kill argument..." -Source ${CmdletName}
						[System.Diagnostics.Process]$notesNSDProcess = Start-Process -FilePath $notesNSDExecutable -ArgumentList '-kill' -WindowStyle Hidden -PassThru -ErrorAction 'Stop'
						
						If (-not ($notesNSDProcess.WaitForExit(10000))) {
							Write-Log -Message "[$notesNSDExecutable] did not end in a timely manner. Force terminate process." -Source ${CmdletName}
							Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
						}
					}
				}
				Catch {
					Write-Log -Message "Failed to launch [$notesNSDExecutable]. `n$(Resolve-Error)" -Source ${CmdletName}
				}
				
				Write-Log -Message "[$notesNSDExecutable] returned exit code [$($notesNSDProcess.Exitcode)]" -Source ${CmdletName}
				
				
				Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
			}
			
			
			[string[]]$notesPathExes = Get-ChildItem -Path $notesPath -Filter '*.exe' -Recurse | Select-Object -ExpandProperty BaseName | Sort-Object
			
			If ($notesPathExes) {
				[array]$processesIgnoringNotesExceptions = Compare-Object -ReferenceObject ($processObjects | Select-Object -ExpandProperty ProcessName | Sort-Object) -DifferenceObject $notesPathExes -IncludeEqual | Where-Object { ($_.SideIndicator -eq '<=') -or ($_.InputObject -eq 'notes') } | Select-Object -ExpandProperty InputObject
				[array]$processObjects = $processObjects | Where-Object { $processesIgnoringNotesExceptions -contains $_.ProcessName }
			}
		}
		
		
		If ($BlockExecution) {
			
			Set-Variable -Name BlockExecution -Value $BlockExecution -Scope Script
			Write-Log -Message '[-BlockExecution] parameter specified.' -Source ${CmdletName}
			Block-AppExecution -ProcessName ($processObjects | Select-Object -ExpandProperty ProcessName)
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-WelcomePrompt {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[string]$ProcessDescriptions,
		[Parameter(Mandatory=$false)]
		[int32]$CloseAppsCountdown,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ForceCloseAppsCountdown,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$PersistPrompt = $false,
		[Parameter(Mandatory=$false)]
		[switch]$AllowDefer = $false,
		[Parameter(Mandatory=$false)]
		[int32]$DeferTimes,
		[Parameter(Mandatory=$false)]
		[string]$DeferDeadline,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$MinimizeWindows = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If (-not $IsProcessUserInteractive) {
			[string]$promptResult = Invoke-PSCommandAsUser -PassThru -Command ([scriptblock]::Create("Show-WelcomePrompt -ProcessDescriptions '$ProcessDescriptions' -CloseAppsCountdown $CloseAppsCountdown -ForceCloseAppsCountdown `$$ForceCloseAppsCountdown -PersistPrompt `$$PersistPrompt -AllowDefer:`$$AllowDefer -DeferTimes $DeferTimes -DeferDeadline '$DeferDeadline' -MinimizeWindows `$$MinimizeWindows"))
			Return $promptResult
		}

		
		[boolean]$showCloseApps = $false
		[boolean]$showDefer = $false
		[boolean]$persistWindow = $false
		
		
		[datetime]$startTime = Get-Date
		[datetime]$countdownTime = $startTime
		
		
		If ($CloseAppsCountdown) {
			If ($CloseAppsCountdown -gt $configInstallationUITimeout) {
				Throw 'The close applications countdown time cannot be longer than the timeout specified in the XML configuration for installation UI dialogs to timeout.'
			}
		}
		
		
		If ($processDescriptions) {
			Write-Log -Message "Prompt user to close application(s) [$runningProcessDescriptions]..." -Source ${CmdletName}
			$showCloseApps = $true
		}
		If (($allowDefer) -and (($deferTimes -ge 0) -or ($deferDeadline))) {
			Write-Log -Message 'User has the option to defer.' -Source ${CmdletName}
			$showDefer = $true
			If ($deferDeadline) {
				
				$deferDeadline = $deferDeadline -replace 'Z',''
				
				[string]$deferDeadline = (Get-Date -Date $deferDeadline).ToString()
			}
		}
		
		
		If ($showDefer) {
			If ($closeAppsCountdown -gt 0) {
				Write-Log -Message "Close applications countdown has [$closeAppsCountdown] seconds remaining." -Source ${CmdletName}
				$showCountdown = $true
			}
			If ($persistPrompt) { $persistWindow = $true }
		}
		
		
		If ($forceCloseAppsCountdown -eq $true) {
			Write-Log -Message "Close applications countdown has [$closeAppsCountdown] seconds remaining." -Source ${CmdletName}
			$showCountdown = $true
		}
		
		[string[]]$processDescriptions = $processDescriptions.Split(',')
		[System.Windows.Forms.Application]::EnableVisualStyles()
		
		$formWelcome = New-Object -TypeName System.Windows.Forms.Form
		$pictureBanner = New-Object -TypeName System.Windows.Forms.PictureBox
		$labelAppName = New-Object -TypeName System.Windows.Forms.Label
		$labelCountdown = New-Object -TypeName System.Windows.Forms.Label
		$labelDefer = New-Object -TypeName System.Windows.Forms.Label
		$listBoxCloseApps = New-Object -TypeName System.Windows.Forms.ListBox
		$buttonContinue = New-Object -TypeName System.Windows.Forms.Button
		$buttonDefer = New-Object -TypeName System.Windows.Forms.Button
		$buttonCloseApps = New-Object -TypeName System.Windows.Forms.Button
		$buttonAbort = New-Object -TypeName System.Windows.Forms.Button
		$formWelcomeWindowState = New-Object -TypeName System.Windows.Forms.FormWindowState
		$flowLayoutPanel = New-Object -TypeName System.Windows.Forms.FlowLayoutPanel
		$panelButtons = New-Object -TypeName System.Windows.Forms.Panel
		
		
		[scriptblock]$Form_Cleanup_FormClosed = {
			Try {
				$labelAppName.remove_Click($handler_labelAppName_Click)
				$labelDefer.remove_Click($handler_labelDefer_Click)
				$buttonCloseApps.remove_Click($buttonCloseApps_OnClick)
				$buttonContinue.remove_Click($buttonContinue_OnClick)
				$buttonDefer.remove_Click($buttonDefer_OnClick)
				$buttonAbort.remove_Click($buttonAbort_OnClick)
				$script:welcomeTimer.remove_Tick($timer_Tick)
				$timerPersist.remove_Tick($timerPersist_Tick)
				$formWelcome.remove_Load($Form_StateCorrection_Load)
				$formWelcome.remove_FormClosed($Form_Cleanup_FormClosed)
			}
			Catch {
			}
		}
		
		[scriptblock]$Form_StateCorrection_Load = {
			
			$formWelcome.WindowState = 'Normal'
			$formWelcome.AutoSize = $true
			$formWelcome.TopMost = $true
			$formWelcome.BringToFront()
			
			Set-Variable -Name formWelcomeStartPosition -Value $formWelcome.Location -Scope Script
			
			
			[datetime]$currentTime = Get-Date
			[datetime]$countdownTime = $startTime.AddSeconds($CloseAppsCountdown)
			$script:welcomeTimer.Start()
			
			
			[timespan]$remainingTime = $countdownTime.Subtract($currentTime)
			[string]$labelCountdownSeconds = [string]::Format('{0}:{1:d2}:{2:d2}', $remainingTime.Hours, $remainingTime.Minutes, $remainingTime.Seconds)
			$labelCountdown.Text = "$configClosePromptCountdownMessage`n$labelCountdownSeconds"
		}
		
		
		If (-not ($script:welcomeTimer)) {
			$script:welcomeTimer = New-Object -TypeName System.Windows.Forms.Timer
		}
		
		If ($showCountdown) {
			[scriptblock]$timer_Tick = {
				
				[datetime]$currentTime = Get-Date
				[datetime]$countdownTime = $startTime.AddSeconds($CloseAppsCountdown)
				[timespan]$remainingTime = $countdownTime.Subtract($currentTime)
				Set-Variable -Name closeAppsCountdownGlobal -Value $remainingTime.TotalSeconds -Scope Script
				
				
				If ($countdownTime -lt $currentTime) {
					Write-Log -Message 'Close application(s) countdown timer has elapsed. Force closing application(s).' -Source ${CmdletName}
					$buttonCloseApps.PerformClick()
				}
				Else {
					
					[string]$labelCountdownSeconds = [string]::Format('{0}:{1:d2}:{2:d2}', $remainingTime.Hours, $remainingTime.Minutes, $remainingTime.Seconds)
					$labelCountdown.Text = "$configClosePromptCountdownMessage`n$labelCountdownSeconds"
					[System.Windows.Forms.Application]::DoEvents()
				}
			}
		}
		Else {
			$script:welcomeTimer.Interval = ($configInstallationUITimeout * 1000)
			[scriptblock]$timer_Tick = { $buttonAbort.PerformClick() }
		}
		
		$script:welcomeTimer.add_Tick($timer_Tick)
		
		
		If ($persistWindow) {
			$timerPersist = New-Object -TypeName System.Windows.Forms.Timer
			$timerPersist.Interval = ($configInstallationPersistInterval * 1000)
			[scriptblock]$timerPersist_Tick = { Refresh-InstallationWelcome }
			$timerPersist.add_Tick($timerPersist_Tick)
			$timerPersist.Start()
		}
		
		
		$formWelcome.Controls.Add($pictureBanner)
		$formWelcome.Controls.Add($buttonAbort)
		
		
		
		$paddingNone = New-Object -TypeName System.Windows.Forms.Padding
		$paddingNone.Top = 0
		$paddingNone.Bottom = 0
		$paddingNone.Left = 0
		$paddingNone.Right = 0
		
		
		$labelPadding = '20,0,20,0'
		
		
		$buttonWidth = 110
		$buttonHeight = 23
		$buttonPadding = 50
		$buttonSize = New-Object -TypeName System.Drawing.Size
		$buttonSize.Width = $buttonWidth
		$buttonSize.Height = $buttonHeight
		$buttonPadding = New-Object -TypeName System.Windows.Forms.Padding
		$buttonPadding.Top = 0
		$buttonPadding.Bottom = 5
		$buttonPadding.Left = 50
		$buttonPadding.Right = 0
		
		
		$pictureBanner.DataBindings.DefaultDataSourceUpdateMode = 0
		$pictureBanner.ImageLocation = $appDeployLogoBanner
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 0
		$System_Drawing_Point.Y = 0
		$pictureBanner.Location = $System_Drawing_Point
		$pictureBanner.Name = 'pictureBanner'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 50
		$System_Drawing_Size.Width = 450
		$pictureBanner.Size = $System_Drawing_Size
		$pictureBanner.SizeMode = 'CenterImage'
		$pictureBanner.Margin = $paddingNone
		$pictureBanner.TabIndex = 0
		$pictureBanner.TabStop = $false
		
		
		$labelAppName.DataBindings.DefaultDataSourceUpdateMode = 0
		$labelAppName.Name = 'labelAppName'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		If (-not $showCloseApps) {
			$System_Drawing_Size.Height = 40
		}
		Else {
			$System_Drawing_Size.Height = 65
		}
		$System_Drawing_Size.Width = 450
		$labelAppName.Size = $System_Drawing_Size
		$System_Drawing_Size.Height = 0
		$labelAppName.MaximumSize = $System_Drawing_Size
		$labelAppName.Margin = '0,15,0,15'
		$labelAppName.Padding = $labelPadding
		$labelAppName.TabIndex = 1
		
		
		If ($showCloseApps) {
			$labelAppNameText = $configClosePromptMessage
		}
		ElseIf ($showDefer) {
			$labelAppNameText = "$configDeferPromptWelcomeMessage `n$installTitle"
		}
		$labelAppName.Text = $labelAppNameText
		$labelAppName.TextAlign = 'TopCenter'
		$labelAppName.Anchor = 'Top'
		$labelAppName.AutoSize = $true
		$labelAppName.add_Click($handler_labelAppName_Click)
		
		
		$listBoxCloseApps.DataBindings.DefaultDataSourceUpdateMode = 0
		$listBoxCloseApps.FormattingEnabled = $true
		$listBoxCloseApps.Name = 'listBoxCloseApps'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 100
		$System_Drawing_Size.Width = 300
		$listBoxCloseApps.Size = $System_Drawing_Size
		$listBoxCloseApps.Margin = '75,0,0,0'
		$listBoxCloseApps.TabIndex = 3
		ForEach ($processDescription in $ProcessDescriptions) {
			$listboxCloseApps.Items.Add($processDescription) | Out-Null
		}
		
		
		$labelDefer.DataBindings.DefaultDataSourceUpdateMode = 0
		$labelDefer.Name = 'labelDefer'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 90
		$System_Drawing_Size.Width = 450
		$labelDefer.Size = $System_Drawing_Size
		$System_Drawing_Size.Height = 0
		$labelDefer.MaximumSize = $System_Drawing_Size
		$labelDefer.Margin = $paddingNone
		$labelDefer.Padding = $labelPadding
		$labelDefer.TabIndex = 4
		$deferralText = "$configDeferPromptExpiryMessage`n"
		If ($deferTimes -ge 0) {
			$deferralText = "$deferralText `n$configDeferPromptRemainingDeferrals $($deferTimes + 1)"
		}
		If ($deferDeadline) {
			$deferralText = "$deferralText `n$configDeferPromptDeadline $deferDeadline"
		}
		If (($deferTimes -lt 0) -and (-not $DeferDeadline)) {
			$deferralText = "$deferralText `n$configDeferPromptNoDeadline"
		}
		$deferralText = "$deferralText `n`n$configDeferPromptWarningMessage"
		$labelDefer.Text = $deferralText
		$labelDefer.TextAlign = 'MiddleCenter'
		$labelDefer.AutoSize = $true
		$labelDefer.add_Click($handler_labelDefer_Click)
		
		
		$labelCountdown.DataBindings.DefaultDataSourceUpdateMode = 0
		$labelCountdown.Name = 'labelCountdown'
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 40
		$System_Drawing_Size.Width = 450
		$labelCountdown.Size = $System_Drawing_Size
		$System_Drawing_Size.Height = 0
		$labelCountdown.MaximumSize = $System_Drawing_Size
		$labelCountdown.Margin = $paddingNone
		$labelCountdown.Padding = $labelPadding
		$labelCountdown.TabIndex = 4
		$labelCountdown.Font = 'Microsoft Sans Serif, 9pt, style=Bold'
		$labelCountdown.Text = '00:00:00'
		$labelCountdown.TextAlign = 'MiddleCenter'
		$labelCountdown.AutoSize = $true
		$labelCountdown.add_Click($handler_labelDefer_Click)
		
		
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 0
		$System_Drawing_Point.Y = 50
		$flowLayoutPanel.Location = $System_Drawing_Point
		$flowLayoutPanel.AutoSize = $true
		$flowLayoutPanel.Anchor = 'Top'
		$flowLayoutPanel.FlowDirection = 'TopDown'
		$flowLayoutPanel.WrapContents = $true
		$flowLayoutPanel.Controls.Add($labelAppName)
		If ($showCloseApps) { $flowLayoutPanel.Controls.Add($listBoxCloseApps) }
		If ($showDefer) {
			$flowLayoutPanel.Controls.Add($labelDefer)
		}
		If ($showCloseApps -and $showCountdown) {
			$flowLayoutPanel.Controls.Add($labelCountdown)
		}
		
		
		$buttonCloseApps.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonCloseApps.Location = '15,0'
		$buttonCloseApps.Name = 'buttonCloseApps'
		$buttonCloseApps.Size = $buttonSize
		$buttonCloseApps.TabIndex = 5
		$buttonCloseApps.Text = $configClosePromptButtonClose
		$buttonCloseApps.DialogResult = 'Yes'
		$buttonCloseApps.AutoSize = $true
		$buttonCloseApps.UseVisualStyleBackColor = $true
		$buttonCloseApps.add_Click($buttonCloseApps_OnClick)
		
		
		$buttonDefer.DataBindings.DefaultDataSourceUpdateMode = 0
		If (-not $showCloseApps) {
			$buttonDefer.Location = '15,0'
		}
		Else {
			$buttonDefer.Location = '170,0'
		}
		$buttonDefer.Name = 'buttonDefer'
		$buttonDefer.Size = $buttonSize
		$buttonDefer.TabIndex = 6
		$buttonDefer.Text = $configClosePromptButtonDefer
		$buttonDefer.DialogResult = 'No'
		$buttonDefer.AutoSize = $true
		$buttonDefer.UseVisualStyleBackColor = $true
		$buttonDefer.add_Click($buttonDefer_OnClick)
		
		
		$buttonContinue.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonContinue.Location = '325,0'
		$buttonContinue.Name = 'buttonContinue'
		$buttonContinue.Size = $buttonSize
		$buttonContinue.TabIndex = 7
		$buttonContinue.Text = $configClosePromptButtonContinue
		$buttonContinue.DialogResult = 'OK'
		$buttonContinue.AutoSize = $true
		$buttonContinue.UseVisualStyleBackColor = $true
		$buttonContinue.add_Click($buttonContinue_OnClick)
		
		
		$buttonAbort.DataBindings.DefaultDataSourceUpdateMode = 0
		$buttonAbort.Name = 'buttonAbort'
		$buttonAbort.Size = '1,1'
		$buttonAbort.DialogResult = 'Abort'
		$buttonAbort.TabIndex = 5
		$buttonAbort.UseVisualStyleBackColor = $true
		$buttonAbort.add_Click($buttonAbort_OnClick)
		
		
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 0
		$System_Drawing_Size.Width = 0
		$formWelcome.Size = $System_Drawing_Size
		$formWelcome.Padding = $paddingNone
		$formWelcome.Margin = $paddingNone
		$formWelcome.DataBindings.DefaultDataSourceUpdateMode = 0
		$formWelcome.Name = 'WelcomeForm'
		$formWelcome.Text = $installTitle
		$formWelcome.StartPosition = 'CenterScreen'
		$formWelcome.FormBorderStyle = 'FixedDialog'
		$formWelcome.MaximizeBox = $false
		$formWelcome.MinimizeBox = $false
		$formWelcome.TopMost = $true
		$formWelcome.TopLevel = $true
		$formWelcome.Icon = New-Object -TypeName System.Drawing.Icon -ArgumentList $AppDeployLogoIcon
		$formWelcome.AutoSize = $true
		$formWelcome.Controls.Add($pictureBanner)
		$formWelcome.Controls.Add($flowLayoutPanel)
		
		
		$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
		$System_Drawing_Point.X = 0
		
		$System_Drawing_Point.Y = (($formWelcome.Size | Select-Object -ExpandProperty Height) - 10)
		$panelButtons.Location = $System_Drawing_Point
		$System_Drawing_Size = New-Object -TypeName System.Drawing.Size
		$System_Drawing_Size.Height = 40
		$System_Drawing_Size.Width = 450
		$panelButtons.Size = $System_Drawing_Size
		$panelButtons.AutoSize = $true
		$panelButtons.Anchor = 'Top'
		$padding = New-Object -TypeName System.Windows.Forms.Padding
		$padding.Top = 0
		$padding.Bottom = 0
		$padding.Left = 0
		$padding.Right = 0
		$panelButtons.Margin = $padding
		If ($showCloseApps) { $panelButtons.Controls.Add($buttonCloseApps) }
		If ($showDefer) { $panelButtons.Controls.Add($buttonDefer) }
		$panelButtons.Controls.Add($buttonContinue)
		
		
		$formWelcome.Controls.Add($panelButtons)
		
		
		$formWelcomeWindowState = $formWelcome.WindowState
		
		$formWelcome.add_Load($Form_StateCorrection_Load)
		
		$formWelcome.add_FormClosed($Form_Cleanup_FormClosed)
		
		Function Refresh-InstallationWelcome {
			$formWelcome.BringToFront()
			$formWelcome.Location = "$($formWelcomeStartPosition.X),$($formWelcomeStartPosition.Y)"
			$formWelcome.Refresh()
		}
		
		
		If ($minimizeWindows) { $shellApp.MinimizeAll() | Out-Null }
		
		
		$result = $formWelcome.ShowDialog()
		$formWelcome.Dispose()
		Switch ($result) {
			OK { $result = 'Continue' }
			No { $result = 'Defer'; $shellApp.UndoMinimizeAll() | Out-Null }
			Yes { $result = 'Close'}
			Abort { $result = 'Timeout'; $shellApp.UndoMinimizeAll() | Out-Null }
		}
		
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-InstallationRestartPrompt {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$CountdownSeconds = 60,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$CountdownNoHideSeconds = 30,
		[Parameter(Mandatory=$false)]
		[switch]$NoCountdown = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If ($deployModeNonInteractive) {
			Write-Log -Message "Bypass Installation Restart Prompt [Mode: $deployMode]" -Source ${CmdletName}
			Return
		}

		
		If (-not $IsProcessUserInteractive) {
			Invoke-PSCommandAsUser -Command ([scriptblock]::Create("Show-InstallationRestartPrompt -CountdownSeconds $CountdownSeconds -CountdownNoHideSeconds $CountdownNoHideSeconds -NoCountdown:`$$NoCountdown"))
			Return
		}

		
		[hashtable]$installRestartPromptParameters = $psBoundParameters
		
		
		If (Get-Process | Where-Object { $_.MainWindowTitle -match $configRestartPromptTitle }) {
			Write-Log -Message "${CmdletName} was invoked, but an existing restart prompt was detected. Canceling restart prompt." -Severity 2 -Source ${CmdletName}
			Return
		}
		
		[datetime]$startTime = Get-Date
		[datetime]$countdownTime = $startTime
		
		[System.Windows.Forms.Application]::EnableVisualStyles()
		$formRestart = New-Object -TypeName System.Windows.Forms.Form
		$labelCountdown = New-Object -TypeName System.Windows.Forms.Label
		$labelTimeRemaining = New-Object -TypeName System.Windows.Forms.Label
		$labelMessage = New-Object -TypeName System.Windows.Forms.Label
		$buttonRestartLater = New-Object -TypeName System.Windows.Forms.Button
		$picturebox = New-Object -TypeName System.Windows.Forms.PictureBox
		$buttonRestartNow = New-Object -TypeName System.Windows.Forms.Button
		$timerCountdown = New-Object -TypeName System.Windows.Forms.Timer
		$InitialFormWindowState = New-Object -TypeName System.Windows.Forms.FormWindowState
		
		Function Perform-Restart {
			Write-Log -Message 'Force restart the computer...' -Source ${CmdletName}
			Restart-Computer -Force
		}
		
		[scriptblock]$FormEvent_Load = {
			
			[datetime]$currentTime = Get-Date
			[datetime]$countdownTime = $startTime.AddSeconds($countdownSeconds)
			$timerCountdown.Start()
			
			[timespan]$remainingTime = $countdownTime.Subtract($currentTime)
			$labelCountdown.Text = [string]::Format('{0}:{1:d2}:{2:d2}', $remainingTime.Hours, $remainingTime.Minutes, $remainingTime.Seconds)
			If ($remainingTime.TotalSeconds -le $countdownNoHideSeconds) { $buttonRestartLater.Enabled = $false }
			$formRestart.WindowState = 'Normal'
			$formRestart.TopMost = $true
			$formRestart.BringToFront()
		}
		
		[scriptblock]$Form_StateCorrection_Load = {
			
			$formRestart.WindowState = $InitialFormWindowState
			$formRestart.AutoSize = $true
			$formRestart.TopMost = $true
			$formRestart.BringToFront()
			
			Set-Variable -Name formInstallationRestartPromptStartPosition -Value $formRestart.Location -Scope Script
		}
		
		
		If ($NoCountdown) {
			$timerPersist = New-Object -TypeName System.Windows.Forms.Timer
			$timerPersist.Interval = ($configInstallationRestartPersistInterval * 1000)
			[scriptblock]$timerPersist_Tick = {
				
				$formRestart.WindowState = 'Normal'
				$formRestart.TopMost = $true
				$formRestart.BringToFront()
				$formRestart.Location = "$($formInstallationRestartPromptStartPosition.X),$($formInstallationRestartPromptStartPosition.Y)"
				$formRestart.Refresh()
				[System.Windows.Forms.Application]::DoEvents()
			}
			$timerPersist.add_Tick($timerPersist_Tick)
			$timerPersist.Start()
		}
		
		[scriptblock]$buttonRestartLater_Click = {
			
			$formRestart.WindowState = 'Minimized'
			
			$timerPersist.Stop()
			$timerPersist.Start()
		}
		
		
		[scriptblock]$buttonRestartNow_Click = { Perform-Restart }
		
		
		[scriptblock]$formRestart_Resize = { If ($formRestart.WindowState -eq 'Minimized') { $formRestart.WindowState = 'Minimized' } }
		
		[scriptblock]$timerCountdown_Tick = {
			
			[datetime]$currentTime = Get-Date
			[datetime]$countdownTime = $startTime.AddSeconds($countdownSeconds)
			[timespan]$remainingTime = $countdownTime.Subtract($currentTime)
			
			If ($countdownTime -lt $currentTime) {
				$buttonRestartNow.PerformClick()
			}
			Else {
				
				$labelCountdown.Text = [string]::Format('{0}:{1:d2}:{2:d2}', $remainingTime.Hours, $remainingTime.Minutes, $remainingTime.Seconds)
				If ($remainingTime.TotalSeconds -le $countdownNoHideSeconds) {
					$buttonRestartLater.Enabled = $false
					
					If ($formRestart.WindowState -eq 'Minimized') {
						
						$formRestart.WindowState = 'Normal'
						$formRestart.TopMost = $true
						$formRestart.BringToFront()
						$formRestart.Location = "$($formInstallationRestartPromptStartPosition.X),$($formInstallationRestartPromptStartPosition.Y)"
						$formRestart.Refresh()
						[System.Windows.Forms.Application]::DoEvents()
					}
				}
				[System.Windows.Forms.Application]::DoEvents()
			}
		}
		
		
		[scriptblock]$Form_Cleanup_FormClosed = {
			Try {
				$buttonRestartLater.remove_Click($buttonRestartLater_Click)
				$buttonRestartNow.remove_Click($buttonRestartNow_Click)
				$formRestart.remove_Load($FormEvent_Load)
				$formRestart.remove_Resize($formRestart_Resize)
				$timerCountdown.remove_Tick($timerCountdown_Tick)
				$timerPersist.remove_Tick($timerPersist_Tick)
				$formRestart.remove_Load($Form_StateCorrection_Load)
				$formRestart.remove_FormClosed($Form_Cleanup_FormClosed)
			}
			Catch {
			}
		}
		
		
		If (-not $NoCountdown) {
			$formRestart.Controls.Add($labelCountdown)
			$formRestart.Controls.Add($labelTimeRemaining)
		}
		$formRestart.Controls.Add($labelMessage)
		$formRestart.Controls.Add($buttonRestartLater)
		$formRestart.Controls.Add($picturebox)
		$formRestart.Controls.Add($buttonRestartNow)
		$formRestart.ClientSize = '450,260'
		$formRestart.ControlBox = $false
		$formRestart.FormBorderStyle = 'FixedDialog'
		$formRestart.Icon = New-Object -TypeName System.Drawing.Icon -ArgumentList $AppDeployLogoIcon
		$formRestart.MaximizeBox = $false
		$formRestart.MinimizeBox = $false
		$formRestart.Name = 'formRestart'
		$formRestart.StartPosition = 'CenterScreen'
		$formRestart.Text = "$($configRestartPromptTitle): $installTitle"
		$formRestart.add_Load($FormEvent_Load)
		$formRestart.add_Resize($formRestart_Resize)
		
		
		$picturebox.Anchor = 'Top'
		$picturebox.Image = [System.Drawing.Image]::Fromfile($AppDeployLogoBanner)
		$picturebox.Location = '0,0'
		$picturebox.Name = 'picturebox'
		$picturebox.Size = '450,50'
		$picturebox.SizeMode = 'CenterImage'
		$picturebox.TabIndex = 1
		$picturebox.TabStop = $false
		
		
		$labelMessage.Location = '20,58'
		$labelMessage.Name = 'labelMessage'
		$labelMessage.Size = '400,79'
		$labelMessage.TabIndex = 3
		$labelMessage.Text = "$configRestartPromptMessage $configRestartPromptMessageTime `n`n$configRestartPromptMessageRestart"
		If ($NoCountdown) { $labelMessage.Text = $configRestartPromptMessage }
		$labelMessage.TextAlign = 'MiddleCenter'
		
		
		$labelTimeRemaining.Location = '20,138'
		$labelTimeRemaining.Name = 'labelTimeRemaining'
		$labelTimeRemaining.Size = '400,23'
		$labelTimeRemaining.TabIndex = 4
		$labelTimeRemaining.Text = $configRestartPromptTimeRemaining
		$labelTimeRemaining.TextAlign = 'MiddleCenter'
		
		
		$labelCountdown.Font = 'Microsoft Sans Serif, 18pt, style=Bold'
		$labelCountdown.Location = '20,165'
		$labelCountdown.Name = 'labelCountdown'
		$labelCountdown.Size = '400,30'
		$labelCountdown.TabIndex = 5
		$labelCountdown.Text = '00:00:00'
		$labelCountdown.TextAlign = 'MiddleCenter'
		
		
		$buttonRestartLater.Anchor = 'Bottom,Left'
		$buttonRestartLater.Location = '20,216'
		$buttonRestartLater.Name = 'buttonRestartLater'
		$buttonRestartLater.Size = '159,23'
		$buttonRestartLater.TabIndex = 0
		$buttonRestartLater.Text = $configRestartPromptButtonRestartLater
		$buttonRestartLater.UseVisualStyleBackColor = $true
		$buttonRestartLater.add_Click($buttonRestartLater_Click)
		
		
		$buttonRestartNow.Anchor = 'Bottom,Right'
		$buttonRestartNow.Location = '265,216'
		$buttonRestartNow.Name = 'buttonRestartNow'
		$buttonRestartNow.Size = '159,23'
		$buttonRestartNow.TabIndex = 2
		$buttonRestartNow.Text = $configRestartPromptButtonRestartNow
		$buttonRestartNow.UseVisualStyleBackColor = $true
		$buttonRestartNow.add_Click($buttonRestartNow_Click)
		
		
		If (-not $NoCountdown) { $timerCountdown.add_Tick($timerCountdown_Tick) }
		
		
		
		
		$InitialFormWindowState = $formRestart.WindowState
		
		$formRestart.add_Load($Form_StateCorrection_Load)
		
		$formRestart.add_FormClosed($Form_Cleanup_FormClosed)
		$formRestartClosing = [System.Windows.Forms.FormClosingEventHandler]{ $_.Cancel = $true }
		$formRestart.add_FormClosing($formRestartClosing)
		
		
		If ($deployAppScriptFriendlyName) {
			If ($NoCountdown) {
				Write-Log -Message "Invoking ${CmdletName} asynchronously with no countdown..." -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Invoking ${CmdletName} asynchronously with a [$countDownSeconds] second countdown..." -Source ${CmdletName}
			}
			[string]$installRestartPromptParameters = ($installRestartPromptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' '
			Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -Command `"$scriptPath`" -ReferringApplication `"$installName`" -ShowInstallationRestartPrompt $installRestartPromptParameters" -WindowStyle Hidden -ErrorAction 'SilentlyContinue'
		}
		Else {
			If ($NoCountdown) {
				Write-Log -Message 'Display restart prompt with no countdown.' -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Display restart prompt with a [$countDownSeconds] second countdown." -Source ${CmdletName}
			}
			
			
			Write-Output $formRestart.ShowDialog()
			$formRestart.Dispose()
			
			[System.Diagnostics.Process]$powershellProcess = Get-Process | Where-Object { $_.MainWindowTitle -match $installTitle }
			[Microsoft.VisualBasic.Interaction]::AppActivate($powershellProcess.ID)
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-BalloonTip {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0)]
		[ValidateNotNullOrEmpty()]
		[string]$BalloonTipText,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
		[string]$BalloonTipTitle = $installTitle,
		[Parameter(Mandatory=$false,Position=2)]
		[ValidateSet('Error','Info','None','Warning')]
		[System.Windows.Forms.ToolTipIcon]$BalloonTipIcon = 'Info',
		[Parameter(Mandatory=$false,Position=3)]
		[ValidateNotNullorEmpty()]
		[int32]$BalloonTipTime = 10000
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		If (($deployModeSilent) -or (-not $configShowBalloonNotifications)) { Return }

		
		If (-not $IsProcessUserInteractive) {
			Invoke-PSCommandAsUser -Command ([scriptblock]::Create("Show-BalloonTip -BalloonTipText '$BalloonTipText' -BalloonTipTitle '$BalloonTipTitle' -BalloonTipIcon '$BalloonTipIcon' -BalloonTipTime $BalloonTipTime"))
			Return
		}
		
		
		If ($global:notifyIcon) { Try { $global:notifyIcon.Dispose() } Catch {} }
		
		
		Try {
			[string]$callingFunction = (Get-Variable -Name MyInvocation -Scope 1 -ErrorAction 'SilentlyContinue').Value.MyCommand.Name
		}
		Catch { }
		
		If ($callingFunction -eq 'Exit-Script') {
			Write-Log -Message "Display balloon tip notification asyhchronously with message [$BalloonTipText]" -Source ${CmdletName}
			
			[scriptblock]$notifyIconScriptBlock = {
				Param (
					[Parameter(Mandatory=$true,Position=0)]
					[ValidateNotNullOrEmpty()]
					[string]$BalloonTipText,
					[Parameter(Mandatory=$false,Position=1)]
					[ValidateNotNullorEmpty()]
					[string]$BalloonTipTitle,
					[Parameter(Mandatory=$false,Position=2)]
					[ValidateSet('Error','Info','None','Warning')]
					$BalloonTipIcon, 
					[Parameter(Mandatory=$false,Position=3)]
					[ValidateNotNullorEmpty()]
					[int32]$BalloonTipTime,
					[Parameter(Mandatory=$false,Position=4)]
					[ValidateNotNullorEmpty()]
					[string]$AppDeployLogoIcon
				)
				
				
				Add-Type -AssemblyName System.Windows.Forms -ErrorAction 'Stop'
				Add-Type -AssemblyName System.Drawing -ErrorAction 'Stop'
				
				[Windows.Forms.ToolTipIcon]$BalloonTipIcon = $BalloonTipIcon
				$global:notifyIcon = New-Object -TypeName Windows.Forms.NotifyIcon -Property @{
					BalloonTipIcon = $BalloonTipIcon
					BalloonTipText = $BalloonTipText
					BalloonTipTitle = $BalloonTipTitle
					Icon = New-Object -TypeName System.Drawing.Icon -ArgumentList $AppDeployLogoIcon
					Text = -join $BalloonTipText[0..62]
					Visible = $true
				}
				
				
				$global:NotifyIcon.ShowBalloonTip($BalloonTipTime)
				
				
				Start-Sleep -Milliseconds ($BalloonTipTime)
				$global:notifyIcon.Dispose()
			}
			
			
			Try {
				Execute-Process -Path "$PSHOME\powershell.exe" -Parameters "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -Command & {$notifyIconScriptBlock} '$BalloonTipText' '$BalloonTipTitle' '$BalloonTipIcon' '$BalloonTipTime' '$AppDeployLogoIcon'" -NoWait -WindowStyle Hidden -CreateNoWindow
			}
			Catch { }
		}
		
		Else {
			Write-Log -Message "Display balloon tip notification with message [$BalloonTipText]" -Source ${CmdletName}
			[Windows.Forms.ToolTipIcon]$BalloonTipIcon = $BalloonTipIcon
			$global:notifyIcon = New-Object -TypeName Windows.Forms.NotifyIcon -Property @{
				BalloonTipIcon = $BalloonTipIcon
				BalloonTipText = $BalloonTipText
				BalloonTipTitle = $BalloonTipTitle
				Icon = New-Object -TypeName System.Drawing.Icon -ArgumentList $AppDeployLogoIcon
				Text = -join $BalloonTipText[0..62]
				Visible = $true
			}
			
			
			$global:NotifyIcon.ShowBalloonTip($BalloonTipTime)
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Show-InstallationProgress {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$StatusMessage = $configProgressMessageInstall,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Default','BottomRight')]
		[string]$WindowLocation = 'Default',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$TopMost = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($deployModeSilent) { Return }

		
		If (($statusMessage -eq $configProgressMessageInstall) -and ($deploymentType -eq 'Uninstall')) {
			$StatusMessage = $configProgressMessageUninstall
		}
		
		If ($envHost.Name -match 'PowerGUI') {
			Write-Log -Message "$($envHost.Name) is not a supported host for WPF multithreading. Progress dialog with message [$statusMessage] will not be displayed." -Severity 2 -Source ${CmdletName}
			Return
		}
		
		
		If (-not $IsProcessUserInteractive) {
			Invoke-PSCommandAsUser -NoWait -Command ([scriptblock]::Create("Show-InstallationProgress -StatusMessage '$StatusMessage' -WindowLocation '$WindowLocation' -TopMost `$$TopMost"))
			Return
		}
		
		
		If (Test-Path -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -PathType 'Leaf') {
			$StatusMessage | Export-Clixml -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -Force
			Return
		}
		Else {
			$StatusMessage | Export-Clixml -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -Force
			
			$balloonText = "$deploymentTypeName $configBalloonTextStart"
			Show-BalloonTip -BalloonTipIcon 'Info' -BalloonTipText $balloonText
		}
		
		
		If ($global:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -ne 'Running') {
			
			$global:ProgressSyncHash = [hashtable]::Synchronized(@{ })
			$global:ProgressSyncHash.StatusMessage = $statusMessage
			
			$global:ProgressRunspace = [runspacefactory]::CreateRunspace()
			$global:ProgressRunspace.ApartmentState = 'STA'
			$global:ProgressRunspace.ThreadOptions = 'ReuseThread'
			$global:ProgressRunspace.Open()
			
			$global:ProgressRunspace.SessionStateProxy.SetVariable('progressSyncHash', $global:ProgressSyncHash)
			
			$global:ProgressRunspace.SessionStateProxy.SetVariable('installTitle', $installTitle)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('windowLocation', $windowLocation)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('topMost', [string]$topMost)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('appDeployLogoBanner', $appDeployLogoBanner)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('statusMessage', $statusMessage)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('AppDeployLogoIcon', $AppDeployLogoIcon)
			$global:ProgressRunspace.SessionStateProxy.SetVariable('dpiScale', $dpiScale)
			
			
			$powershell = [PowerShell]::Create()
			$powershell.Runspace = $global:ProgressRunspace
			$powershell.AddScript({
				[Xml.XmlDocument]$xamlProgress = @'
				<Window
				xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
				xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
				x:Name="Window" Title=""
				MaxHeight="200" MinHeight="180" Height="180"
				MaxWidth="456" MinWidth="456" Width="456" Padding="0,0,0,0" Margin="0,0,0,0"
				WindowStartupLocation = "Manual"
				Top=""
				Left=""
				Topmost=""
				ResizeMode="NoResize"
				Icon=""
				ShowInTaskbar="True" >
				<Window.Resources>
					<Storyboard x:Key="Storyboard1" RepeatBehavior="Forever">
						<DoubleAnimationUsingKeyFrames BeginTime="00:00:00" Storyboard.TargetName="ellipse" Storyboard.TargetProperty="(UIElement.RenderTransform).(TransformGroup.Children)[2].(RotateTransform.Angle)">
						<SplineDoubleKeyFrame KeyTime="00:00:02" Value="360"/>
						</DoubleAnimationUsingKeyFrames>
					</Storyboard>
				</Window.Resources>
				<Window.Triggers>
					<EventTrigger RoutedEvent="FrameworkElement.Loaded">
						<BeginStoryboard Storyboard="{StaticResource Storyboard1}"/>
					</EventTrigger>
				</Window.Triggers>
				<Grid Background="
					<Grid.RowDefinitions>
						<RowDefinition Height="50"/>
						<RowDefinition Height="100"/>
					</Grid.RowDefinitions>
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="45"></ColumnDefinition>
						<ColumnDefinition Width="*"></ColumnDefinition>
					</Grid.ColumnDefinitions>
					<Image x:Name = "ProgressBanner" Grid.ColumnSpan="2" Margin="0,0,0,0" Source=""></Image>
					<TextBlock x:Name = "ProgressText" Grid.Row="1" Grid.Column="1" Margin="0,5,45,10" Text="" FontSize="15" FontFamily="Microsoft Sans Serif" HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center" Padding="15" TextWrapping="Wrap"></TextBlock>
					<Ellipse x:Name = "ellipse" Grid.Row="1" Grid.Column="0" Margin="0,0,0,0" StrokeThickness="5" RenderTransformOrigin="0.5,0.5" Height="25" Width="25" HorizontalAlignment="Right" VerticalAlignment="Center">
						<Ellipse.RenderTransform>
							<TransformGroup>
								<ScaleTransform/>
								<SkewTransform/>
								<RotateTransform/>
							</TransformGroup>
						</Ellipse.RenderTransform>
						<Ellipse.Stroke>
							<LinearGradientBrush EndPoint="0.445,0.997" StartPoint="0.555,0.003">
								<GradientStop Color="White" Offset="0"/>
								<GradientStop Color="
							</LinearGradientBrush>
						</Ellipse.Stroke>
					</Ellipse>
					</Grid>
				</Window>
'@
				
				
				$screen = [System.Windows.Forms.Screen]::PrimaryScreen
				$screenWorkingArea = $screen.WorkingArea
				[int32]$screenWidth = $screenWorkingArea | Select-Object -ExpandProperty Width
				[int32]$screenHeight = $screenWorkingArea | Select-Object -ExpandProperty Height
				
				If ($windowLocation -eq 'BottomRight') {
					$xamlProgress.Window.Left = [string]($screenWidth - $xamlProgress.Window.Width - 10)
					$xamlProgress.Window.Top = [string]($screenHeight - $xamlProgress.Window.Height - 10)
				}
				
				Else {
					
					$xamlProgress.Window.Left = [string](($screenWidth / (2 * ($dpiscale / 100) )) - (($xamlProgress.Window.Width / 2)))
					$xamlProgress.Window.Top = [string]($screenHeight / 9.5)
				}
				$xamlProgress.Window.TopMost = $topMost
				$xamlProgress.Window.Icon = $AppDeployLogoIcon
				$xamlProgress.Window.Grid.Image.Source = $appDeployLogoBanner
				$xamlProgress.Window.Grid.TextBlock.Text = $statusMessage
				$xamlProgress.Window.Title = $installTitle
				
				$progressReader = New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xamlProgress
				$global:ProgressSyncHash.Window = [Windows.Markup.XamlReader]::Load($progressReader)
				$global:ProgressSyncHash.ProgressText = $global:ProgressSyncHash.Window.FindName('ProgressText')
				
				$global:ProgressSyncHash.Window.Add_Closing({ $_.Cancel = $true })
				
				$global:ProgressSyncHash.Window.Add_MouseLeftButtonDown({ $global:ProgressSyncHash.Window.DragMove() })
				
				$global:ProgressSyncHash.Window.ToolTip = $installTitle
				$global:ProgressSyncHash.Window.ShowDialog() | Out-Null
				$global:ProgressSyncHash.Error = $Error
			}) | Out-Null
			
			
			Write-Log -Message "Spin up progress dialog in a separate thread with message: [$statusMessage]" -Source ${CmdletName}
			$progressData = $powershell.BeginInvoke()
			
			Start-Sleep -Seconds 3
			
			While ($global:ProgressSyncHash.StatusMessage -ne '_CloseRunspace') {
				Try {
					
					If (Test-Path -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -PathType 'Leaf') {
						$global:ProgressSyncHash.StatusMessage = Import-Clixml -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -ErrorAction 'Stop'
					}
					
					If ($global:ProgressSyncHash.StatusMessage -eq '_CloseRunspace') { Break }
					
					
					$global:ProgressSyncHash.Window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]'Normal', [Windows.Input.InputEventHandler]{ $global:ProgressSyncHash.ProgressText.Text = $global:ProgressSyncHash.StatusMessage }, $null, $null)
					
					
					Start-Sleep -Seconds 1
				}
				Catch {
					Write-Log -Message "Unable to update the progress message. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
					Break
				}
			}
			
			
			If ($global:ProgressSyncHash.Error) {
				Write-Log -Message "Failure while displaying progress dialog. `n$(Resolve-Error -ErrorRecord $global:ProgressSyncHash.Error)" -Severity 3 -Source ${CmdletName}
			}
			
			
			$global:ProgressSyncHash.Window.Close()
			$global:ProgressSyncHash.Window.Dispose()
			$powershell.Dispose()
			
			
			If (Test-Path -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -PathType 'Leaf') {
				Remove-Item -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -Force -ErrorAction 'SilentlyContinue' | Out-Null
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Close-InstallationProgress {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($global:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -eq 'Running') {
			
			Write-Log -Message 'Close the installation progress dialog.' -Source ${CmdletName}
			$global:ProgressSyncHash.Window.Dispatcher.InvokeShutdown()
			$global:ProgressRunspace.Close()
			$global:ProgressSyncHash.Clear()
		}
		
		If (Test-Path -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -PathType 'Leaf') {
			Remove-Item -Path "$dirAppDeployTemp\StatusMsgFrom_ShowInstallProgress.xml" -Force -ErrorAction 'SilentlyContinue' | Out-Null
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-PinnedApplication {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('PintoStartMenu','UnpinfromStartMenu','PintoTaskbar','UnpinfromTaskbar')]
		[string]$Action,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		
		Function Get-PinVerb {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[int32]$VerbId
			)
			
			[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			
			$GetPinVerbSource = @'
			using System;
			using System.Text;
			using System.Runtime.InteropServices;
			namespace Verb
			{
				public sealed class Load
				{
					[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
					public static extern int LoadString(IntPtr h, int id, StringBuilder sb, int maxBuffer);
					
					[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
					public static extern IntPtr LoadLibrary(string s);
					
					public static string PinVerb(int VerbId)
					{
						IntPtr hShell32 = LoadLibrary("shell32.dll");
						const int nChars  = 255;
						StringBuilder Buff = new StringBuilder("", nChars);
						
						LoadString(hShell32, VerbId, Buff, Buff.Capacity);
						return Buff.ToString();
					}
				}
			}
'@
			If (-not ([System.Management.Automation.PSTypeName]'Verb.Load').Type) {
				Add-Type -TypeDefinition $GetPinVerbSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
			}
			
			Write-Log -Message "Get localized pin verb for verb id [$VerbID]." -Source ${CmdletName}
			[string]$PinVerb = [Verb.Load]::PinVerb($VerbId)
			Write-Log -Message "Verb ID [$VerbID] has a localized pin verb of [$PinVerb]." -Source ${CmdletName}
			Write-Output $PinVerb
		}
		
		
		
		Function Invoke-Verb {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string]$FilePath,
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string]$Verb
			)
			
			Try {
				[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
				$verb = $verb.Replace('&','')
				$path = Split-Path -Path $FilePath -Parent -ErrorAction 'Stop'
				$folder = $shellApp.Namespace($path)
				$item = $folder.ParseName((Split-Path -Path $FilePath -Leaf -ErrorAction 'Stop'))
				$itemVerb = $item.Verbs() | Where-Object { $_.Name.Replace('&','') -eq $verb } -ErrorAction 'Stop'
				
				If ($null -eq $itemVerb) {
					Write-Log -Message "Performing action [$verb] is not programatically supported for this file [$FilePath]." -Severity 2 -Source ${CmdletName}
				}
				Else {
					Write-Log -Message "Perform action [$verb] on [$FilePath]." -Source ${CmdletName}
					$itemVerb.DoIt()
				}
			}
			Catch {
				Write-Log -Message "Failed to perform action [$verb] on [$FilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
		}
		
		
		[hashtable]$Verbs = @{
			'PintoStartMenu' = 5381
			'UnpinfromStartMenu' = 5382
			'PintoTaskbar' = 5386
			'UnpinfromTaskbar' = 5387
		}
	}
	Process {
		Try {
			Write-Log -Message "Execute action [$Action] for file [$FilePath]." -Source ${CmdletName}
			
			If (-not (Test-Path -Path $FilePath -PathType Leaf -ErrorAction 'Stop')) {
				Throw "Path [$filePath] does not exist."
			}
			
			If (-not ($Verbs.$Action)) {
				Throw "Action [$Action] not supported. Supported actions are [$($Verbs.Keys -join ', ')]."
			}
			
			[string]$PinVerbAction = Get-PinVerb -VerbId $Verbs.$Action
			If (-not ($PinVerbAction)) {
				Throw "Failed to get a localized pin verb for action [$Action]. Action is not supported on this operating system."
			}
			
			Invoke-Verb -FilePath $FilePath -Verb $PinVerbAction
		}
		Catch {
			Write-Log -Message "Failed to execute action [$Action]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-IniValue {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Section,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$GetIniValueSource = @'
		using System;
		using System.Text;
		using System.Runtime.InteropServices;
		namespace IniFile
		{
			public sealed class GetValue
			{
				[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern int GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, int nSize, string lpFileName);
				
				public static string GetIniValue(string section, string key, string filepath)
				{
					string sDefault    = "";
					const int  nChars  = 1024;
					StringBuilder Buff = new StringBuilder(nChars);
					
					GetPrivateProfileString(section, key, sDefault, Buff, Buff.Capacity, filepath);
					return Buff.ToString();
				}
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'IniFile.GetValue').Type) {
			Add-Type -TypeDefinition $GetIniValueSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			Write-Log -Message "Read INI Key:  [Section = $Section] [Key = $Key]" -Source ${CmdletName}
			
			If (-not (Test-Path -Path $FilePath -PathType Leaf)) { Throw "File [$filePath] could not be found." }
			
			$IniValue = [IniFile.GetValue]::GetIniValue($Section, $Key, $FilePath)
			Write-Log -Message "INI Key Value: [Section = $Section] [Key = $Key] [Value = $IniValue]" -Source ${CmdletName}
			
			Write-Output $IniValue
		}
		Catch {
			Write-Log -Message "Failed to read INI file key value. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to read INI file key value: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-IniValue {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Section,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		
		[Parameter(Mandatory=$true)]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$SetIniValueSource = @'
		using System;
		using System.Text;
		using System.Runtime.InteropServices;
		namespace IniFile
		{
			public sealed class SetValue
			{
				[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				[return: MarshalAs(UnmanagedType.Bool)]
				public static extern bool WritePrivateProfileString(string lpAppName, string lpKeyName, StringBuilder lpString, string lpFileName);
				
				public static void SetIniValue(string section, string key, StringBuilder value, string filepath)
				{
					WritePrivateProfileString(section, key, value, filepath);
				}
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'IniFile.SetValue').Type) {
			Add-Type -TypeDefinition $SetIniValueSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			Write-Log -Message "Write INI Key Value: [Section = $Section] [Key = $Key] [Value = $Value]" -Source ${CmdletName}
			
			If (-not (Test-Path -Path $FilePath -PathType Leaf)) { Throw "File [$filePath] could not be found." }
			
			[IniFile.SetValue]::SetIniValue($Section, $Key, ([System.Text.StringBuilder]$Value), $FilePath)
		}
		Catch {
			Write-Log -Message "Failed to write INI file key value. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to write INI file key value: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-PEFileArchitecture {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({$_ | Test-Path -PathType Leaf})]
		[System.IO.FileInfo[]]$FilePath,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true,
		[Parameter(Mandatory=$false)]
		[switch]$PassThru
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[string[]]$PEFileExtensions = '.exe', '.dll', '.ocx', '.drv', '.sys', '.scr', '.efi', '.cpl', '.fon'
		[int32]$MACHINE_OFFSET = 4
		[int32]$PE_POINTER_OFFSET = 60
	}
	Process {
		ForEach ($Path in $filePath) {
			Try {
				If ($PEFileExtensions -notcontains $Path.Extension) {
					Throw "Invalid file type. Please specify one of the following PE file types: $($PEFileExtensions -join ', ')"
				}
				
				[byte[]]$data = New-Object -TypeName System.Byte[] -ArgumentList 4096
				$stream = New-Object -TypeName System.IO.FileStream -ArgumentList ($Path.FullName, 'Open', 'Read')
				$stream.Read($data, 0, 4096) | Out-Null
				$stream.Flush()
				$stream.Close()
				
				[int32]$PE_HEADER_ADDR = [System.BitConverter]::ToInt32($data, $PE_POINTER_OFFSET)
				[uint16]$PE_IMAGE_FILE_HEADER = [System.BitConverter]::ToUInt16($data, $PE_HEADER_ADDR + $MACHINE_OFFSET)
				Switch ($PE_IMAGE_FILE_HEADER) {
					0 { $PEArchitecture = 'Native' } 
					0x014c { $PEArchitecture = '32BIT' } 
					0x0200 { $PEArchitecture = 'Itanium-x64' } 
					0x8664 { $PEArchitecture = '64BIT' } 
					Default { $PEArchitecture = 'Unknown' }
				}
				Write-Log -Message "File [$($Path.FullName)] has a detected file architecture of [$PEArchitecture]." -Source ${CmdletName}
				
				If ($PassThru) {
					
					Get-Item -Path $Path.FullName -Force | Add-Member -MemberType 'NoteProperty' -Name 'BinaryType' -Value $PEArchitecture -Force -PassThru | Write-Output
				}
				Else {
					Write-Output $PEArchitecture
				}
			}
			Catch {
				Write-Log -Message "Failed to get the PE file architecture. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to get the PE file architecture: $($_.Exception.Message)"
				}
				Continue
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Invoke-RegisterOrUnregisterDLL {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Register','Unregister')]
		[string]$DLLAction,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		
		[string]${InvokedCmdletName} = $MyInvocation.InvocationName
		
		If (${InvokedCmdletName} -ne ${CmdletName}) {
			Switch (${InvokedCmdletName}) {
				'Register-DLL' { [string]$DLLAction = 'Register' }
				'Unregister-DLL' { [string]$DLLAction = 'Unregister' }
			}
		}
		
		If (-not $DLLAction) { Throw 'Parameter validation failed. Please specify the [-DLLAction] parameter to determine whether to register or unregister the DLL.' }
		[string]$DLLAction = (Get-Culture).TextInfo | ForEach-Object { $_.ToTitleCase($DLLAction.ToLower()) }
		Switch ($DLLAction) {
			'Register' { [string]$DLLActionParameters = "/s `"$FilePath`"" }
			'Unregister' { [string]$DLLActionParameters = "/s /u `"$FilePath`"" }
		}
	}
	Process {
		Try {
			Write-Log -Message "$DLLAction DLL file [$filePath]." -Source ${CmdletName}
			If (-not (Test-Path -Path $FilePath -PathType Leaf)) { Throw "File [$filePath] could not be found." }
			
			[string]$DLLFileBitness = Get-PEFileArchitecture -FilePath $filePath -ContinueOnError $false -ErrorAction 'Stop'
			If (($DLLFileBitness -ne '64BIT') -and ($DLLFileBitness -ne '32BIT')) {
				Throw "File [$filePath] has a detected file architecture of [$DLLFileBitness]. Only 32-bit or 64-bit DLL files can be $($DLLAction.ToLower() + 'ed')."
			}
			
			If ($Is64Bit) {
				If ($DLLFileBitness -eq '64BIT') {
					If ($Is64BitProcess) {
						[psobject]$ExecuteResult = Execute-Process -Path "$envWinDir\system32\regsvr32.exe" -Parameters $DLLActionParameters -WindowStyle Hidden -PassThru
					}
					Else {
						[psobject]$ExecuteResult = Execute-Process -Path "$envWinDir\sysnative\regsvr32.exe" -Parameters $DLLActionParameters -WindowStyle Hidden -PassThru
					}
				}
				ElseIf ($DLLFileBitness -eq '32BIT') {
					[psobject]$ExecuteResult = Execute-Process -Path "$envWinDir\SysWOW64\regsvr32.exe" -Parameters $DLLActionParameters -WindowStyle Hidden -PassThru
				}
			}
			Else {
				If ($DLLFileBitness -eq '64BIT') {
					Throw "File [$filePath] cannot be $($DLLAction.ToLower()) because it is a 64-bit file on a 32-bit operating system."
				}
				ElseIf ($DLLFileBitness -eq '32BIT') {
					[psobject]$ExecuteResult = Execute-Process -Path "$envWinDir\system32\regsvr32.exe" -Parameters $DLLActionParameters -WindowStyle Hidden -PassThru
				}
			}
			
			If ($ExecuteResult.ExitCode -ne 0) {
				If ($ExecuteResult.ExitCode -eq 999) {
					Throw "Execute-Process function failed with exit code [$($ExecuteResult.ExitCode)]."
				}
				Else {
					Throw "regsvr32.exe failed with exit code [$($ExecuteResult.ExitCode)]."
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to $($DLLAction.ToLower()) DLL file. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to $($DLLAction.ToLower()) DLL file: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
Set-Alias -Name 'Register-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope Script -Force -ErrorAction 'SilentlyContinue'
Set-Alias -Name 'Unregister-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope Script -Force -ErrorAction 'SilentlyContinue'




Function Get-MsiTableProperty {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateScript({ $_ | Test-Path -PathType Leaf })]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Table = 'Property',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[scriptblock]$InvokeMethod = {
			Param (
				[__comobject]$Object,
				[string]$MethodName,
				[object[]]$ArgumentList
			)
			Write-Output $Object.GetType().InvokeMember($MethodName, [System.Reflection.BindingFlags]::InvokeMethod, $null, $Object, $ArgumentList, $null, $null, $null)
		}
		
		[scriptblock]$GetProperty = {
			Param (
				[__comobject]$Object,
				[string]$PropertyName,
				[object[]]$ArgumentList
			)
			Write-Output $Object.GetType().InvokeMember($PropertyName, [System.Reflection.BindingFlags]::GetProperty, $null, $Object, $ArgumentList, $null, $null, $null)
		}
	}
	Process {
		Try {
			Write-Log -Message "Get properties from MSI file [$Path] in table [$Table]" -Source ${CmdletName}
			
			
			[psobject]$TableProperties = New-Object -TypeName PSObject
			
			[__comobject]$Installer = New-Object -ComObject WindowsInstaller.Installer -ErrorAction 'Stop'
			
			[int32]$OpenMSIReadOnly = 0
			[__comobject]$Database = &$InvokeMethod -Object $Installer -MethodName 'OpenDatabase' -ArgumentList @($Path, $OpenMSIReadOnly)
			
			[__comobject]$View = &$InvokeMethod -Object $Database -MethodName 'OpenView' -ArgumentList @("SELECT * FROM $Table")
			&$InvokeMethod -Object $View -MethodName 'Execute' | Out-Null
			
			
			[__comobject]$Record = &$InvokeMethod -Object $View -MethodName 'Fetch'
			
			While ($Record) {
				
				$TableProperties | Add-Member -MemberType NoteProperty -Name (& $GetProperty -Object $Record -PropertyName 'StringData' -ArgumentList @(1)) -Value (& $GetProperty -Object $Record -PropertyName 'StringData' -ArgumentList @(2))
				
				[__comobject]$Record = & $InvokeMethod -Object $View -MethodName 'Fetch'
			}
			
			Write-Output $TableProperties
		}
		Catch {
			Write-Log -Message "Failed to get the MSI table [$Table]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to get the MSI table [$Table]: $($_.Exception.Message)"
			}
		}
		Finally {
			If ($View) {
				& $InvokeMethod -Object $View -MethodName 'Close' -ArgumentList @() | Out-Null
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-MSUpdates {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,HelpMessage='Enter the KB Number for the Microsoft Update')]
		[ValidateNotNullorEmpty()]
		[string]$KBNumber
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Check if Microsoft Update [$kbNumber] is installed." -Source ${CmdletName}
		
		
		[boolean]$kbFound = $false
		
		
		[__comobject]$Session = New-Object -ComObject Microsoft.Update.Session
		[__comobject]$Collection = New-Object -ComObject Microsoft.Update.UpdateColl
		[__comobject]$Installer = $Session.CreateUpdateInstaller()
		[__comobject]$Searcher = $Session.CreateUpdateSearcher()
		[int32]$updateCount = $Searcher.GetTotalHistoryCount()
		If ($updateCount -gt 0) {
			$Searcher.QueryHistory(0, $updateCount) | Where-Object { $_.Title -match $kbNumber } | ForEach-Object { $kbFound = $true }
		}
		
		
		If (-not $kbFound) {
			Get-Hotfix -Id $kbNumber -ErrorAction 'SilentlyContinue' | ForEach-Object { $kbFound = $true }
		}
		
		
		If (-not $kbFound) {
			Write-Log -Message "Microsoft Update [$kbNumber] is not installed" -Source ${CmdletName}
			Write-Output $false
		}
		Else {
			Write-Log -Message "Microsoft Update [$kbNumber] is installed" -Source ${CmdletName}
			Write-Output $true
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Install-MSUpdates {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Directory
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Recursively install all Microsoft Updates in directory [$Directory]." -Source ${CmdletName}
		
		
		$kbPattern = '(?i)kb\d{6,8}'
		
		
		[System.IO.FileInfo[]]$files = Get-ChildItem -Path $Directory -Recurse -Include ('*.exe','*.msu','*.msp')
		ForEach ($file in $files) {
			If ($file.Name -match 'redist') {
				[version]$redistVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($file).ProductVersion
				[string]$redistDescription = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($file).FileDescription
				
				Write-Log -Message "Install [$redistDescription $redistVersion]..." -Source ${CmdletName}
				
				If ($redistDescription -match 'Win32 Cabinet Self-Extractor') {
					Execute-Process -Path $file -Parameters '/q' -WindowStyle Hidden -ContinueOnError $true
				}
				Else {
					Execute-Process -Path $file -Parameters '/quiet /norestart' -WindowStyle Hidden -ContinueOnError $true
				}
			}
			Else {
				
				[string]$kbNumber = [regex]::Match($file, $kbPattern).ToString()
				If (-not $kbNumber) { Continue }
				
				
				If (-not (Test-MSUpdates -KBNumber $kbNumber)) {
					Write-Log -Message "KB Number [$KBNumber] was not detected and will be installed." -Source ${CmdletName}
					Switch ($file.Extension) {
						
						'.exe' { Execute-Process -Path $file -Parameters '/quiet /norestart' -WindowStyle Hidden -ContinueOnError $true }
						
						'.msu' { Execute-Process -Path 'wusa.exe' -Parameters "`"$file`" /quiet /norestart" -WindowStyle Hidden -ContinueOnError $true }
						
						'.msp' { Execute-MSI -Action 'Patch' -Path $file -ContinueOnError $true }
					}
				}
				Else {
					Write-Log -Message "KB Number [$kbNumber] is already installed. Continue..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Send-Keys {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0)]
		[ValidateNotNullorEmpty()]
		[string]$WindowTitle,
		[Parameter(Mandatory=$true,Position=1)]
		[ValidateNotNullorEmpty()]
		[string]$Keys,
		[Parameter(Mandatory=$false,Position=2)]
		[ValidateNotNullorEmpty()]
		[int32]$WaitSeconds
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		
		Add-Type -AssemblyName System.Windows.Forms -ErrorAction 'Stop'
		
		$SetForegroundWindowSource = @'
			using System;
			using System.Runtime.InteropServices;
			public class GUIWindow
			{
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				[return: MarshalAs(UnmanagedType.Bool)]
				public static extern bool SetForegroundWindow(IntPtr hWnd);
			}
'@
		If (-not ([System.Management.Automation.PSTypeName]'GUIWindow').Type) {
			Add-Type -TypeDefinition $SetForegroundWindowSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			
			[System.Diagnostics.Process[]]$Process = Get-Process -ErrorAction 'Stop' | Where-Object { $_.MainWindowTitle.Contains($WindowTitle) }
			If ($Process) {
				Write-Log -Message "Match window title found running under process [$($process.name)]..." -Source ${CmdletName}
				
				[IntPtr]$ProcessHandle = $Process[0].MainWindowHandle
				
				Write-Log -Message 'Bring window to foreground.' -Source ${CmdletName}
				
				[boolean]$ActivateWindow = [GUIWindow]::SetForegroundWindow($ProcessHandle)
				
				
				
				If ($ActivateWindow) {
					Write-Log -Message 'Send key(s) [$Keys] to window.' -Source ${CmdletName}
					[System.Windows.Forms.SendKeys]::SendWait($Keys)
				}
				Else {
					Write-Log -Message 'Failed to bring window to foreground.' -Source ${CmdletName}
					
				}
				
				If ($WaitSeconds) { Start-Sleep -Seconds $WaitSeconds }
			}
		}
		Catch {
			Write-Log -Message "Failed to send keys to window [$WindowTitle]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-Battery {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		
		Add-Type -Assembly System.Windows.Forms -ErrorAction 'SilentlyContinue'
	}
	Process {
		Write-Log -Message 'Check if system is using AC power or if it is running on battery...' -Source ${CmdletName}
		
		[System.Windows.Forms.PowerStatus]$PowerStatus = [System.Windows.Forms.SystemInformation]::PowerStatus
		
		
		
		
		
		[string]$PowerLineStatus = $PowerStatus.PowerLineStatus
		
		
		[string]$BatteryChargeStatus = $PowerStatus.BatteryChargeStatus
		
		
		
		
		[single]$BatteryLifePercent = $PowerStatus.BatteryLifePercent
		If (($BatteryChargeStatus -eq 'NoSystemBattery') -or ($BatteryChargeStatus -eq 'Unknown')) {
			[single]$BatteryLifePercent = 0.0
		}
		
		
		[int32]$BatteryLifeRemaining = $PowerStatus.BatteryLifeRemaining
		
		
		
		
		[int32]$BatteryFullLifetime = $PowerStatus.BatteryFullLifetime
		
		
		[boolean]$OnACPower = $false
		If ($PowerLineStatus -eq 'Online') {
			Write-Log -Message 'System is using AC power.' -Source ${CmdletName}
			$OnACPower = $true
		}
		ElseIf ($PowerLineStatus -eq 'Offline') {
			Write-Log -Message 'System is using battery power.' -Source ${CmdletName}
		}
		ElseIf ($PowerLineStatus -eq 'Unknown') {
			If (($BatteryChargeStatus -eq 'NoSystemBattery') -or ($BatteryChargeStatus -eq 'Unknown')) {
				Write-Log -Message "System power status is [$PowerLineStatus] and battery charge status is [$BatteryChargeStatus]. This is most likely due to a damaged battery so we will report system is using AC power." -Source ${CmdletName}
				$OnACPower = $true
			}
			Else {
				Write-Log -Message "System power status is [$PowerLineStatus] and battery charge status is [$BatteryChargeStatus]. Therefore, we will report system is using battery power." -Source ${CmdletName}
			}
		}
		
		Write-Output $OnACPower
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-NetworkConnection {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message 'Check if system is using a wired network connection...' -Source ${CmdletName}
		
		[psobject[]]$networkConnected = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { ($_.NetConnectionStatus -eq 2) -and ($_.NetConnectionID -match 'Local') -and ($_.NetConnectionID -notmatch 'Wireless') -and ($_.Name -notmatch 'Virtual') } -ErrorAction 'SilentlyContinue'
		[boolean]$onNetwork = $false
		If ($networkConnected) {
			Write-Log -Message 'Wired network connection found.' -Source ${CmdletName}
			[boolean]$onNetwork = $true
		}
		Else {
			Write-Log -Message 'Wired network connection not found.' -Source ${CmdletName}
		}
		
		Write-Output $onNetwork
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-PowerPoint {

	[CmdletBinding()]
	Param (
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$FullScreenWindowSource = @'
		using System;
		using System.Text;
		using System.Text.RegularExpressions;
		using System.Runtime.InteropServices;
		namespace ScreenDetection
		{
			[StructLayout(LayoutKind.Sequential)]
			public struct RECT
			{
				public int Left;
				public int Top;
				public int Right;
				public int Bottom;
			}
			
			public class FullScreen
			{
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				private static extern IntPtr GetForegroundWindow();
				
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				private static extern IntPtr GetDesktopWindow();
				
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				private static extern IntPtr GetShellWindow();
				
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				private static extern int GetWindowRect(IntPtr hWnd, out RECT rc);
				
				[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
				
				private static IntPtr desktopHandle;
				private static IntPtr shellHandle;
				
				public static bool IsFullScreenWindow(string fullScreenWindowTitle)
				{
					desktopHandle = GetDesktopWindow();
					shellHandle   = GetShellWindow();
					
					bool runningFullScreen = false;
					RECT appBounds;
					System.Drawing.Rectangle screenBounds;
					const int nChars = 256;
					StringBuilder Buff = new StringBuilder(nChars);
					string mainWindowTitle = "";
					IntPtr hWnd;
					hWnd = GetForegroundWindow();
					
					if (hWnd != null && !hWnd.Equals(IntPtr.Zero))
					{
						if (!(hWnd.Equals(desktopHandle) || hWnd.Equals(shellHandle)))
						{
							if (GetWindowText(hWnd, Buff, nChars) > 0)
							{
								mainWindowTitle = Buff.ToString();
								//Console.WriteLine(mainWindowTitle);
							}
							
							// If the main window title contains the text being searched for, then check to see if the window is in fullscreen mode.
							Match match  = Regex.Match(mainWindowTitle, fullScreenWindowTitle, RegexOptions.IgnoreCase);
							if ((!string.IsNullOrEmpty(fullScreenWindowTitle)) && match.Success)
							{
								GetWindowRect(hWnd, out appBounds);
								screenBounds = System.Windows.Forms.Screen.FromHandle(hWnd).Bounds;
								if ((appBounds.Bottom - appBounds.Top) == screenBounds.Height && (appBounds.Right - appBounds.Left) == screenBounds.Width)
								{
									runningFullScreen = true;
								}
							}
						}
					}
					return runningFullScreen;
				}
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'ScreenDetection.FullScreen').Type) {
			[string[]]$ReferencedAssemblies = 'System.Drawing', 'System.Windows.Forms'
			Add-Type -TypeDefinition $FullScreenWindowSource -ReferencedAssemblies $ReferencedAssemblies -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			Write-Log -Message 'Check if PowerPoint is in fullscreen slideshow mode...' -Source ${CmdletName}
			[boolean]$IsPowerPointFullScreen = $false
			If (Get-Process -Name 'POWERPNT' -ErrorAction 'SilentlyContinue') {
				Write-Log -Message 'PowerPoint application is running.' -Source ${CmdletName}
				
				
				[boolean]$IsPowerPointFullScreen = [ScreenDetection.FullScreen]::IsFullScreenWindow('^PowerPoint Slide Show')
				
				Write-Log -Message "PowerPoint is running in fullscreen mode: $IsPowerPointFullScreen" -Source ${CmdletName}
			}
			Else {
				Write-Log -Message 'PowerPoint application is not running.' -Source ${CmdletName}
			}
			
			Write-Output $IsPowerPointFullScreen
		}
		Catch {
			Write-Log -Message "Failed check to see if PowerPoint is running in fullscreen slideshow mode. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			Write-Output $false
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Invoke-SCCMTask {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('HardwareInventory','SoftwareInventory','HeartbeatDiscovery','SoftwareInventoryFileCollection','RequestMachinePolicy','EvaluateMachinePolicy','LocationServicesCleanup','SoftwareMeteringReport','SourceUpdate','PolicyAgentCleanup','RequestMachinePolicy2','CertificateMaintenance','PeerDistributionPointStatus','PeerDistributionPointProvisioning','ComplianceIntervalEnforcement','SoftwareUpdatesAgentAssignmentEvaluation','UploadStateMessage','StateMessageManager','SoftwareUpdatesScan','AMTProvisionCycle')]
		[string]$ScheduleID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[hashtable]$ScheduleIds = @{
			HardwareInventory = '{00000000-0000-0000-0000-000000000001}'; 
			SoftwareInventory = '{00000000-0000-0000-0000-000000000002}'; 
			HeartbeatDiscovery = '{00000000-0000-0000-0000-000000000003}'; 
			SoftwareInventoryFileCollection = '{00000000-0000-0000-0000-000000000010}'; 
			RequestMachinePolicy = '{00000000-0000-0000-0000-000000000021}'; 
			EvaluateMachinePolicy = '{00000000-0000-0000-0000-000000000022}'; 
			RefreshDefaultMp = '{00000000-0000-0000-0000-000000000023}'; 
			RefreshLocationServices = '{00000000-0000-0000-0000-000000000024}'; 
			LocationServicesCleanup = '{00000000-0000-0000-0000-000000000025}'; 
			SoftwareMeteringReport = '{00000000-0000-0000-0000-000000000031}'; 
			SourceUpdate = '{00000000-0000-0000-0000-000000000032}'; 
			PolicyAgentCleanup = '{00000000-0000-0000-0000-000000000040}'; 
			RequestMachinePolicy2 = '{00000000-0000-0000-0000-000000000042}'; 
			CertificateMaintenance = '{00000000-0000-0000-0000-000000000051}'; 
			PeerDistributionPointStatus = '{00000000-0000-0000-0000-000000000061}'; 
			PeerDistributionPointProvisioning = '{00000000-0000-0000-0000-000000000062}'; 
			ComplianceIntervalEnforcement = '{00000000-0000-0000-0000-000000000071}'; 
			SoftwareUpdatesAgentAssignmentEvaluation = '{00000000-0000-0000-0000-000000000108}'; 
			UploadStateMessage = '{00000000-0000-0000-0000-000000000111}'; 
			StateMessageManager = '{00000000-0000-0000-0000-000000000112}'; 
			SoftwareUpdatesScan = '{00000000-0000-0000-0000-000000000113}'; 
			AMTProvisionCycle = '{00000000-0000-0000-0000-000000000120}'; 
		}
	}
	Process {
		Write-Log -Message "Invoke SCCM Schedule Task ID [$ScheduleId]..." -Source ${CmdletName}
		
		
		Try {
			[System.Management.ManagementClass]$SmsClient = [WMIClass]'ROOT\CCM:SMS_Client'
			$SmsClient.TriggerSchedule($ScheduleIds.$ScheduleID) | Out-Null
		}
		Catch {
			Write-Log -Message "Failed to trigger SCCM Schedule Task ID [$($ScheduleIds.$ScheduleId)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to trigger SCCM Schedule Task ID [$($ScheduleIds.$ScheduleId)]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Install-SCCMSoftwareUpdates {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		
		Write-Log -Message 'Scan for pending SCCM software updates...' -Source ${CmdletName}
		Invoke-SCCMTask -ScheduleId 'SoftwareUpdatesScan'
		
		Write-Log -Message 'Sleep for 180 seconds...' -Source ${CmdletName}
		Start-Sleep -Seconds 180
		
		Write-Log -Message 'Install pending software updates...' -Source ${CmdletName}
		Try {
			[System.Management.ManagementClass]$SmsSoftwareUpdates = [WMIClass]'ROOT\CCM:SMS_Client'
			$SmsSoftwareUpdates.InstallUpdates([System.Management.ManagementObject[]](Get-WmiObject -Namespace 'ROOT\CCM\ClientSDK' -Query 'SELECT * FROM CCM_SoftwareUpdate' -ErrorAction 'Stop')) | Out-Null
		}
		Catch {
			Write-Log -Message "Failed to trigger installation of pending SCCM software updates. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to trigger installation of pending SCCM software updates: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Update-GroupPolicy {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[string[]]$GPUpdateCmds = '/C echo N | gpupdate.exe /Target:Computer /Force', '/C echo N | gpupdate.exe /Target:User /Force'
		[int32]$InstallCount = 0
		ForEach ($GPUpdateCmd in $GPUpdateCmds) {
			Try {
				If ($InstallCount -eq 0) {
					[string]$InstallMsg = 'Update Group Policies for the Machine'
					Write-Log -Message $InstallMsg -Source ${CmdletName}
				}
				Else {
					[string]$InstallMsg = 'Update Group Policies for the User'
					Write-Log -Message $InstallMsg -Source ${CmdletName}
				}
				[psobject]$ExecuteResult = Execute-Process -Path "$envWindir\system32\cmd.exe" -Parameters $GPUpdateCmd -WindowStyle Hidden -PassThru
				
				If ($ExecuteResult.ExitCode -ne 0) {
					If ($ExecuteResult.ExitCode -eq 999) {
						Throw "Execute-Process function failed with exit code [$($ExecuteResult.ExitCode)]."
					}
					Else {
						Throw "gpupdate.exe failed with exit code [$($ExecuteResult.ExitCode)]."
					}
				}
				$InstallCount++
			}
			Catch {
				Write-Log -Message "Failed to $($InstallMsg). `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to $($InstallMsg): $($_.Exception.Message)"
				}
				Continue
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Enable-TerminalServerInstallMode {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Change terminal server into user install mode...' -Source ${CmdletName}
			$terminalServerResult = change.exe User /Install
			
			If ($global:LastExitCode -ne 0) { Throw $terminalServerResult }
		}
		Catch {
			Write-Log -Message "Failed to change terminal server into user install mode. `n$(Resolve-Error) " -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to change terminal server into user install mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Disable-TerminalServerInstallMode {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Change terminal server into user execute mode...' -Source ${CmdletName}
			$terminalServerResult = change.exe User /Execute
			
			If ($global:LastExitCode -ne 0) { Throw $terminalServerResult }
		}
		Catch {
			Write-Log -Message "Failed to change terminal server into user execute mode. `n$(Resolve-Error) " -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to change terminal server into user execute mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-ActiveSetup {

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$StubExePath,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Arguments,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Description = $installName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Key = $installName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Version = ((Get-Date -Format 'yyMM,ddHH,mmss').ToString()), 
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Locale,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$DisableActiveSetup = $false,
		[Parameter(Mandatory=$false)]
		[switch]$PurgeActiveSetupKey,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			[string]$ActiveSetupKey = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\$Key"
			[string]$HKCUActiveSetupKey = "HKCU:Software\Microsoft\Active Setup\Installed Components\$Key"
			
			
			If ($PurgeActiveSetupKey) {
				Write-Log -Message "Remove Active Setup entry [$ActiveSetupKey]." -Source ${CmdletName}
				Remove-RegistryKey -Key $ActiveSetupKey
				
				Write-Log -Message "Remove Active Setup entry [$HKCUActiveSetupKey] for all log on user registry hives on the system." -Source ${CmdletName}
				[scriptblock]$RemoveHKCUActiveSetupKey = { Remove-RegistryKey -Key $HKCUActiveSetupKey -SID $UserProfile.SID }
				Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $RemoveHKCUActiveSetupKey -UserProfiles (Get-UserProfiles -ExcludeDefaultUser)
				Return
			}
			
			
			[string[]]$StubExePathFileExtensions = '.exe', '.vbs', '.cmd', '.ps1', '.js'
			[string]$StubExeExt = [System.IO.Path]::GetExtension($StubExePath)
			If ($StubExePathFileExtensions -notcontains $StubExeExt) {
				Throw "Unsupported Active Setup StubPath file extension [$StubExeExt]."
			}
			
			
			[string]$StubExePath = [Environment]::ExpandEnvironmentVariables($StubExePath)
			[string]$ActiveSetupFileName = [System.IO.Path]::GetFileName($StubExePath)
			[string]$StubExeFile = Join-Path -Path $dirFiles -ChildPath $ActiveSetupFileName
			If (Test-Path -Path $StubExeFile -PathType Leaf) {
				
				Copy-File -Path $StubExeFile -Destination $StubExePath -ContinueOnError $false
			}
			
			
			If (-not (Test-Path -Path $StubExePath -PathType Leaf)) { Throw "Active Setup StubPath file [$ActiveSetupFileName] is missing." }
			
			
			Switch ($StubExeExt) {
				'.exe' {
					[string]$CUStubExePath = $StubExePath
					[string]$CUArguments = $Arguments
					[string]$StubPath = "$CUStubExePath"
				}
				{'.vbs','.js' -contains $StubExeExt} {
					[string]$CUStubExePath = "$envWinDir\system32\cscript.exe"
					[string]$CUArguments = "//nologo `"$StubExePath`""
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
				'.cmd' {
					[string]$CUStubExePath = "$envWinDir\system32\CMD.exe"
					[string]$CUArguments = "/C `"$StubExePath`""
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
				'.ps1' {
					[string]$CUStubExePath = "$PSHOME\powershell.exe"
					[string]$CUArguments = "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -Command `"$StubExePath`""
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
			}
			If ($Arguments) {
				[string]$StubPath = "$StubPath $Arguments"
				If ($StubExeExt -ne '.exe') { [string]$CUArguments = "$CUArguments $Arguments" }
			}
			
			
			Set-RegistryKey -Key $ActiveSetupKey -Name '(Default)' -Value $Description -ContinueOnError $false
			Set-RegistryKey -Key $ActiveSetupKey -Name 'StubPath' -Value $StubPath -Type 'ExpandString' -ContinueOnError $false
			Set-RegistryKey -Key $ActiveSetupKey -Name 'Version' -Value $Version -ContinueOnError $false
			If ($Locale) { Set-RegistryKey -Key $ActiveSetupKey -Name 'Locale' -Value $Locale -ContinueOnError $false }
			If ($DisableActiveSetup) {
				Set-RegistryKey -Key $ActiveSetupKey -Name 'IsInstalled' -Value 0 -Type 'DWord' -ContinueOnError $false
			}
			Else {
				Set-RegistryKey -Key $ActiveSetupKey -Name 'IsInstalled' -Value 1 -Type 'DWord' -ContinueOnError $false
			}
			
			
			If ($SessionZero) {
				Write-Log -Message 'Session 0 detected: Will not execute Active Setup StubPath file. Users will have to log off and log back into their account to execute Active Setup entry.' -Source ${CmdletName}
			}
			Else {
				Write-Log -Message 'Execute Active Setup StubPath file for the current user.' -Source ${CmdletName}
				If ($CUArguments) {
					$ExecuteResults = Execute-Process -FilePath $CUStubExePath -Arguments $CUArguments -PassThru
				}
				Else {
					$ExecuteResults = Execute-Process -FilePath $CUStubExePath -PassThru
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to set Active Setup registry entry. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set Active Setup registry entry: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Test-ServiceExists {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$ServiceObject = Get-WmiObject -ComputerName $ComputerName -Class Win32_Service -Filter "Name='$Name'" -ErrorAction 'Stop'
			If ($ServiceObject) {
				Write-Log -Message "Service [$Name] exists" -Source ${CmdletName}
				If ($PassThru) { Write-Output $ServiceObject } Else { Write-Output $true }
			}
			Else {
				Write-Log -Message "Service [$Name] does not exist" -Source ${CmdletName}
				If ($PassThru) { Write-Output $ServiceObject } Else { Write-Output $false }
			}
		}
		Catch {
			Write-Log -Message "Failed check to see if service [$Name] exists." -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed check to see if service [$Name] exists: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Stop-ServiceAndDependencies {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipServiceExistsTest,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipDependentServices,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If ((-not $SkipServiceExistsTest) -and (-not (Test-ServiceExists -ComputerName $ComputerName -Name $Name -ContinueOnError $false))) {
				Write-Log -Message "Service [$Name] does not exist" -Source ${CmdletName} -Severity 2
				Throw "Service [$Name] does not exist."
			}
			
			
			Write-Log -Message "Get the service object for service [$Name]" -Source ${CmdletName}
			[System.ServiceProcess.ServiceController]$Service = Get-Service -ComputerName $ComputerName -Name $Name -ErrorAction 'Stop'
			
			[string[]]$PendingStatus = 'ContinuePending', 'PausePending', 'StartPending', 'StopPending'
			If ($PendingStatus -contains $Service.Status) {
				Switch ($Service.Status) {
					{'ContinuePending'} { $DesiredStatus = 'Running' }
					{'PausePending'} { $DesiredStatus = 'Paused' }
					{'StartPending'} { $DesiredStatus = 'Running' }
					{'StopPending'} { $DesiredStatus = 'Stopped' }
				}
				[timespan]$WaitForStatusTime = New-TimeSpan -Seconds 60
				Write-Log -Message "Waiting for up to [$($WaitForStatusTime.TotalSeconds)] seconds to allow service pending status [$($Service.Status)] to reach desired status [$DesiredStatus]." -Source ${CmdletName}
				$Service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]$DesiredStatus, $WaitForStatusTime)
				$Service.Refresh()
			}
			
			Write-Log -Message "Service [$($Service.ServiceName)] with display name [$($Service.DisplayName)] has a status of [$($Service.Status)]" -Source ${CmdletName}
			If ($Service.Status -ne 'Stopped') {
				
				If (-not $SkipDependentServices) {
					Write-Log -Message "Discover all dependent service(s) for service [$Name] which are not 'Stopped'." -Source ${CmdletName}
					[System.ServiceProcess.ServiceController[]]$DependentServices = Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -DependentServices -ErrorAction 'Stop' | Where-Object { $_.Status -ne 'Stopped' }
					If ($DependentServices) {
						ForEach ($DependentService in $DependentServices) {
							Write-Log -Message "Stop dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]." -Source ${CmdletName}
							Try {
								Stop-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $DependentService.ServiceName -ErrorAction 'Stop') -Force -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
							}
							Catch {
								Write-Log -Message "Failed to start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]. Continue..." -Severity 2 -Source ${CmdletName}
								Continue
							}
						}
					}
					Else {
						Write-Log -Message "Dependent service(s) were not discovered for service [$Name]" -Source ${CmdletName}
					}
				}
				
				Write-Log -Message "Stop parent service [$($Service.ServiceName)] with display name [$($Service.DisplayName)]" -Source ${CmdletName}
				[System.ServiceProcess.ServiceController]$Service = Stop-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -ErrorAction 'Stop') -Force -PassThru -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
			}
		}
		Catch {
			Write-Log -Message "Failed to stop the service [$Name]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to stop the service [$Name]: $($_.Exception.Message)"
			}
		}
		Finally {
			
			If ($PassThru -and $Service) { Write-Output $Service }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Start-ServiceAndDependencies {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipServiceExistsTest,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipDependentServices,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If ((-not $SkipServiceExistsTest) -and (-not (Test-ServiceExists -ComputerName $ComputerName -Name $Name -ContinueOnError $false))) {
				Write-Log -Message "Service [$Name] does not exist" -Source ${CmdletName} -Severity 2
				Throw "Service [$Name] does not exist."
			}
			
			
			Write-Log -Message "Get the service object for service [$Name]" -Source ${CmdletName}
			[System.ServiceProcess.ServiceController]$Service = Get-Service -ComputerName $ComputerName -Name $Name -ErrorAction 'Stop'
			
			[string[]]$PendingStatus = 'ContinuePending', 'PausePending', 'StartPending', 'StopPending'
			If ($PendingStatus -contains $Service.Status) {
				Switch ($Service.Status) {
					'ContinuePending' { $DesiredStatus = 'Running' }
					'PausePending' { $DesiredStatus = 'Paused' }
					'StartPending' { $DesiredStatus = 'Running' }
					'StopPending' { $DesiredStatus = 'Stopped' }
				}
				[timespan]$WaitForStatusTime = New-TimeSpan -Seconds 60
				Write-Log -Message "Waiting for up to [$($WaitForStatusTime.TotalSeconds)] seconds to allow service pending status [$($Service.Status)] to reach desired status [$DesiredStatus]." -Source ${CmdletName}
				$Service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]$DesiredStatus, $WaitForStatusTime)
				$Service.Refresh()
			}
			
			Write-Log -Message "Service [$($Service.ServiceName)] with display name [$($Service.DisplayName)] has a status of [$($Service.Status)]" -Source ${CmdletName}
			If ($Service.Status -ne 'Running') {
				
				Write-Log -Message "Start parent service [$($Service.ServiceName)] with display name [$($Service.DisplayName)]" -Source ${CmdletName}
				[System.ServiceProcess.ServiceController]$Service = Start-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -ErrorAction 'Stop') -PassThru -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
				
				
				If (-not $SkipDependentServices) {
					Write-Log -Message "Discover all dependent service(s) for service [$Name] which are not 'Running'." -Source ${CmdletName}
					[System.ServiceProcess.ServiceController[]]$DependentServices = Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -DependentServices -ErrorAction 'Stop' | Where-Object { $_.Status -ne 'Running' }
					If ($DependentServices) {
						ForEach ($DependentService in $DependentServices) {
							Write-Log -Message "Start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]." -Source ${CmdletName}
							Try {
								Start-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $DependentService.ServiceName -ErrorAction 'Stop') -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
							}
							Catch {
								Write-Log -Message "Failed to start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]. Continue..." -Severity 2 -Source ${CmdletName}
								Continue
							}
						}
					}
					Else {
						Write-Log -Message "Dependent service(s) were not discovered for service [$Name]" -Source ${CmdletName}
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to start the service [$Name]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to start the service [$Name]: $($_.Exception.Message)"
			}
		}
		Finally {
			
			If ($PassThru -and $Service) { Write-Output $Service }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-ServiceStartMode
{

	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get the service [$Name] startup mode." -Source ${CmdletName}
			[string]$ServiceStartMode = (Get-WmiObject -ComputerName $ComputerName -Class 'Win32_Service' -Filter "Name='$Name'" -Property 'StartMode' -ErrorAction 'Stop').StartMode
			
			If ($ServiceStartMode -eq 'Auto') { $ServiceStartMode = 'Automatic'}
			
			
			If (($ServiceStartMode -eq 'Automatic') -and ([System.Environment]::OSVersion.Version.Major -gt 5)) {
				Try {
					[string]$ServiceRegistryPath = "HKLM:SYSTEM\CurrentControlSet\Services\$Name"
					[int32]$DelayedAutoStart = Get-ItemProperty -Path $ServiceRegistryPath -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DelayedAutoStart' -ErrorAction 'Stop'
					If ($DelayedAutoStart -eq 1) { $ServiceStartMode = 'Automatic (Delayed Start)' }
				}
				Catch { }
			}
			
			Write-Log -Message "Service [$Name] startup mode is set to [$ServiceStartMode]" -Source ${CmdletName}
			Write-Output $ServiceStartMode
		}
		Catch {
			Write-Log -Message "Failed to get the service [$Name] startup mode. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to get the service [$Name] startup mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Set-ServiceStartMode
{

	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$true)]
		[ValidateSet('Automatic','Automatic (Delayed Start)','Manual','Disabled','Boot','System')]
		[string]$StartMode,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			
			If (($StartMode -eq 'Automatic (Delayed Start)') -and ([System.Environment]::OSVersion.Version.Major -lt 6)) { $StartMode = 'Automatic' }
			
			Write-Log -Message "Set service [$Name] startup mode to [$StartMode]" -Source ${CmdletName}
			If ($StartMode -eq 'Automatic (Delayed Start)') {
				$ChangeStartMode = & sc.exe config $Name start= delayed-auto
				If ($global:LastExitCode -ne 0) {
					Throw "sc.exe failed with exit code [$($global:LastExitCode)] and message [$ChangeStartMode]."
				}
			}
			Else {
				$ChangeStartMode = (Get-WmiObject -ComputerName $ComputerName -Class Win32_Service -Filter "Name='$Name'" -ErrorAction 'Stop').ChangeStartMode($StartMode)
				If($ChangeStartMode.ReturnValue -ne 0) {
					Throw "The 'ChangeStartMode' method of the 'Win32_Service' WMI class failed with a return value of [$($ChangeStartMode.ReturnValue)]."
				}
			}
			Write-Log -Message "Successfully set service [$Name] startup mode to [$StartMode]" -Source ${CmdletName}
		}
		Catch {
			Write-Log -Message "Failed to set service [$Name] startup mode to [$StartMode]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to set service [$Name] startup mode to [$StartMode]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Get-LoggedOnUser {

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipIsLocalAdminCheck = $false
	)
	
	Begin {
		
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		$QueryUserSessionSource = @'
		using System;
		using System.Collections.Generic;
		using System.Text;
		using System.Runtime.InteropServices;
		using System.ComponentModel;
		using FILETIME=System.Runtime.InteropServices.ComTypes.FILETIME;
		namespace QueryUser
		{
			public class Session
			{
				[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern IntPtr WTSOpenServer(string pServerName);
				[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern void WTSCloseServer(IntPtr hServer);
				[DllImport("wtsapi32.dll", CharSet = CharSet.Ansi, SetLastError = false)]
				public static extern bool WTSQuerySessionInformation(IntPtr hServer, int sessionId, WTS_INFO_CLASS wtsInfoClass, out IntPtr pBuffer, out int pBytesReturned);
				[DllImport("wtsapi32.dll", CharSet = CharSet.Ansi, SetLastError = false)]
				public static extern int WTSEnumerateSessions(IntPtr hServer, int Reserved, int Version, out IntPtr pSessionInfo, out int pCount);
				[DllImport("wtsapi32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern void WTSFreeMemory(IntPtr pMemory);
				[DllImport("winsta.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern int WinStationQueryInformation(IntPtr hServer, int sessionId, int information, ref WINSTATIONINFORMATIONW pBuffer, int bufferLength, ref int returnedLength);
				[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern int GetCurrentProcessId();
				[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
				public static extern bool ProcessIdToSessionId(int processId, ref int pSessionId);

				[StructLayout(LayoutKind.Sequential)]
				private struct WTS_SESSION_INFO
				{
					public Int32 SessionId; [MarshalAs(UnmanagedType.LPStr)] public string SessionName; public WTS_CONNECTSTATE_CLASS State;
				}

				[StructLayout(LayoutKind.Sequential)]
				public struct WINSTATIONINFORMATIONW
				{
					[MarshalAs(UnmanagedType.ByValArray, SizeConst = 70)] private byte[] Reserved1;
					public int SessionId;
					[MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)] private byte[] Reserved2;
					public FILETIME ConnectTime;
					public FILETIME DisconnectTime;
					public FILETIME LastInputTime;
					public FILETIME LoginTime;
					[MarshalAs(UnmanagedType.ByValArray, SizeConst = 1096)] private byte[] Reserved3;
					public FILETIME CurrentTime;
				}

				public enum WINSTATIONINFOCLASS { WinStationInformation = 8 }
				public enum WTS_CONNECTSTATE_CLASS { Active, Connected, ConnectQuery, Shadow, Disconnected, Idle, Listen, Reset, Down, Init }
				public enum WTS_INFO_CLASS { SessionId=4, UserName, SessionName, DomainName, ConnectState, ClientBuildNumber, ClientName, ClientDirectory, ClientProtocolType=16 }

				private static IntPtr OpenServer(string Name) { IntPtr server = WTSOpenServer(Name); return server; }
				private static void CloseServer(IntPtr ServerHandle) { WTSCloseServer(ServerHandle); }
				
				private static IList<T> PtrToStructureList<T>(IntPtr ppList, int count) where T : struct
				{
					List<T> result = new List<T>(); long pointer = ppList.ToInt64(); int sizeOf = Marshal.SizeOf(typeof(T));
					for (int index = 0; index < count; index++)
					{
						T item = (T) Marshal.PtrToStructure(new IntPtr(pointer), typeof(T)); result.Add(item); pointer += sizeOf;
					}
					return result;
				}

				public static DateTime? FileTimeToDateTime(FILETIME ft)
				{
					if (ft.dwHighDateTime == 0 && ft.dwLowDateTime == 0) { return null; }
					long hFT = (((long) ft.dwHighDateTime) << 32) + ft.dwLowDateTime;
					return DateTime.FromFileTime(hFT);
				}

				public static WINSTATIONINFORMATIONW GetWinStationInformation(IntPtr server, int sessionId)
				{
					int retLen = 0;
					WINSTATIONINFORMATIONW wsInfo = new WINSTATIONINFORMATIONW();
					WinStationQueryInformation(server, sessionId, (int) WINSTATIONINFOCLASS.WinStationInformation, ref wsInfo, Marshal.SizeOf(typeof(WINSTATIONINFORMATIONW)), ref retLen);
					return wsInfo;
				}
				
				public static TerminalSessionData[] ListSessions(string ServerName)
				{
					IntPtr server = IntPtr.Zero;
					if (ServerName != "localhost" && ServerName != String.Empty) {server = OpenServer(ServerName);}
					List<TerminalSessionData> results = new List<TerminalSessionData>();
					try
					{
						IntPtr ppSessionInfo = IntPtr.Zero; int count; bool _isUserSession = false; IList<WTS_SESSION_INFO> sessionsInfo;
						
						if (WTSEnumerateSessions(server, 0, 1, out ppSessionInfo, out count) == 0) { throw new Win32Exception(); }
						try { sessionsInfo = PtrToStructureList<WTS_SESSION_INFO>(ppSessionInfo, count); }
						finally { WTSFreeMemory(ppSessionInfo); }
						
						foreach (WTS_SESSION_INFO sessionInfo in sessionsInfo)
						{
							if (sessionInfo.SessionName != "Services" && sessionInfo.SessionName != "RDP-Tcp") { _isUserSession = true; }
							results.Add(new TerminalSessionData(sessionInfo.SessionId, sessionInfo.State, sessionInfo.SessionName, _isUserSession));
							_isUserSession = false;
						}
					}
					finally { CloseServer(server); }
					TerminalSessionData[] returnData = results.ToArray();
					return returnData;
				}
				
				public static TerminalSessionInfo GetSessionInfo(string ServerName, int SessionId)
				{
					IntPtr server = IntPtr.Zero;
					IntPtr buffer = IntPtr.Zero;
					int bytesReturned;
					TerminalSessionInfo data = new TerminalSessionInfo();
					bool _IsCurrentSessionId = false;
					bool _IsConsoleSession = false;
					bool _IsUserSession = false;
					int currentSessionID = 0;
					string _NTAccount = String.Empty;

					if (ServerName != "localhost" && ServerName != String.Empty) { server = OpenServer(ServerName); }
					if (ProcessIdToSessionId(GetCurrentProcessId(), ref currentSessionID) == false) { currentSessionID = -1; }
					try
					{
						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientBuildNumber, out buffer, out bytesReturned) == false) { return data; }
						int lData = Marshal.ReadInt32(buffer);
						data.ClientBuildNumber = lData;

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientDirectory, out buffer, out bytesReturned) == false) { return data; }
						string strData = Marshal.PtrToStringAnsi(buffer);
						data.ClientDirectory = strData;

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientName, out buffer, out bytesReturned) == false) { return data; }
						strData = Marshal.PtrToStringAnsi(buffer);
						data.ClientName = strData;

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ClientProtocolType, out buffer, out bytesReturned) == false) { return data; }
						Int16 intData = Marshal.ReadInt16(buffer);
						if (intData == 2) {strData = "RDP";} else {strData = "";}
						data.ClientProtocolType = strData;

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.ConnectState, out buffer, out bytesReturned) == false) { return data; }
						lData = Marshal.ReadInt32(buffer);
						data.ConnectState = (WTS_CONNECTSTATE_CLASS)Enum.ToObject(typeof(WTS_CONNECTSTATE_CLASS), lData);

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.SessionId, out buffer, out bytesReturned) == false) { return data; }
						lData = Marshal.ReadInt32(buffer);
						data.SessionId = lData;

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.DomainName, out buffer, out bytesReturned) == false) { return data; }
						strData = Marshal.PtrToStringAnsi(buffer);
						data.DomainName = strData;
						if (strData != String.Empty) {_NTAccount = strData;}

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.UserName, out buffer, out bytesReturned) == false) { return data; }
						strData = Marshal.PtrToStringAnsi(buffer);
						data.UserName = strData;
						if (strData != String.Empty) {data.NTAccount = _NTAccount + "\\" + strData;}

						if (WTSQuerySessionInformation(server, SessionId, WTS_INFO_CLASS.SessionName, out buffer, out bytesReturned) == false) { return data; }
						strData = Marshal.PtrToStringAnsi(buffer);
						data.SessionName = strData;
						if (strData != "Services" && strData != "RDP-Tcp") { _IsUserSession = true; }
						data.IsUserSession = _IsUserSession;
						if (strData == "Console") { _IsConsoleSession = true; }
						data.IsConsoleSession = _IsConsoleSession;

						WINSTATIONINFORMATIONW wsInfo = GetWinStationInformation(server, SessionId);
						DateTime? _loginTime = FileTimeToDateTime(wsInfo.LoginTime);
						DateTime? _lastInputTime = FileTimeToDateTime(wsInfo.LastInputTime);
						DateTime? _disconnectTime = FileTimeToDateTime(wsInfo.DisconnectTime);
						DateTime? _currentTime = FileTimeToDateTime(wsInfo.CurrentTime);
						TimeSpan? _idleTime = (_currentTime != null && _lastInputTime != null) ? _currentTime.Value - _lastInputTime.Value : TimeSpan.Zero;
						data.LogonTime = _loginTime;
						data.IdleTime = _idleTime;
						data.DisconnectTime = _disconnectTime;

						if (currentSessionID == SessionId) { _IsCurrentSessionId = true; }
						data.IsCurrentSession = _IsCurrentSessionId;
					}
					finally
					{
						WTSFreeMemory(buffer); buffer = IntPtr.Zero; CloseServer(server);
					}
					return data;
				}
			}

			public class TerminalSessionData
			{
				public int SessionId; public Session.WTS_CONNECTSTATE_CLASS ConnectionState; public string SessionName; public bool IsUserSession;
				public TerminalSessionData(int sessionId, Session.WTS_CONNECTSTATE_CLASS connState, string sessionName, bool isUserSession)
				{
					SessionId = sessionId; ConnectionState = connState; SessionName = sessionName; IsUserSession = isUserSession;
				}
			}

			public class TerminalSessionInfo
			{
				public string NTAccount; public string UserName; public string DomainName; public int SessionId; public string SessionName;
				public Session.WTS_CONNECTSTATE_CLASS ConnectState; public bool IsCurrentSession; public bool IsConsoleSession;
				public bool IsUserSession; public bool IsLocalAdmin; public DateTime? LogonTime; public TimeSpan? IdleTime; public DateTime? DisconnectTime;
				public string ClientName; public string ClientProtocolType; public string ClientDirectory; public int ClientBuildNumber;
			}
		}
'@
		If (-not ([System.Management.Automation.PSTypeName]'QueryUser.Session').Type) {
			Add-Type -TypeDefinition $QueryUserSessionSource -Language CSharp -IgnoreWarnings -ErrorAction 'Stop'
		}
	}
	Process {
		Try {
			If (-not $SkipIsLocalAdminCheck) {
				Try {
					
					$LocalAdminGroupSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-32-544'
					$LocalAdminGroupNTAccount = $LocalAdminGroupSID.Translate([System.Security.Principal.NTAccount])
					$LocalAdminGroupName = ($LocalAdminGroupNTAccount.Value).Split('\')[1]
					$LocalAdminGroup =[ADSI]"WinNT://$($env:COMPUTERNAME)/$LocalAdminGroupName" 
					$LocalAdminGroupMembers = @($LocalAdminGroup.PSBase.Invoke('Members'))
					[string[]]$LocalAdminGroupUserName = ''
					$LocalAdminGroupMembers | ForEach { [string[]]$LocalAdminGroupUserName += $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) }
					[string[]]$LocalAdminGroupUserName = $LocalAdminGroupUserName | Where-Object { -not [string]::IsNullOrEmpty($_) }
					[string[]]$LocalAdminGroupNTAccounts = @()
					[string[]]$LocalAdminGroupNTAccounts = $LocalAdminGroupUserName | ForEach-Object { (New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $_).Translate([System.Security.Principal.SecurityIdentifier]).Translate([System.Security.Principal.NTAccount]).Value }
					[boolean]$IsLocalAdminCheckSuccess = $true
				}
				Catch {
					[boolean]$IsLocalAdminCheckSuccess = $false
					[string[]]$LocalAdminGroupNTAccounts = @()
				}
			}
			
			Write-Log -Message 'Get session information for all logged on users.' -Source ${CmdletName} -DisableOnRelaunchToolkitAsUser
			[psobject[]]$TerminalSessions = [QueryUser.Session]::ListSessions('localhost')
			ForEach ($TerminalSession in $TerminalSessions) {
				If (($TerminalSession.IsUserSession)) {
					[psobject]$SessionInfo = [QueryUser.Session]::GetSessionInfo('localhost', $TerminalSession.SessionId)
					If ($SessionInfo.UserName) {
						If ((-not $SkipIsLocalAdminCheck) -and ($IsLocalAdminCheckSuccess)) {
							If ($LocalAdminGroupNTAccounts -contains $SessionInfo.NTAccount) {
								$SessionInfo.IsLocalAdmin = $true
							}
							Else {
								$SessionInfo.IsLocalAdmin = $false
							}
						}
						[psobject[]]$TerminalSessionInfo += $SessionInfo
					}
				}
			}
			Write-Output $TerminalSessionInfo
		}
		Catch {
			Write-Log -Message "Failed to get session information for all logged on users. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName} -DisableOnRelaunchToolkitAsUser
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}




Function Invoke-PSCommandAsUser {
	Param (
		[string]$UserName = $RelaunchToolkitAsNTAccount,
		[string]$PSPath = "$PSHOME\powershell.exe",
		[scriptblock]$Command,
		[switch]$NoWait = $false,
		[switch]$NoExit = $false,
		[switch]$ExitAfterCommandExecution = $false,
		[switch]$PassThru = $false,
		[boolean]$ContinueOnError = $true
	)

	If (-not $UserName) { Throw "No valid username [$UserName] specified." }

	
	If (-not $Variables_Application) {
		[scriptblock]$Variables_Application = {
			[string]$appVendor = $appVendor
			[string]$appName = $appName
			[string]$appVersion = $appVersion
			[string]$appArch = $appArch
			[string]$appLang = $appLang
			[string]$appRevision = $appRevision
		}
	}
	
	If (-not $Variables_AllScriptParams) {
		[scriptblock]$Variables_AllScriptParams = {
			[string]$DeploymentType = $DeploymentType
			[string]$DeployMode = $DeployMode
		}
	}
	
	If ($NoExit) {
		[string]$Variables_PowerShellExeParams = "-ExecutionPolicy Bypass -NoProfile -NoLogo -NoExit -WindowStyle Hidden"
	}
	Else {
		[string]$Variables_PowerShellExeParams = "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden"
	}
	
	[scriptblock]$Variables_SkipAdminCheck = { [boolean]$SkipAdminCheck = $true }
	
	[scriptblock]$Variables_ExitWithLastExitCode = { Exit $LastExitCode }
	
	[string]$Variables_DotSourceToolkitForUser = ". `"$scriptPath`" -RelaunchToolkitAsUser $appDeployMainScriptParameters"
	
	
	If ($PassThru) {
		If (Test-Path -Path "$dirAppDeployTemp\ResultsFrom_InvokePSCommandAsUser.xml" -PathType 'Leaf') {
			Remove-Item -Path "$dirAppDeployTemp\ResultsFrom_InvokePSCommandAsUser.xml" -Force -ErrorAction 'SilentlyContinue' | Out-Null
		}
		[scriptblock]$Command = [scriptblock]::Create($Command.ToString() + " | Export-Clixml -Path '$dirAppDeployTemp\ResultsFrom_InvokePSCommandAsUser.xml' -Force" )
	}
	
	
	[scriptblock]$PSPrameters = { "$Variables_PowerShellExeParams -Command `".{ $Variables_InstallPhase; $Variables_Application; $Variables_AllScriptParams; $Variables_Script; $Variables_SkipAdminCheck; $Variables_DotSourceToolkitForUser; $Command; $Variables_ExitWithLastExitCode }`"" }
	
	[System.Diagnostics.Process]$PSProcess = Invoke-ProcessWithLogonToken -PassThru -Username $UserName -CreateProcess $PSPath -ProcessArgs (& $PSPrameters) -WarningAction 'SilentlyContinue'
	If (-not $NoWait) {
		$PSProcess.WaitForExit()
		[int32]$PSExitCode = $PSProcess.ExitCode
	}
	If ($PSProcess) { $PSProcess.Close() }
	
	If ($PassThru) {
		If (Test-Path -Path "$dirAppDeployTemp\ResultsFrom_InvokePSCommandAsUser.xml" -PathType 'Leaf') {
			$CommandOutput = Import-Clixml -Path "$dirAppDeployTemp\ResultsFrom_InvokePSCommandAsUser.xml" -ErrorAction 'Stop'
		}
		Write-Output $CommandOutput
	}

	
	
	
	
	
	
	
	
	
}














If ($invokingScript) {
	If ((Split-Path -Path $invokingScript -Leaf) -eq 'AppDeployToolkitHelp.ps1') { Return }
}


If ($ReferringApplication) {
	$installName = $ReferringApplication
	$installTitle = $ReferringApplication -replace '_',' '
	$installPhase = 'Asynchronous'
}


Try {
	Add-Type -AssemblyName System.Windows.Forms -ErrorAction 'Stop'
	Add-Type -AssemblyName PresentationFramework -ErrorAction 'Stop'
	Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction 'Stop'
	Add-Type -AssemblyName System.Drawing -ErrorAction 'Stop'
	Add-Type -AssemblyName PresentationFramework -ErrorAction 'Stop'
	Add-Type -AssemblyName PresentationCore -ErrorAction 'Stop'
	Add-Type -AssemblyName WindowsBase -ErrorAction 'Stop'
}
Catch {
	Write-Log -Message "Failed to load assembly. `n$(Resolve-Error)" -Severity 3 -Source $appDeployToolkitName
	If ($deployModeNonInteractive) {
		Write-Log -Message "Continue despite assembly load error since deployment mode is [$deployMode]" -Source $appDeployToolkitName
	}
	Else {
		Exit-Script -ExitCode 1
	}
}


If ($showInstallationPrompt) {
	$deployModeSilent = $true
	Write-Log -Message "[$appDeployMainScriptFriendlyName] called with switch [-ShowInstallationPrompt]" -Source $appDeployToolkitName
	$appDeployMainScriptParameters.Remove('ShowInstallationPrompt')
	$appDeployMainScriptParameters.Remove('ReferringApplication')
	Show-InstallationPrompt @appDeployMainScriptParameters
	Exit 0
}


If ($showInstallationRestartPrompt) {
	$deployModeSilent = $true
	Write-Log -Message "[$appDeployMainScriptFriendlyName] called with switch [-ShowInstallationRestartPrompt]" -Source $appDeployToolkitName
	$appDeployMainScriptParameters.Remove('ShowInstallationRestartPrompt')
	$appDeployMainScriptParameters.Remove('ReferringApplication')
	Show-InstallationRestartPrompt @appDeployMainScriptParameters
	Exit 0
}


If ($cleanupBlockedApps) {
	$deployModeSilent = $true
	Write-Log -Message "[$appDeployMainScriptFriendlyName] called with switch [-CleanupBlockedApps]" -Source $appDeployToolkitName
	Unblock-AppExecution
	Exit 0
}


If ($showBlockedAppDialog) {
	$DisableLogging = $true
	Try {
		$deployModeSilent = $true
		Write-Log -Message "[$appDeployMainScriptFriendlyName] called with switch [-ShowBlockedAppDialog]" -Source $appDeployToolkitName
		Show-InstallationPrompt -Title $installTitle -Message $configBlockExecutionMessage -Icon Warning -ButtonRightText 'OK'
		Exit 0
	}
	Catch {
		$InstallPromptErrMsg = "There was an error in displaying the Installation Prompt. `n$(Resolve-Error)"
		Write-Log -Message $InstallPromptErrMsg -Severity 3 -Source $appDeployToolkitName
		Show-DialogBox -Text $InstallPromptErrMsg -Icon 'Stop' | Out-Null
		Exit 1
	}
}


If ($RelaunchToolkitAsUser) {
	Write-Log -Message "Dot-sourcing [$scriptFileName] in a separate PowerShell.exe process running under user account [$ProcessNTAccount] to allow execution of PowerShell commands in a user session." -Source $appDeployToolkitName
}
If (-not $RelaunchToolkitAsUser) {
	[scriptblock]$Variables_InstallPhase = { [string]$installPhase = 'Initialization' }; .$Variables_InstallPhase
	$scriptSeparator = '*' * 79
	Write-Log -Message ($scriptSeparator,$scriptSeparator) -Source $appDeployToolkitName
	Write-Log -Message "[$installName] setup started." -Source $appDeployToolkitName
	
	
	If ($invokingScript) {
		Write-Log -Message "Script [$scriptPath] dot-source invoked by [$invokingScript]" -Source $appDeployToolkitName
	}
	Else {
		Write-Log -Message "Script [$scriptPath] invoked directly" -Source $appDeployToolkitName
	}
}

If (Test-Path -Path "$scriptRoot\$appDeployToolkitDotSourceExtensions" -PathType Leaf) {
	If ($RelaunchToolkitAsUser) {
		. "$scriptRoot\$appDeployToolkitDotSourceExtensions" -RelaunchToolkitAsUser
	}
	Else {
		. "$scriptRoot\$appDeployToolkitDotSourceExtensions"
	}
}


If (Test-Path -Path "$scriptRoot\Invoke-ProcessWithLogonToken.ps1" -PathType Leaf) {
	. "$scriptRoot\Invoke-ProcessWithLogonToken.ps1"
}


If ($deployAppScriptParameters) { [string]$deployAppScriptParameters = ($deployAppScriptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' ' }
If ($appDeployMainScriptParameters) { [string]$appDeployMainScriptParameters = ($appDeployMainScriptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' ' }
If ($appDeployExtScriptParameters) { [string]$appDeployExtScriptParameters = ($appDeployExtScriptParameters.GetEnumerator() | ForEach-Object { If ($_.Value.GetType().Name -eq 'SwitchParameter') { "-$($_.Key):`$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Boolean') { "-$($_.Key) `$" + "$($_.Value)".ToLower() } ElseIf ($_.Value.GetType().Name -eq 'Int32') { "-$($_.Key) $($_.Value)" } Else { "-$($_.Key) `"$($_.Value)`"" } }) -join ' ' }


If ($configConfigVersion -lt $appDeployMainScriptMinimumConfigVersion) {
	[string]$XMLConfigVersionErr = "The XML configuration file version [$configConfigVersion] is lower than the supported version required by the Toolkit [$appDeployMainScriptMinimumConfigVersion]. Please upgrade the configuration file."
	Write-Log -Message $XMLConfigVersionErr -Severity 3 -Source $appDeployToolkitName
	Throw $XMLConfigVersionErr
}


If (-not $RelaunchToolkitAsUser) {
	If ($appScriptVersion) { Write-Log -Message "[$installName] script version is [$appScriptVersion]" -Source $appDeployToolkitName }
	If ($deployAppScriptFriendlyName) { Write-Log -Message "[$deployAppScriptFriendlyName] script version is [$deployAppScriptVersion]" -Source $appDeployToolkitName }
	If ($deployAppScriptParameters) { Write-Log -Message "The following non-default parameters were passed to [$deployAppScriptFriendlyName]: [$deployAppScriptParameters]" -Source $appDeployToolkitName }
	If ($appDeployMainScriptFriendlyName) { Write-Log -Message "[$appDeployMainScriptFriendlyName] script version is [$appDeployMainScriptVersion]" -Source $appDeployToolkitName }
	If ($appDeployMainScriptParameters) { Write-Log -Message "The following non-default parameters were passed to [$appDeployMainScriptFriendlyName]: [$appDeployMainScriptParameters]" -Source $appDeployToolkitName }
	If ($appDeployExtScriptFriendlyName) { Write-Log -Message "[$appDeployExtScriptFriendlyName] version is [$appDeployExtScriptVersion]" -Source $appDeployToolkitName }
	If ($appDeployExtScriptParameters) { Write-Log -Message "The following non-default parameters were passed to [$appDeployExtScriptFriendlyName]: [$appDeployExtScriptParameters]" -Source $appDeployToolkitName }
	Write-Log -Message "Computer Name is [$envComputerNameFQDN]" -Source $appDeployToolkitName
	Write-Log -Message "Current User is [$ProcessNTAccount]" -Source $appDeployToolkitName
	If ($envOSServicePack) {
		Write-Log -Message "OS Version is [$envOSName $envOSServicePack $envOSArchitecture $envOSVersion]" -Source $appDeployToolkitName
	}
	Else {
		Write-Log -Message "OS Version is [$envOSName $envOSArchitecture $envOSVersion]" -Source $appDeployToolkitName
	}
	Write-Log -Message "OS Type is [$envOSProductTypeName]" -Source $appDeployToolkitName
	Write-Log -Message "Current Culture is [$($culture.Name)] and UI language is [$currentLanguage]" -Source $appDeployToolkitName
	Write-Log -Message "Hardware Platform is [$($OriginalDisableLogging = $DisableLogging; $DisableLogging = $true; Get-HardwarePlatform; $DisableLogging = $OriginalDisableLogging)]" -Source $appDeployToolkitName
	Write-Log -Message "PowerShell Host is [$($envHost.Name)] with version [$($envHost.Version)]" -Source $appDeployToolkitName
	Write-Log -Message "PowerShell Version is [$envPSVersion $psArchitecture]" -Source $appDeployToolkitName
	Write-Log -Message "PowerShell CLR (.NET) version is [$envCLRVersion]" -Source $appDeployToolkitName
	Write-Log -Message "System has a DPI scale of [$dpiScale]." -Source $appDeployToolkitName
	Write-Log -Message $scriptSeparator -Source $appDeployToolkitName
}


If (-not $RelaunchToolkitAsUser) {
	[psobject[]]$LoggedOnUserSessions = Get-LoggedOnUser
}
Else {
	[psobject[]]$LoggedOnUserSessions = Get-LoggedOnUser -SkipIsLocalAdminCheck
}
Write-Log -Message "Logged on user session details: `n$($LoggedOnUserSessions | Format-List | Out-String)" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
[string[]]$usersLoggedOn = $LoggedOnUserSessions | ForEach-Object { $_.NTAccount }

If ($usersLoggedOn) {
	Write-Log -Message "The following users are logged on to the system: $($usersLoggedOn -join ', ')" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	
	
	[psobject]$CurrentLoggedOnUserSession = $LoggedOnUserSessions | Where-Object { $_.IsCurrentSession }
	If ($CurrentLoggedOnUserSession) {
		Write-Log -Message "Current process is running under a user account [$($CurrentLoggedOnUserSession.NTAccount)]" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	}
	Else {
		Write-Log -Message "Current process is running under a system account [$ProcessNTAccount]" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	}

	
	[psobject]$CurrentConsoleUserSession = $LoggedOnUserSessions | Where-Object { $_.IsConsoleSession }
	If ($CurrentConsoleUserSession) {
		Write-Log -Message "The following user is the console user [$($CurrentConsoleUserSession.NTAccount)] (user with control of physical monitor, keyboard, and mouse)." -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	}
	Else {
		Write-Log -Message 'There is no console user logged in (user with control of physical monitor, keyboard, and mouse).' -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	}

	
	If ($CurrentConsoleUserSession) {
		[string]$RelaunchToolkitAsNTAccount = $CurrentConsoleUserSession.NTAccount
	}
	ElseIf ($configToolkitAllowSystemInteractionForNonConsoleUser) {
		[string]$FirstLoggedInNonConsoleUser = $LoggedOnUserSessions | Select-Object -First 1
		If ($FirstLoggedInNonConsoleUser) { [string]$RelaunchToolkitAsNTAccount = $FirstLoggedInNonConsoleUser.NTAccount }
	}
	Else {
		[string]$RelaunchToolkitAsNTAccount = ''
	}
}
Else {
	Write-Log -Message 'No users are logged on to the system' -Source $appDeployToolkitName
}


Try { [boolean]$IsTerminalServerSession = [System.Windows.Forms.SystemInformation]::TerminalServerSession } Catch { }
Write-Log -Message "The process is running in a terminal server session: [$IsTerminalServerSession]." -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser


Try {
	[__comobject]$SMSTSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction 'Stop'
	Write-Log -Message 'Successfully loaded COM Object [Microsoft.SMS.TSEnvironment]. Therefore, script is currently running from a SCCM Task Sequence.' -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	[boolean]$runningTaskSequence = $true
}
Catch {
	Write-Log -Message 'Unable to load COM Object [Microsoft.SMS.TSEnvironment]. Therefore, script is not currently running from a SCCM Task Sequence.' -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
	[boolean]$runningTaskSequence = $false
}



[boolean]$IsTaskSchedulerHealthy = $true
If ($IsLocalSystemAccount) {
	[scriptblock]$TestServiceHealth = {
		Param (
			[string]$ServiceName
		)
		Try {
			If (Test-ServiceExists -Name $ServiceName -ContinueOnError $false) {
				If ((Get-ServiceStartMode -Name $ServiceName -ContinueOnError $false) -ne 'Automatic') {
					Set-ServiceStartMode -Name $ServiceName -StartMode 'Automatic' -ContinueOnError $false
				}
				Start-ServiceAndDependencies -Name $ServiceName -SkipServiceExistsTest -ContinueOnError $false
			}
			Else {
				[boolean]$IsTaskSchedulerHealthy = $false
			}
		}
		Catch {
			[boolean]$IsTaskSchedulerHealthy = $false
		}
	}
	
	& $TestServiceHealth -ServiceName 'EventSystem'
	
	& $TestServiceHealth -ServiceName 'RpcSs'
	
	& $TestServiceHealth -ServiceName 'EventLog'
	
	& $TestServiceHealth -ServiceName 'Schedule'

	Write-Log -Message "The task scheduler service is in a healthy state: $IsTaskSchedulerHealthy" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
}


If (-not $RelaunchToolkitAsUser) {
	If ($SessionZero) {
		
		If ($deployMode -eq 'NonInteractive') {
			Write-Log -Message "Session 0 detected. Deployment mode was manually set to [$deployMode]." -Source $appDeployToolkitName
		}
		Else {
			
			If (-not $IsProcessUserInteractive) {
				Write-Log -Message 'Session 0 detected, process not running in user interactive mode.' -Source $appDeployToolkitName
				If ($configToolkitAllowSystemInteraction) {
					Write-Log -Message "'Allow System Interaction' option is enabled in the toolkit XML configuration file." -Source $appDeployToolkitName
					If ($CurrentConsoleUserSession) {
						$deployMode = 'Interactive'
						Write-Log -Message "Toolkit will use a console user account [$RelaunchToolkitAsNTAccount] to provide interaction in the SYSTEM context..." -Source $appDeployToolkitName
					}
					ElseIf ($configToolkitAllowSystemInteractionForNonConsoleUser) {
						Write-Log -Message "'Allow System Interaction' for non-console user is enabled in the toolkit XML configuration file." -Source $appDeployToolkitName
						If ($FirstLoggedInNonConsoleUser) {
							$deployMode = 'Interactive'
							Write-Log -Message "Toolkit will use a non-console user account [$RelaunchToolkitAsNTAccount] to provide interaction in the SYSTEM context..." -Source $appDeployToolkitName
						}
						Else {
							Write-Log -Message 'No users are currently logged in to allow relaunching the toolkit to provide interaction in the SYSTEM context.' -Source $appDeployToolkitName
						}
					}
					Else {
						$deployMode = 'NonInteractive'
						Write-Log -Message 'No users are logged on to be able to run in interactive mode.' -Source $appDeployToolkitName
					}
				}
				Else {
					Write-Log -Message "'Allow System Interaction' option is disabled in the toolkit XML configuration file." -Source $appDeployToolkitName
					$deployMode = 'NonInteractive'
					Write-Log -Message "Deployment mode set to [$deployMode]." -Source $appDeployToolkitName
				}
			}
			Else {
				If (-not $RelaunchToolkitAsNTAccount) {
					$deployMode = 'NonInteractive'
					Write-Log -Message "Session 0 detected, process running in user interactive mode, no users logged in: deployment mode set to [$deployMode]." -Source $appDeployToolkitName
				}
				Else {
					Write-Log -Message 'Session 0 detected, process running in user interactive mode, user(s) logged in.' -Source $appDeployToolkitName
				}
			}
		}
	}
	Else {
		Write-Log -Message 'Session 0 not detected.' -Source $appDeployToolkitName
	}
}


If ($deployMode) {
	Write-Log -Message "Installation is running in [$deployMode] mode." -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser
}
Switch ($deployMode) {
	'Silent' { $deployModeSilent = $true }
	'NonInteractive' { $deployModeNonInteractive = $true; $deployModeSilent = $true }
	Default { $deployModeNonInteractive = $false; $deployModeSilent = $false }
}


Switch ($deploymentType) {
	'Install'   { $deploymentTypeName = $configDeploymentTypeInstall }
	'Uninstall' { $deploymentTypeName = $configDeploymentTypeUnInstall }
	Default { $deploymentTypeName = $configDeploymentTypeInstall }
}
If ($deploymentTypeName) { Write-Log -Message "Deployment type is [$deploymentTypeName]" -Source $appDeployToolkitName -DisableOnRelaunchToolkitAsUser }


If ($configToolkitRequireAdmin) {
	
	If ((-not $IsAdmin) -and (-not $ShowBlockedAppDialog) -and (-not $SkipAdminCheck)) {
		[string]$AdminPermissionErr = "[$appDeployToolkitName] has an XML config file option [Toolkit_RequireAdmin] set to [True] so as to require Administrator rights for the toolkit to function. Please re-run the deployment script as an Administrator or change the option in the XML config file to not require Administrator rights."
		Write-Log -Message $AdminPermissionErr -Severity 3 -Source $appDeployToolkitName
		Show-DialogBox -Text $AdminPermissionErr -Icon 'Stop' | Out-Null
		Throw $AdminPermissionErr
	}
}


If ($terminalServerMode) { Enable-TerminalServerInstallMode }




