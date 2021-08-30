
[CmdletBinding(DefaultParameterSetName="NamedPipe")]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $HostName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $HostProfileId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $HostVersion,

    [ValidateNotNullOrEmpty()]
    [string]
    $BundledModulesPath,

    [ValidateNotNullOrEmpty()]
    $LogPath,

    [ValidateSet("Diagnostic", "Verbose", "Normal", "Warning", "Error")]
    $LogLevel,

	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]
	$SessionDetailsPath,

    [switch]
    $EnableConsoleRepl,

    [switch]
    $UseLegacyReadLine,

    [switch]
    $DebugServiceOnly,

    [string[]]
    $AdditionalModules,

    [string[]]
    $FeatureFlags,

    [switch]
    $WaitForDebugger,

    [switch]
    $ConfirmInstall,

    [Parameter(ParameterSetName="Stdio", Mandatory=$true)]
    [switch]
    $Stdio,

    [Parameter(ParameterSetName="NamedPipe")]
    [string]
    $LanguageServicePipeName = $null,

    [Parameter(ParameterSetName="NamedPipe")]
    [string]
    $DebugServicePipeName = $null,

    [Parameter(ParameterSetName="NamedPipeSimplex")]
    [switch]
    $SplitInOutPipes,

    [Parameter(ParameterSetName="NamedPipeSimplex")]
    [string]
    $LanguageServiceInPipeName,

    [Parameter(ParameterSetName="NamedPipeSimplex")]
    [string]
    $LanguageServiceOutPipeName,

    [Parameter(ParameterSetName="NamedPipeSimplex")]
    [string]
    $DebugServiceInPipeName = $null,

    [Parameter(ParameterSetName="NamedPipeSimplex")]
    [string]
    $DebugServiceOutPipeName = $null
)

$DEFAULT_USER_MODE = "600"

if ($LogLevel -eq "Diagnostic") {
    if (!$Stdio.IsPresent) {
        $VerbosePreference = 'Continue'
    }
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
    $logFileName = [System.IO.Path]::GetFileName($LogPath)
    Start-Transcript (Join-Path (Split-Path $LogPath -Parent) "$scriptName-$logFileName") -Force | Out-Null
}

function LogSection([string]$msg) {
    Write-Verbose "`n
}

function Log([string[]]$msg) {
    $msg | Write-Verbose
}

function ExitWithError($errorString) {
    Write-Host -ForegroundColor Red "`n`n$errorString"

    
    
    Start-Sleep -Seconds 300

    exit 1;
}

function WriteSessionFile($sessionInfo) {
    $sessionInfoJson = Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject $sessionInfo -Compress
    Log "Writing session file with contents:"
    Log $sessionInfoJson
    $sessionInfoJson | Microsoft.PowerShell.Management\Set-Content -Force -Path "$SessionDetailsPath" -ErrorAction Stop
}


$version = $PSVersionTable.PSVersion
if (($version.Major -le 2) -or ($version.Major -eq 6 -and $version.Minor -eq 0)) {
    
    "{`"status`": `"failed`", `"reason`": `"unsupported`", `"powerShellVersion`": `"$($PSVersionTable.PSVersion.ToString())`"}" |
        Microsoft.PowerShell.Management\Set-Content -Force -Path "$SessionDetailsPath" -ErrorAction Stop

    ExitWithError "Unsupported PowerShell version $($PSVersionTable.PSVersion), language features are disabled."
}


if ($host.Runspace.LanguageMode -eq 'ConstrainedLanguage') {
    WriteSessionFile @{
        "status" = "failed"
        "reason" = "languageMode"
        "detail" = $host.Runspace.LanguageMode.ToString()
    }

    ExitWithError "PowerShell is configured with an unsupported LanguageMode (ConstrainedLanguage), language features are disabled."
}


if ($PSVersionTable.PSVersion.Major -le 5) {
    $net452Version = 379893
    $dotnetVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\").Release
    if ($dotnetVersion -lt $net452Version) {
        Write-SessionFile @{
            status = failed
            reason = "netversion"
            detail = "$netVersion"
        }

        ExitWithError "Your .NET version is too low. Upgrade to net452 or higher to run the PowerShell extension."
    }
}



if ((Microsoft.PowerShell.Core\Get-Module PSReadline).Count -gt 0) {
    LogSection "Removing PSReadLine module"
    Microsoft.PowerShell.Core\Remove-Module PSReadline -ErrorAction SilentlyContinue
}




