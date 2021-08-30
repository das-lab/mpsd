




param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [string]$PsesSubmodulePath = "$PSScriptRoot/module",

    [string]$ModulesJsonPath = "$PSScriptRoot/modules.json",

    [string]$DefaultModuleRepository = "PSGallery",

    [string]$TestFilter = ''
)



$script:IsUnix = $PSVersionTable.PSEdition -and $PSVersionTable.PSEdition -eq "Core" -and !$IsWindows
$script:TargetPlatform = "netstandard2.0"
$script:TargetFrameworksParam = "/p:TargetFrameworks=`"$script:TargetPlatform`""
$script:RequiredSdkVersion = (Get-Content (Join-Path $PSScriptRoot 'global.json') | ConvertFrom-Json).sdk.version
$script:NugetApiUriBase = 'https://www.nuget.org/api/v2/package'
$script:ModuleBinPath = "$PSScriptRoot/module/PowerShellEditorServices/bin/"
$script:VSCodeModuleBinPath = "$PSScriptRoot/module/PowerShellEditorServices.VSCode/bin/"
$script:WindowsPowerShellFrameworkTarget = 'net461'
$script:NetFrameworkPlatformId = 'win'
$script:BuildInfoPath = [System.IO.Path]::Combine($PSScriptRoot, "src", "PowerShellEditorServices", "Hosting", "BuildInfo.cs")

$script:PSCoreModulePath = $null

$script:TestRuntime = @{
    'Core'    = 'netcoreapp2.1'
    'Desktop' = 'net461'
}


$script:RequiredBuildAssets = @{
    $script:ModuleBinPath = @{
        'PowerShellEditorServices' = @(
            'publish/Microsoft.Extensions.DependencyInjection.Abstractions.dll',
            'publish/Microsoft.Extensions.DependencyInjection.dll',
            'publish/Microsoft.Extensions.FileSystemGlobbing.dll',
            'publish/Microsoft.Extensions.Logging.Abstractions.dll',
            'publish/Microsoft.Extensions.Logging.dll',
            'publish/Microsoft.Extensions.Options.dll',
            'publish/Microsoft.Extensions.Primitives.dll',
            'publish/Microsoft.PowerShell.EditorServices.dll',
            'publish/Microsoft.PowerShell.EditorServices.pdb',
            'publish/Newtonsoft.Json.dll',
            'publish/OmniSharp.Extensions.JsonRpc.dll',
            'publish/OmniSharp.Extensions.LanguageProtocol.dll',
            'publish/OmniSharp.Extensions.LanguageServer.dll',
            'publish/OmniSharp.Extensions.DebugAdapter.dll',
            'publish/OmniSharp.Extensions.DebugAdapter.Server.dll',
            'publish/MediatR.dll',
            'publish/MediatR.Extensions.Microsoft.DependencyInjection.dll',
            'publish/runtimes/linux-64/native/libdisablekeyecho.so',
            'publish/runtimes/osx-64/native/libdisablekeyecho.dylib',
            'publish/Serilog.dll',
            'publish/Serilog.Extensions.Logging.dll',
            'publish/Serilog.Sinks.File.dll',
            'publish/System.Reactive.dll',
            'publish/UnixConsoleEcho.dll'
        )
    }

    $script:VSCodeModuleBinPath = @{
        'PowerShellEditorServices.VSCode' = @(
            'Microsoft.PowerShell.EditorServices.VSCode.dll',
            'Microsoft.PowerShell.EditorServices.VSCode.pdb'
        )
    }
}


$script:RequiredNugetBinaries = @{
    'Desktop' = @(
        @{ PackageName = 'System.Security.Principal.Windows'; PackageVersion = '4.5.0'; TargetRuntime = 'net461' },
        @{ PackageName = 'System.Security.AccessControl';     PackageVersion = '4.5.0'; TargetRuntime = 'net461' },
        @{ PackageName = 'System.IO.Pipes.AccessControl';     PackageVersion = '4.5.1'; TargetRuntime = 'net461' }
    )
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    
    git update-index --assume-unchanged "$PSScriptRoot/src/PowerShellEditorServices.Host/BuildInfo/BuildInfo.cs"
}

if ($PSVersionTable.PSEdition -ne "Core") {
    Add-Type -Assembly System.IO.Compression.FileSystem
}

function Restore-NugetAsmForRuntime {
    param(
        [ValidateNotNull()][string]$PackageName,
        [ValidateNotNull()][string]$PackageVersion,
        [string]$DllName,
        [string]$DestinationPath,
        [string]$TargetPlatform = $script:NetFrameworkPlatformId,
        [string]$TargetRuntime = $script:WindowsPowerShellFrameworkTarget
    )

    $tmpDir = Join-Path $PSScriptRoot '.tmp'
    if (-not (Test-Path $tmpDir)) {
        New-Item -ItemType Directory -Path $tmpDir
    }

    if (-not $DllName) {
        $DllName = "$PackageName.dll"
    }

    if ($DestinationPath -eq $null) {
        $DestinationPath = Join-Path $tmpDir $DllName
    } elseif (Test-Path $DestinationPath -PathType Container) {
        $DestinationPath = Join-Path $DestinationPath $DllName
    }

    $packageDirPath = Join-Path $tmpDir "$PackageName.$PackageVersion"
    if (-not (Test-Path $packageDirPath)) {
        $guid = New-Guid
        $tmpNupkgPath = Join-Path $tmpDir "$guid.zip"
        if (Test-Path $tmpNupkgPath) {
            Remove-Item -Force $tmpNupkgPath
        }

        try {
            $packageUri = "$script:NugetApiUriBase/$PackageName/$PackageVersion"
            Invoke-WebRequest -Uri $packageUri -OutFile $tmpNupkgPath
            Expand-Archive -Path $tmpNupkgPath -DestinationPath $packageDirPath
        } finally {
            Remove-Item -Force $tmpNupkgPath -ErrorAction SilentlyContinue
        }
    }

    $internalPath = [System.IO.Path]::Combine($packageDirPath, 'runtimes', $TargetPlatform, 'lib', $TargetRuntime, $DllName)

    Copy-Item -Path $internalPath -Destination $DestinationPath -Force

    return $DestinationPath
}

function Invoke-WithCreateDefaultHook {
    param([scriptblock]$ScriptBlock)

    try
    {
        $env:PSES_TEST_USE_CREATE_DEFAULT = 1
        & $ScriptBlock
    } finally {
        Remove-Item env:PSES_TEST_USE_CREATE_DEFAULT
    }
}

task SetupDotNet -Before Clean, Build, TestHost, TestServer, TestProtocol, TestE2E {

    $dotnetPath = "$PSScriptRoot/.dotnet"
    $dotnetExePath = if ($script:IsUnix) { "$dotnetPath/dotnet" } else { "$dotnetPath/dotnet.exe" }
    $originalDotNetExePath = $dotnetExePath

    if (!(Test-Path $dotnetExePath)) {
        $installedDotnet = Get-Command dotnet -ErrorAction Ignore
        if ($installedDotnet) {
            $dotnetExePath = $installedDotnet.Source
        }
        else {
            $dotnetExePath = $null
        }
    }

    
    if ($dotnetExePath) {
        
        if ((& $dotnetExePath --list-sdks | ForEach-Object { $_.Split()[0] } ) -contains $script:RequiredSdkVersion) {
            $script:dotnetExe = $dotnetExePath
        }
        else {
            
            $script:dotnetExe = $null
        }
    }
    else {
        
        $script:dotnetExe = $null
    }

    if ($script:dotnetExe -eq $null) {

        Write-Host "`n

        
        $installScriptExt = if ($script:IsUnix) { "sh" } else { "ps1" }

        
        $installScriptPath = "$([System.IO.Path]::GetTempPath())dotnet-install.$installScriptExt"
        Invoke-WebRequest "https://raw.githubusercontent.com/dotnet/cli/v$script:RequiredSdkVersion/scripts/obtain/dotnet-install.$installScriptExt" -OutFile $installScriptPath
        $env:DOTNET_INSTALL_DIR = "$PSScriptRoot/.dotnet"

        if (!$script:IsUnix) {
            & $installScriptPath -Version $script:RequiredSdkVersion -InstallDir "$env:DOTNET_INSTALL_DIR"
        }
        else {
            & /bin/bash $installScriptPath -Version $script:RequiredSdkVersion -InstallDir "$env:DOTNET_INSTALL_DIR"
            $env:PATH = $dotnetExeDir + [System.IO.Path]::PathSeparator + $env:PATH
        }

        Write-Host "`n
        $script:dotnetExe = $originalDotnetExePath
    }

    
    $script:dotnetExe = Resolve-Path $script:dotnetExe
    if (!$env:DOTNET_INSTALL_DIR)
    {
        $dotnetExeDir = [System.IO.Path]::GetDirectoryName($script:dotnetExe)
        $env:PATH = $dotnetExeDir + [System.IO.Path]::PathSeparator + $env:PATH
        $env:DOTNET_INSTALL_DIR = $dotnetExeDir
    }

    Write-Host "`n
}

