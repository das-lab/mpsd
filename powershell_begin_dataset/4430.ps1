
function Get-CredsFromCredentialProvider {
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SourceLocation,

        [Parameter()]
        [bool]
        $isRetry = $false
    )


    Write-Verbose "PowerShellGet Calling 'CallCredProvider' on $SourceLocation"
    
    $regex = [regex] '^(\S*pkgs.dev.azure.com\S*/v2)$|^(\S*pkgs.visualstudio.com\S*/v2)$'

    if (!($SourceLocation -match $regex)) {
        return $null;
    }

    
    
    
    
    
    $credProviderPath = $null
    $defaultEnvPath = "NUGET_PLUGIN_PATHS"
    $nugetPluginPath = Get-Childitem env:$defaultEnvPath -ErrorAction SilentlyContinue
    $callDotnet = $true;

    if ($nugetPluginPath -and $nugetPluginPath.value) {
        
        
        $credProviderPath = $nugetPluginPath.value
        $extension = $credProviderPath.Substring($credProviderPath.get_Length() - 4)
        if ($extension -eq ".exe") {
            $callDotnet = $false
        }
    }
    else {
        
        $path = "$($env:UserProfile)/.nuget/plugins/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll";

        if ($script:IsLinux -or $script:IsMacOS) {
            $path = "$($HOME)/.nuget/plugins/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll";
        }
        if (Test-Path $path -PathType Leaf) {
            $credProviderPath = $path
        }
    }

    
    
    
    
    if (!$credProviderPath -and $script:IsWindows) {
        if (${Env:ProgramFiles(x86)}) {
            $programFiles = ${Env:ProgramFiles(x86)}
        }
        elseif ($Env:Programfiles) {
            $programFiles = $Env:Programfiles
        }
        else {
            return $null
        }

        $vswhereExePath = "$($programFiles)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
        if (!(Test-Path $vswhereExePath -PathType Leaf)) {
            return $null
        }

        $RedirectedOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'RedirectedOutput.txt'
        Start-Process $vswhereExePath `
            -Wait `
            -WorkingDirectory $PSHOME `
            -RedirectStandardOutput $RedirectedOutput `
            -NoNewWindow

        $content = Get-Content $RedirectedOutput
        Remove-Item $RedirectedOutput -Force -Recurse -ErrorAction SilentlyContinue

        $vsInstallationPath = ""
        if ([System.Text.RegularExpressions.Regex]::IsMatch($content, "installationPath")) {
            $vsInstallationPath = [System.Text.RegularExpressions.Regex]::Match($content, "(?<=installationPath: ).*(?= installationVersion:)");
            $vsInstallationPath = $vsInstallationPath.ToString()
        }

        
        
        if ($vsInstallationPath) {
            $credProviderPath = ($vsInstallationPath + '\Common7\IDE\CommonExtensions\Microsoft\NuGet\Plugins\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe')
            if (!(Test-Path $credProviderPath -PathType Leaf)) {
                return $null
            }
            $callDotnet = $false;
        }
    }

    if (!(Test-Path $credProviderPath -PathType Leaf)) {
        return $null
    }

    $filename = $credProviderPath
    $arguments = "-U $SourceLocation"
    if ($callDotnet) {
        $filename = "dotnet"
        $arguments = "$credProviderPath $arguments"
    }
    $argumentsNoRetry = $arguments
    if ($isRetry) {
        $arguments = "$arguments -I";
        Write-Debug "Credential provider is re-running with -IsRetry"
    }

    Write-Debug "Credential provider path is: $credProviderPath"
    
    
    Start-Process $filename -ArgumentList "$arguments -V minimal" `
        -Wait `
        -WorkingDirectory $PSHOME `
        -NoNewWindow

    
    $RedirectedOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'RedirectedOutput.txt'
    Start-Process $filename -ArgumentList "$argumentsNoRetry -V verbose" `
        -Wait `
        -WorkingDirectory $PSHOME `
        -RedirectStandardOutput $RedirectedOutput `
        -NoNewWindow

    $content = Get-Content $RedirectedOutput
    Remove-Item $RedirectedOutput -Force -Recurse -ErrorAction SilentlyContinue

    $username = [System.Text.RegularExpressions.Regex]::Match($content, '(?<=Username: )\S*')
    $password = [System.Text.RegularExpressions.Regex]::Match($content, '(?<=Password: ).*')

    if ($username -and $password) {
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

        return $credential
    }

    return $null
}
