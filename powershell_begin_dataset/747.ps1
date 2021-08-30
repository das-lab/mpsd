


[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter()]
    [ValidateSet('64-bit', '32-bit')]
    [string]$Architecture = '64-bit',

    [parameter()]
    [ValidateSet('Stable-System', 'Stable-User', 'Insider-System', 'Insider-User')]
    [string]$BuildEdition = "Stable-System",

    [Parameter()]
    [ValidateNotNull()]
    [string[]]$AdditionalExtensions = @(),

    [switch]$LaunchWhenDone,

    [switch]$EnableContextMenus
)


$script:VSCodeYumRepoEntry = @"
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"@

$script:VSCodeZypperRepoEntry = @"
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"@

function Test-IsOsArchX64 {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq '64-bit'
    }

    return [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::X64
}

function Get-AvailablePackageManager
{
    if (Get-Command 'apt' -ErrorAction SilentlyContinue) {
        return 'apt'
    }

    if (Get-Command 'dnf' -ErrorAction SilentlyContinue) {
        return 'dnf'
    }

    if (Get-Command 'yum' -ErrorAction SilentlyContinue) {
        return 'yum'
    }

    if (Get-Command 'zypper' -ErrorAction SilentlyContinue) {
        return 'zypper'
    }
}

function Get-CodePlatformInformation {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('32-bit', '64-bit')]
        [string]
        $Bitness,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Stable-System', 'Stable-User', 'Insider-System', 'Insider-User')]
        [string]
        $BuildEdition
    )

    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        $os = 'Windows'
    }
    elseif ($IsLinux) {
        $os = 'Linux'
    }
    elseif ($IsMacOS) {
        $os = 'MacOS'
    }
    else {
        throw 'Could not identify operating system'
    }

    if ($Bitness -ne '64-bit' -and $os -ne 'Windows') {
        throw "Non-64-bit *nix systems are not supported"
    }

    if ($BuildEdition.EndsWith('User') -and $os -ne 'Windows') {
        throw 'User builds are not available for non-Windows systems'
    }

    switch ($BuildEdition) {
        'Stable-System' {
            $appName = "Visual Studio Code ($Bitness)"
            break
        }

        'Stable-User' {
            $appName = "Visual Studio Code ($($Architecture) - User)"
            break
        }

        'Insider-System' {
            $appName = "Visual Studio Code - Insiders Edition ($Bitness)"
            break
        }

        'Insider-User' {
            $appName = "Visual Studio Code - Insiders Edition ($($Architecture) - User)"
            break
        }
    }

    switch ($os) {
        'Linux' {
            $pacMan = Get-AvailablePackageManager

            switch ($pacMan) {
                'apt' {
                    $platform = 'linux-deb-x64'
                    $ext = 'deb'
                    break
                }

                { 'dnf','yum','zypper' -contains $_ } {
                    $platform = 'linux-rpm-x64'
                    $ext = 'rpm'
                    break
                }

                default {
                    $platform = 'linux-x64'
                    $ext = 'tar.gz'
                    break
                }
            }

            if ($BuildEdition.StartsWith('Insider')) {
                $exePath = '/usr/bin/code-insiders'
                break
            }

            $exePath = '/usr/bin/code'
            break
        }

        'MacOS' {
            $platform = 'darwin'
            $ext = 'zip'

            if ($BuildEdition.StartsWith('Insider')) {
                $exePath = '/usr/local/bin/code-insiders'
                break
            }

            $exePath = '/usr/local/bin/code'
            break
        }

        'Windows' {
            $ext = 'exe'
            switch ($Bitness) {
                '32-bit' {
                    $platform = 'win32'

                    if (Test-IsOsArchX64) {
                        $installBase = ${env:ProgramFiles(x86)}
                        break
                    }

                    $installBase = ${env:ProgramFiles}
                    break
                }

                '64-bit' {
                    $installBase = ${env:ProgramFiles}

                    if (Test-IsOsArchX64) {
                        $platform = 'win32-x64'
                        break
                    }

                    Write-Warning '64-bit install requested on 32-bit system. Installing 32-bit VSCode'
                    $platform = 'win32'
                    break
                }
            }

            switch ($BuildEdition) {
                'Stable-System' {
                    $exePath = "$installBase\Microsoft VS Code\bin\code.cmd"
                }

                'Stable-User' {
                    $exePath = "${env:LocalAppData}\Programs\Microsoft VS Code\bin\code.cmd"
                }

                'Insider-System' {
                    $exePath = "$installBase\Microsoft VS Code Insiders\bin\code-insiders.cmd"
                }

                'Insider-User' {
                    $exePath = "${env:LocalAppData}\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd"
                }
            }
        }
    }

    switch ($BuildEdition) {
        'Stable-System' {
            $channel = 'stable'
            break
        }

        'Stable-User' {
            $channel = 'stable'
            $platform += '-user'
            break
        }

        'Insider-System' {
            $channel = 'insider'
            break
        }

        'Insider-User' {
            $channel = 'insider'
            $platform += '-user'
            break
        }
    }

    $info = @{
        AppName = $appName
        ExePath = $exePath
        Platform = $platform
        Channel = $channel
        FileUri = "https://vscode-update.azurewebsites.net/latest/$platform/$channel"
        Extension = $ext
    }

    if ($pacMan) {
        $info['PackageManager'] = $pacMan
    }

    return $info
}