task Clean {
    exec { & $script:dotnetExe restore }
    exec { & $script:dotnetExe clean }
    Remove-Item $PSScriptRoot\.tmp -Recurse -Force -ErrorAction Ignore
    Remove-Item $PSScriptRoot\module\PowerShellEditorServices\bin -Recurse -Force -ErrorAction Ignore
    Remove-Item $PSScriptRoot\module\PowerShellEditorServices.VSCode\bin -Recurse -Force -ErrorAction Ignore
    Get-ChildItem -Recurse $PSScriptRoot\src\*.nupkg | Remove-Item -Force -ErrorAction Ignore
    Get-ChildItem $PSScriptRoot\PowerShellEditorServices*.zip | Remove-Item -Force -ErrorAction Ignore
    Get-ChildItem $PSScriptRoot\module\PowerShellEditorServices\Commands\en-US\*-help.xml | Remove-Item -Force -ErrorAction Ignore
}

task GetProductVersion -Before PackageModule, UploadArtifacts {
    [xml]$props = Get-Content .\PowerShellEditorServices.Common.props

    $script:BuildNumber = 9999
    $script:VersionSuffix = $props.Project.PropertyGroup.VersionSuffix

    if ($env:TF_BUILD) {
        
        
        $jobname = $env:SYSTEM_PHASENAME -replace '_', ''
        $script:BuildNumber = "$jobname-$env:BUILD_BUILDID"
    }

    if ($script:VersionSuffix -ne $null) {
        $script:VersionSuffix = "$script:VersionSuffix-$script:BuildNumber"
    }
    else {
        $script:VersionSuffix = "$script:BuildNumber"
    }

    $script:FullVersion = "$($props.Project.PropertyGroup.VersionPrefix)-$script:VersionSuffix"

    Write-Host "`n
}