$resultDetails = $null;

function Test-ModuleAvailable($ModuleName, $ModuleVersion) {
    Log "Testing module availability $ModuleName $ModuleVersion"

    $modules = Microsoft.PowerShell.Core\Get-Module -ListAvailable $moduleName
    if ($null -ne $modules) {
        if ($null -ne $ModuleVersion) {
            foreach ($module in $modules) {
                if ($module.Version.Equals($moduleVersion)) {
                    Log "$ModuleName $ModuleVersion found"
                    return $true;
                }
            }
        }
        else {
            Log "$ModuleName $ModuleVersion found"
            return $true;
        }
    }

    Log "$ModuleName $ModuleVersion NOT found"
    return $false;
}

function New-NamedPipeName {
    
    for ($i = 0; $i -lt 10; $i++) {
        $PipeName = "PSES_$([System.IO.Path]::GetRandomFileName())"

        if ((Test-NamedPipeName -PipeName $PipeName)) {
            return $PipeName
        }
    }

    ExitWithError "Could not find valid a pipe name."
}

function Get-NamedPipePath {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PipeName
    )

    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        return "\\.\pipe\$PipeName";
    }
    else {
        
        
        return (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "CoreFxPipe_$PipeName")
    }
}




function Test-NamedPipeName {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PipeName
    )

    $path = Get-NamedPipePath -PipeName $PipeName
    return !(Test-Path $path)
}

LogSection "Console Encoding"
Log $OutputEncoding

function Get-ValidatedNamedPipeName {
    param(
        [string]
        $PipeName
    )

    
    if (!$PipeName) {
        $PipeName = New-NamedPipeName
    }
    elseif (!(Test-NamedPipeName -PipeName $PipeName)) {
        ExitWithError "Pipe name supplied is already in use: $PipeName"
    }

    return $PipeName
}

function Set-PipeFileResult {
    param (
        [Hashtable]
        $ResultTable,

        [string]
        $PipeNameKey,

        [string]
        $PipeNameValue
    )

    $ResultTable[$PipeNameKey] = Get-NamedPipePath -PipeName $PipeNameValue
}


if ($BundledModulesPath) {
    $env:PSModulePath = $env:PSModulePath.TrimEnd([System.IO.Path]::PathSeparator) + [System.IO.Path]::PathSeparator + $BundledModulesPath
    LogSection "Updated PSModulePath to:"
    Log ($env:PSModulePath -split [System.IO.Path]::PathSeparator)
}

LogSection "Check required modules available"

if ((Test-ModuleAvailable "PowerShellGet") -eq $false) {
    Log "Failed to find PowerShellGet module"
    
}