function Save-WithBitsTransfer {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $FileUri,

        [Parameter(Mandatory=$true)]
        [string]
        $Destination,

        [Parameter(Mandatory=$true)]
        [string]
        $AppName
    )

    Write-Host "`nDownloading latest $AppName..." -ForegroundColor Yellow

    Remove-Item -Force $Destination -ErrorAction SilentlyContinue

    $bitsDl = Start-BitsTransfer $FileUri -Destination $Destination -Asynchronous

    while (($bitsDL.JobState -eq 'Transferring') -or ($bitsDL.JobState -eq 'Connecting')) {
        Write-Progress -Activity "Downloading: $AppName" -Status "$([math]::round($bitsDl.BytesTransferred / 1mb))mb / $([math]::round($bitsDl.BytesTotal / 1mb))mb" -PercentComplete ($($bitsDl.BytesTransferred) / $($bitsDl.BytesTotal) * 100 )
    }

    switch ($bitsDl.JobState) {

        'Transferred' {
            Complete-BitsTransfer -BitsJob $bitsDl
            break
        }

        'Error' {
            throw 'Error downloading installation media.'
        }
    }
}

function Install-VSCodeFromTar {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $TarPath,

        [Parameter()]
        [switch]
        $Insiders
    )

    $tarDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VSCodeTar'
    $destDir = '/opt/VSCode-linux-x64'

    New-Item -ItemType Directory -Force -Path $tarDir
    try {
        Push-Location $tarDir
        tar xf $TarPath
        Move-Item -LiteralPath "$tarDir/VSCode-linux-x64" $destDir
    }
    finally {
        Pop-Location
    }

    if ($Insiders) {
        ln -s "$destDir/code-insiders" /usr/bin/code-insiders
        return
    }

    ln -s "$destDir/code" /usr/bin/code
}


if (($IsLinux -or $IsMacOS) -and (id -u) -ne 0) {
    throw "Must be running as root to install VSCode.`nInvoke this script with (for example):`n`tsudo pwsh -f Install-VSCode.ps1 -BuildEdition Stable-System"
}


if ($BuildEdition.EndsWith('User') -and -not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
    throw 'User builds are not available for non-Windows systems'
}

