

function script:Start-NativeExecution([scriptblock]$sb, [switch]$IgnoreExitcode) {
    $backupEAP = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    try {
        & $sb
        
        
        if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
            throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        $script:ErrorActionPreference = $backupEAP
    }
}

function Install-Dotnet {
    [CmdletBinding()]
    param(
        [string]$Channel = $dotnetCLIChannel,
        [string]$Version = $dotnetCLIRequiredVersion,
        [switch]$NoSudo
    )

    
    
    $sudo = if (!$NoSudo) { "sudo" }

    $obtainUrl = "https://raw.githubusercontent.com/dotnet/cli/master/scripts/obtain"

    
    if ($IsLinux -or $IsMacOS) {
        
        $uninstallScript = if ($IsUbuntu) {
            "dotnet-uninstall-debian-packages.sh"
        }
        elseif ($IsMacOS) {
            "dotnet-uninstall-pkgs.sh"
        }

        if ($uninstallScript) {
            Start-NativeExecution {
                curl -sO $obtainUrl/uninstall/$uninstallScript
                Invoke-Expression "$sudo bash ./$uninstallScript"
            }
        }
        else {
            Write-Warning "This script only removes prior versions of dotnet for Ubuntu 14.04 and OS X"
        }

        
        $installScript = "dotnet-install.sh"
        Start-NativeExecution {
            curl -sO $obtainUrl/$installScript
            bash ./$installScript -c $Channel -v $Version
        }
    }
    elseif (!(Test-Path Variable:\IsWindows) -or $IsWindows) {
        Remove-Item -ErrorAction SilentlyContinue -Recurse -Force ~\AppData\Local\Microsoft\dotnet
        $installScript = "dotnet-install.ps1"
        Invoke-WebRequest -Uri $obtainUrl/$installScript -OutFile $installScript

        if (-not $IsCoreCLR) {
            & ./$installScript -Channel $Channel -Version $Version
        }
        else {
            
            $fullPSPath = Join-Path -Path $env:windir -ChildPath "System32\WindowsPowerShell\v1.0\powershell.exe"
            $fullDotnetInstallPath = Join-Path -Path $pwd.Path -ChildPath $installScript
            Start-NativeExecution { & $fullPSPath -NoLogo -NoProfile -File $fullDotnetInstallPath -Channel $Channel -Version $Version }
        }
    }
}