try {
    LogSection "Start up PowerShellEditorServices"
    Log "Importing PowerShellEditorServices"

    Microsoft.PowerShell.Core\Import-Module PowerShellEditorServices -ErrorAction Stop

    if ($EnableConsoleRepl) {
        Write-Host "PowerShell Integrated Console`n"
    }

    $resultDetails = @{
        "status" = "not started";
        "languageServiceTransport" = $PSCmdlet.ParameterSetName;
        "debugServiceTransport" = $PSCmdlet.ParameterSetName;
    }

    
    Log "Invoking Start-EditorServicesHost"
    
    
    switch ($PSCmdlet.ParameterSetName) {
        "Stdio" {
            $editorServicesHost = Start-EditorServicesHost `
                                        -HostName $HostName `
                                        -HostProfileId $HostProfileId `
                                        -HostVersion $HostVersion `
                                        -LogPath $LogPath `
                                        -LogLevel $LogLevel `
                                        -AdditionalModules $AdditionalModules `
                                        -Stdio `
                                        -BundledModulesPath $BundledModulesPath `
                                        -EnableConsoleRepl:$EnableConsoleRepl.IsPresent `
                                        -DebugServiceOnly:$DebugServiceOnly.IsPresent `
                                        -WaitForDebugger:$WaitForDebugger.IsPresent `
                                        -FeatureFlags $FeatureFlags
            break
        }

        "NamedPipeSimplex" {
            $LanguageServiceInPipeName = Get-ValidatedNamedPipeName $LanguageServiceInPipeName
            $LanguageServiceOutPipeName = Get-ValidatedNamedPipeName $LanguageServiceOutPipeName
            $DebugServiceInPipeName = Get-ValidatedNamedPipeName $DebugServiceInPipeName
            $DebugServiceOutPipeName = Get-ValidatedNamedPipeName $DebugServiceOutPipeName

            $editorServicesHost = Start-EditorServicesHost `
                                        -HostName $HostName `
                                        -HostProfileId $HostProfileId `
                                        -HostVersion $HostVersion `
                                        -LogPath $LogPath `
                                        -LogLevel $LogLevel `
                                        -AdditionalModules $AdditionalModules `
                                        -LanguageServiceInNamedPipe $LanguageServiceInPipeName `
                                        -LanguageServiceOutNamedPipe $LanguageServiceOutPipeName `
                                        -DebugServiceInNamedPipe $DebugServiceInPipeName `
                                        -DebugServiceOutNamedPipe $DebugServiceOutPipeName `
                                        -BundledModulesPath $BundledModulesPath `
                                        -UseLegacyReadLine:$UseLegacyReadLine.IsPresent `
                                        -EnableConsoleRepl:$EnableConsoleRepl.IsPresent `
                                        -DebugServiceOnly:$DebugServiceOnly.IsPresent `
                                        -WaitForDebugger:$WaitForDebugger.IsPresent `
                                        -FeatureFlags $FeatureFlags

            Set-PipeFileResult $resultDetails "languageServiceReadPipeName" $LanguageServiceInPipeName
            Set-PipeFileResult $resultDetails "languageServiceWritePipeName" $LanguageServiceOutPipeName
            Set-PipeFileResult $resultDetails "debugServiceReadPipeName" $DebugServiceInPipeName
            Set-PipeFileResult $resultDetails "debugServiceWritePipeName" $DebugServiceOutPipeName
            break
        }

        Default {
            $LanguageServicePipeName = Get-ValidatedNamedPipeName $LanguageServicePipeName
            $DebugServicePipeName = Get-ValidatedNamedPipeName $DebugServicePipeName

            $editorServicesHost = Start-EditorServicesHost `
                                        -HostName $HostName `
                                        -HostProfileId $HostProfileId `
                                        -HostVersion $HostVersion `
                                        -LogPath $LogPath `
                                        -LogLevel $LogLevel `
                                        -AdditionalModules $AdditionalModules `
                                        -LanguageServiceNamedPipe $LanguageServicePipeName `
                                        -DebugServiceNamedPipe $DebugServicePipeName `
                                        -BundledModulesPath $BundledModulesPath `
                                        -UseLegacyReadLine:$UseLegacyReadLine.IsPresent `
                                        -EnableConsoleRepl:$EnableConsoleRepl.IsPresent `
                                        -DebugServiceOnly:$DebugServiceOnly.IsPresent `
                                        -WaitForDebugger:$WaitForDebugger.IsPresent `
                                        -FeatureFlags $FeatureFlags

            Set-PipeFileResult $resultDetails "languageServicePipeName" $LanguageServicePipeName
            Set-PipeFileResult $resultDetails "debugServicePipeName" $DebugServicePipeName
            break
        }
    }

    
    Log "Start-EditorServicesHost returned $editorServicesHost"

    $resultDetails["status"] = "started"

    
    WriteSessionFile $resultDetails

    Log "Wrote out session file"
}
catch [System.Exception] {
    $e = $_.Exception;
    $errorString = ""

    Log "ERRORS caught starting up EditorServicesHost"

    while ($null -ne $e) {
        $errorString = $errorString + ($e.Message + "`r`n" + $e.StackTrace + "`r`n")
        $e = $e.InnerException;
        Log $errorString
    }

    ExitWithError ("An error occurred while starting PowerShell Editor Services:`r`n`r`n" + $errorString)
}

try {
    
    LogSection "Waiting for EditorServicesHost to complete execution"
    $editorServicesHost.WaitForCompletion()
    Log "EditorServicesHost has completed execution"
}
catch [System.Exception] {
    $e = $_.Exception;
    $errorString = ""

    Log "ERRORS caught while waiting for EditorServicesHost to complete execution"

    while ($null -ne $e) {
        $errorString = $errorString + ($e.Message + "`r`n" + $e.StackTrace + "`r`n")
        $e = $e.InnerException;
        Log $errorString
    }
}