task CreateBuildInfo -Before Build {
    $buildVersion = "<development-build>"
    $buildOrigin = "<development>"

    
    if ($env:TF_BUILD)
    {
        $psd1Path = [System.IO.Path]::Combine($PSScriptRoot, "module", "PowerShellEditorServices", "PowerShellEditorServices.psd1")
        $buildVersion = (Import-PowerShellDataFile -LiteralPath $psd1Path).Version
        $buildOrigin = "VSTS"
    }

    
    if ($env:PSES_BUILD_VERSION)
    {
        $buildVersion = $env:PSES_BUILD_VERSION
    }

    if ($env:PSES_BUILD_ORIGIN)
    {
        $buildOrigin = $env:PSES_BUILD_ORIGIN
    }

    [string]$buildTime = [datetime]::Now.ToString("s", [System.Globalization.CultureInfo]::InvariantCulture)

    $buildInfoContents = @"
namespace Microsoft.PowerShell.EditorServices.Hosting
{
    public static class BuildInfo
    {
        public const string BuildVersion = "$buildVersion";
        public const string BuildOrigin = "$buildOrigin";
        public static readonly System.DateTime? BuildTime = System.DateTime.Parse("$buildTime");
    }
}
"@

    Set-Content -LiteralPath $script:BuildInfoPath -Value $buildInfoContents -Force
}

task SetupHelpForTests -Before Test {
    if (-not (Get-Help Write-Host).Examples) {
        Update-Help -Module Microsoft.PowerShell.Utility -Force -Scope CurrentUser
    }
}

task Build {
    exec { & $script:dotnetExe publish -c $Configuration .\src\PowerShellEditorServices\PowerShellEditorServices.csproj -f $script:TargetPlatform }
    exec { & $script:dotnetExe build -c $Configuration .\src\PowerShellEditorServices.VSCode\PowerShellEditorServices.VSCode.csproj $script:TargetFrameworksParam }
}

function DotNetTestFilter {
    
    if ($TestFilter) { @("--filter",$TestFilter) } else { "" }
}


task Test TestE2E

task TestServer {
    Set-Location .\test\PowerShellEditorServices.Test\

    if (-not $script:IsUnix) {
        exec { & $script:dotnetExe test --logger trx -f $script:TestRuntime.Desktop (DotNetTestFilter) }
    }

    Invoke-WithCreateDefaultHook -NewModulePath $script:PSCoreModulePath {
        exec { & $script:dotnetExe test --logger trx -f $script:TestRuntime.Core (DotNetTestFilter) }
    }
}

task TestProtocol {
    Set-Location .\test\PowerShellEditorServices.Test.Protocol\

    if (-not $script:IsUnix) {
        exec { & $script:dotnetExe test --logger trx -f $script:TestRuntime.Desktop (DotNetTestFilter) }
    }

    Invoke-WithCreateDefaultHook {
        exec { & $script:dotnetExe test --logger trx -f $script:TestRuntime.Core (DotNetTestFilter) }
    }
}

task TestHost {
    Set-Location .\test\PowerShellEditorServices.Test.Host\

    if (-not $script:IsUnix) {
        exec { & $script:dotnetExe build -f $script:TestRuntime.Desktop }
        exec { & $script:dotnetExe test -f $script:TestRuntime.Desktop (DotNetTestFilter) }
    }

    exec { & $script:dotnetExe build -c $Configuration -f $script:TestRuntime.Core }
    exec { & $script:dotnetExe test -f $script:TestRuntime.Core (DotNetTestFilter) }
}