try {
    $prevProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    
    $codePlatformInfo = Get-CodePlatformInformation -Bitness $Architecture -BuildEdition $BuildEdition

    
    $tmpdir = [System.IO.Path]::GetTempPath()

    $ext = $codePlatformInfo.Extension
    $installerName = "vscode-install.$ext"

    $installerPath = [System.IO.Path]::Combine($tmpdir, $installerName)

    if ($PSVersionTable.PSVersion.Major -le 5) {
        Save-WithBitsTransfer -FileUri $codePlatformInfo.FileUri -Destination $installerPath -AppName $codePlatformInfo.AppName
    }
    
    elseif ($codePlatformInfo.Extension -ne 'rpm') {
        if ($PSCmdlet.ShouldProcess($codePlatformInfo.FileUri, "Invoke-WebRequest -OutFile $installerPath")) {
            Invoke-WebRequest -Uri $codePlatformInfo.FileUri -OutFile $installerPath
        }
    }

    
    switch ($codePlatformInfo.Extension) {
        
        'deb' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, 'apt install -y')) {
                break
            }

            
            
            apt install -y $installerPath
            break
        }

        
        
        
        'rpm' {
            $pacMan = $codePlatformInfo.PackageManager
            if (-not $PSCmdlet.ShouldProcess($installerPath, "$pacMan install -y")) {
                break
            }

            
            rpm --import https://packages.microsoft.com/keys/microsoft.asc

            switch ($pacMan) {
                'zypper' {
                    $script:VSCodeZypperRepoEntry > /etc/zypp/repos.d/vscode.repo
                    zypper refresh -y
                }

                default {
                    $script:VSCodeYumRepoEntry > /etc/yum.repos.d/vscode.repo
                    & $pacMan check-update -y
                }
            }

            switch ($BuildEdition) {
                'Stable-System' {
                    & $pacMan install -y code
                }

                default {
                    & $pacMan install -y code-insiders
                }
            }
            break
        }

        
        'exe' {
            $exeArgs = '/verysilent /tasks=addtopath'
            if ($EnableContextMenus) {
                $exeArgs = '/verysilent /tasks=addcontextmenufiles,addcontextmenufolders,addtopath'
            }

            if (-not $PSCmdlet.ShouldProcess("$installerPath $exeArgs", 'Start-Process -Wait')) {
                break
            }

            Start-Process -Wait $installerPath -ArgumentList $exeArgs
            break
        }

        
        'zip' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, "Expand-Archive -DestinationPath $zipDirPath -Force; Move-Item $zipDirPath/*.app /Applications/")) {
                break
            }

            $zipDirPath = [System.IO.Path]::Combine($tmpdir, 'VSCode')
            Expand-Archive -LiteralPath $installerPath -DestinationPath $zipDirPath -Force
            Move-Item "$zipDirPath/*.app" '/Applications/'
            break
        }

        
        'tar.gz' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, 'Install-VSCodeFromTar (expand, move to /opt/, symlink)')) {
                break
            }

            Install-VSCodeFromTar -TarPath $installerPath -Insiders:($BuildEdition -ne 'Stable-System')
            break
        }

        default {
            throw "Unkown package type: $($codePlatformInfo.Extension)"
        }
    }

    $codeExePath = $codePlatformInfo.ExePath

    
    $extensions = @("ms-vscode.PowerShell") + $AdditionalExtensions
    if ($PSCmdlet.ShouldProcess(($extensions -join ','), "$codeExePath --install-extension")) {
        if ($IsLinux -or $IsMacOS) {
            
            $extsSlashes = $extensions -join '/'
            sudo -H -u $env:SUDO_USER pwsh -c "`$exts = '$extsSlashes' -split '/'; foreach (`$e in `$exts) { $codeExePath --install-extension `$e }"
        }
        else {
            foreach ($extension in $extensions) {
                Write-Host "`nInstalling extension $extension..." -ForegroundColor Yellow
                & $codeExePath --install-extension $extension
            }
        }
    }

    
    if ($LaunchWhenDone) {
        $appName = $codePlatformInfo.AppName

        if (-not $PSCmdlet.ShouldProcess($appName, "Launch with $codeExePath")) {
            return
        }

        Write-Host "`nInstallation complete, starting $appName...`n`n" -ForegroundColor Green
        & $codeExePath
        return
    }

    if ($PSCmdlet.ShouldProcess('Installation complete!', 'Write-Host')) {
        Write-Host "`nInstallation complete!`n`n" -ForegroundColor Green
    }
}
finally {
    $ProgressPreference = $prevProgressPreference
}