task TestE2E {
    Set-Location .\test\PowerShellEditorServices.Test.E2E\

    $env:PWSH_EXE_NAME = if ($IsCoreCLR) { "pwsh" } else { "powershell" }
    exec { & $script:dotnetExe test --logger trx -f $script:TestRuntime.Core (DotNetTestFilter) }
}

task LayoutModule -After Build {
    
    Copy-Item -Force -Path "$PSScriptRoot\Third Party Notices.txt" -Destination $PSScriptRoot\module\PowerShellEditorServices

    
    
    foreach ($destDir in $script:RequiredBuildAssets.Keys) {
        
        $null = New-Item -Force $destDir -Type Directory

        
        foreach ($projectName in $script:RequiredBuildAssets[$destDir].Keys) {
            
            $basePath = [System.IO.Path]::Combine($PSScriptRoot, 'src', $projectName, 'bin', $Configuration, $script:TargetPlatform)

            
            foreach ($bin in $script:RequiredBuildAssets[$destDir][$projectName]) {
                
                $binPath = Join-Path $basePath $bin

                
                Copy-Item -Force -Verbose $binPath $destDir
            }
        }
    }

    
    foreach ($binDestinationDir in $script:RequiredNugetBinaries.Keys) {
        $binDestPath = Join-Path $script:ModuleBinPath $binDestinationDir
        if (-not (Test-Path $binDestPath)) {
            New-Item -Path $binDestPath -ItemType Directory
        }

        foreach ($packageDetails in $script:RequiredNugetBinaries[$binDestinationDir]) {
            Restore-NugetAsmForRuntime -DestinationPath $binDestPath @packageDetails
        }
    }
}

task RestorePsesModules -After Build {
    $submodulePath = (Resolve-Path $PsesSubmodulePath).Path + [IO.Path]::DirectorySeparatorChar
    Write-Host "`nRestoring EditorServices modules..."

    
    $moduleInfos = @{}

    (Get-Content -Raw $ModulesJsonPath | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
        $name = $_.Name
        $body = @{
            Name = $name
            MinimumVersion = $_.Value.MinimumVersion
            MaximumVersion = $_.Value.MaximumVersion
            AllowPrerelease = $_.Value.AllowPrerelease
            Repository = if ($_.Value.Repository) { $_.Value.Repository } else { $DefaultModuleRepository }
            Path = $submodulePath
        }

        if (-not $name)
        {
            throw "EditorServices module listed without name in '$ModulesJsonPath'"
        }

        $moduleInfos.Add($name, $body)
    }

    if ($moduleInfos.Keys.Count -gt 0) {
        
        
        
        Import-Module -Name PowerShellGet -MinimumVersion 1.6.0 -ErrorAction Stop
    }

    
    foreach ($moduleName in $moduleInfos.Keys)
    {
        if (Test-Path -Path (Join-Path -Path $submodulePath -ChildPath $moduleName))
        {
            Write-Host "`tModule '${moduleName}' already detected. Skipping"
            continue
        }

        $moduleInstallDetails = $moduleInfos[$moduleName]

        $splatParameters = @{
           Name = $moduleName
           MinimumVersion = $moduleInstallDetails.MinimumVersion
           MaximumVersion = $moduleInstallDetails.MaximumVersion
           AllowPrerelease = $moduleInstallDetails.AllowPrerelease
           Repository = if ($moduleInstallDetails.Repository) { $moduleInstallDetails.Repository } else { $DefaultModuleRepository }
           Path = $submodulePath
        }

        Write-Host "`tInstalling module: ${moduleName} with arguments $(ConvertTo-Json $splatParameters)"

        Save-Module @splatParameters
    }

    Write-Host "`n"
}

task BuildCmdletHelp {
    New-ExternalHelp -Path $PSScriptRoot\module\docs -OutputPath $PSScriptRoot\module\PowerShellEditorServices\Commands\en-US -Force
    New-ExternalHelp -Path $PSScriptRoot\module\PowerShellEditorServices.VSCode\docs -OutputPath $PSScriptRoot\module\PowerShellEditorServices.VSCode\en-US -Force
}

task PackageModule {
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        "$PSScriptRoot/module/",
        "$PSScriptRoot/PowerShellEditorServices-$($script:FullVersion).zip",
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false)
}

task UploadArtifacts -If ($null -ne $env:TF_BUILD) {
    Copy-Item -Path .\PowerShellEditorServices-$($script:FullVersion).zip -Destination $env:BUILD_ARTIFACTSTAGINGDIRECTORY
}


task . GetProductVersion, Clean, Build, Test, BuildCmdletHelp, PackageModule, UploadArtifacts
