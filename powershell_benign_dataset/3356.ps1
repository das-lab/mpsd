















param(
    [CmdletBinding()]
    [Parameter(Mandatory = $false, Position = 0)]
    [switch]$IsNetCore,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("Debug", "Release")]
    [string]$BuildConfig,

    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateSet("All", "Latest", "Stack", "NetCore", "ServiceManagement", "AzureStorage")]
    [string]$Scope,

    [Parameter(Mandatory = $false, Position = 3)]
    [string]$ApiKey,

    [Parameter(Mandatory = $false, Position = 4)]
    [string]$RepositoryLocation,

    [Parameter(Mandatory = $false, Position = 5)]
    [string]$NugetExe
)




function Out-FileNoBom {
    param(
        [System.string]$File,
        [System.string]$Text
    )
    $encoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($File, $Text, $encoding)
}


function Get-Directories {
    [CmdletBinding()]
    param
    (
        [String]$BuildConfig,
        [String]$Scope
    )

    PROCESS {
        $packageFolder = "$PSScriptRoot\..\artifacts"

        $resourceManagerRootFolder = "$packageFolder\$buildConfig"

        Write-Output -InputObject $packageFolder, $resourceManagerRootFolder
    }
}




function Get-RollupModules {
    [CmdletBinding()]
    param
    (
        [string]$BuildConfig,
        [string]$Scope,
        [switch]$IsNetCore
    )

    PROCESS {
        $targets = @()

        if ($Scope -eq 'Stack') {
            Write-Host "Publishing AzureRM"
            $targets += "$PSScriptRoot\..\src\StackAdmin\AzureRM"
            $targets += "$PSScriptRoot\..\src\StackAdmin\AzureStack"
        }

        if ($Scope -eq 'All' -or $Scope -eq 'Latest' -or $Scope -eq 'NetCore') {
            if ($IsNetCore) {
                
                $targets += "$PSScriptRoot\Az"
            } else {
                $targets += "$PSScriptRoot\AzureRM"
            }
        }

        Write-Output -InputObject $targets
    }
}


function Get-AdminModules {
    [CmdletBinding()]
    param
    (
        [string]$BuildConfig,
        [string]$Scope
    )

    PROCESS {
        $targets = @()
        if ($Scope -eq "Stack") {
            $packageFolder, $resourceManagerRootFolder = Get-Directories -BuildConfig $BuildConfig -Scope $Scope

            $resourceManagerModules = Get-ChildItem -Path $resourceManagerRootFolder -Directory -Filter Azs.*
            foreach ($module in $resourceManagerModules) {
                $targets += $module.FullName
            }
        }
        Write-Output -InputObject $targets
    }
}



function Get-ClientModules {
    [CmdletBinding()]
    param
    (
        [string]$BuildConfig,
        [string]$Scope,
        [bool]$PublishLocal,
        [switch]$IsNetCore
    )

    PROCESS {
        $targets = @()

        $packageFolder, $resourceManagerRootFolder = Get-Directories -BuildConfig $BuildConfig -Scope $Scope

        
        $AllScopes = @('Stack', 'All', 'Latest', 'NetCore')
        if ($Scope -in $AllScopes -or $PublishLocal) {
            if ($Scope -eq "Netcore")
            {
                $targets += "$resourceManagerRootFolder\Az.Accounts"
            }
            else
            {
                $targets += "$resourceManagerRootFolder\AzureRM.Profile"
            }
        }

        $StorageScopes = @('All', 'Latest', 'Stack', 'AzureStorage')
        if ($Scope -in $StorageScopes) {
            $targets += "$packageFolder\$buildConfig\Storage\Azure.Storage"
        }

        
        if (-not $IsNetCore) {
            $ServiceScopes = @('All', 'Latest', 'ServiceManagement')
            if ($Scope -in $ServiceScopes) {
                $targets += "$packageFolder\$buildConfig\ServiceManagement\Azure"
            }
        }

        
        if ($Scope -in $AllScopes) {

            
            if ($IsNetCore) {
                $resourceManagerModules = Get-ChildItem -Path $resourceManagerRootFolder -Directory -Exclude Azs.* | Where-Object {$_.Name -like "*Az.*" -or $_.Name -eq "Az"}
            } else {
                $resourceManagerModules = Get-ChildItem -Path $resourceManagerRootFolder -Directory -Exclude Azs.* | Where-Object {$_.Name -like "*Azure*"}
            }

            
            $excludedModules = @('AzureRM.Profile', 'Azure.Storage', 'Az.Accounts')

            
            foreach ($module in $resourceManagerModules) {
                
                if (-not ($module.Name -in $excludedModules)) {
                    $targets += $module.FullName
                }
            }
        }
        Write-Output -InputObject $targets
    }
}


function Get-AllModules {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [String]$BuildConfig,

        [ValidateNotNullOrEmpty()]
        [String]$Scope,

        [switch]$PublishLocal,

        [switch]$IsNetCore
    )
    Write-Host "Getting Azure client modules"
    $clientModules = Get-ClientModules -BuildConfig $BuildConfig -Scope $Scope -PublishLocal:$PublishLocal -IsNetCore:$isNetCore
    Write-Host " "

    Write-Host "Getting admin modules"
    $adminModules = Get-AdminModules -BuildConfig $BuildConfig -Scope $Scope
    Write-Host " "

    Write-Host "Getting rollup modules"
    $rollupModules = Get-RollupModules -BuildConfig $BuildConfig -Scope $Scope -IsNetCore:$isNetCore
    Write-Host " "

    return @{
        ClientModules = $clientModules;
        AdminModules  = $adminModules;
        RollUpModules = $rollUpModules
    }
}





function Remove-ModuleDependencies {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    PROCESS {
        $regex = New-Object System.Text.RegularExpressions.Regex "RequiredModules\s*=\s*@\([^\)]+\)"
        $content = (Get-Content -Path $Path) -join "`r`n"
        $text = $regex.Replace($content, "RequiredModules = @()")
        Out-FileNoBom -File $Path -Text $text

        $regex = New-Object System.Text.RegularExpressions.Regex "NestedModules\s*=\s*@\([^\)]+\)"
        $content = (Get-Content -Path $Path) -join "`r`n"
        $text = $regex.Replace($content, "NestedModules = @()")
        Out-FileNoBom -File $Path -Text $text
    }
}


function Update-NugetPackage {
    [CmdletBinding()]
    param(
        [string]$TempRepoPath,
        [string]$ModuleName,
        [string]$DirPath,
        [string]$NugetExe
    )

    PROCESS {
        $regex2 = "<requireLicenseAcceptance>false</requireLicenseAcceptance>"

        $relDir = Join-Path $DirPath -ChildPath "_rels"
        $contentPath = Join-Path $DirPath -ChildPath '`[Content_Types`].xml'
        $packPath = Join-Path $DirPath -ChildPath "package"
        $modulePath = Join-Path $DirPath -ChildPath ($ModuleName + ".nuspec")

        
        Remove-Item -Recurse -Path $relDir -Force
        Remove-Item -Recurse -Path $packPath -Force
        Remove-Item -Path $contentPath -Force

        
        $content = (Get-Content -Path $modulePath) -join "`r`n"
        $content = $content -replace $regex2, ("<requireLicenseAcceptance>true</requireLicenseAcceptance>")
        Out-FileNoBom -File (Join-Path (Get-Location) $modulePath) -Text $content

        
        &$NugetExe pack $modulePath -OutputDirectory $TempRepoPath -NoPackageAnalysis
    }
}


function Add-Modules {
    [CmdletBinding()]
    param(
        [String[]]$ModulePaths,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepo,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepoPath,

        [ValidateNotNullOrEmpty()]
        [String]$NugetExe
    )
    PROCESS {
        foreach ($modulePath in $ModulePaths) {
            Write-Output $modulePath
            $module = Get-Item -Path $modulePath
            Write-Output "Updating $module module from $modulePath"
            Add-Module -Path $modulePath -TempRepo $TempRepo -TempRepoPath $TempRepoPath -NugetExe $NugetExe
            Write-Output "Updated $module module"
        }
    }
}


function Save-PackageLocally {
    [CmdletBinding()]
    param(
        $Module,
        [string]$TempRepo,
        [string]$TempRepoPath
    )

    $ModuleName = $module['ModuleName']
    $RequiredVersion = $module['RequiredVersion']

    
    if ($RequiredVersion -ne $null) {
        Write-Output "Checking for required module $ModuleName, $RequiredVersion"
        if (Find-Module -Name $ModuleName -RequiredVersion $RequiredVersion -Repository $TempRepo -ErrorAction SilentlyContinue) {
            Write-Output "Required dependency $ModuleName, $RequiredVersion found in the repo $TempRepo"
        } else {
            Write-Warning "Required dependency $ModuleName, $RequiredVersion not found in the repo $TempRepo"
            Write-Output "Downloading the package from PsGallery to the path $TempRepoPath"
            
            
            Save-Package -Name $ModuleName -RequiredVersion $RequiredVersion -ProviderName Nuget -Path $TempRepoPath -Source https://www.powershellgallery.com/api/v2 | Out-Null
            Write-Output "Downloaded the package sucessfully"
        }
    }
}


function Save-PackagesFromPsGallery {
    [CmdletBinding()]
    param(
        [String[]]$ModulePaths,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepo,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepoPath
    )
    PROCESS {

        Write-Output "Saving..."

        foreach ($modulePath in $ModulePaths) {

            Write-Output "module path $modulePath"

            $module = (Get-Item -Path $modulePath).Name
            $moduleManifest = $module + ".psd1"

            Write-Host "Verifying $module has all the dependencies in the repo $TempRepo"

            $psDataFile = Import-PowershellDataFile (Join-Path $modulePath -ChildPath $moduleManifest)
            $RequiredModules = $psDataFile['RequiredModules']

            if ($RequiredModules -ne $null) {
                foreach ($tmp in $RequiredModules) {
                    foreach ($module in $tmp) {
                        Save-PackageLocally -Module $module -TempRepo $TempRepo -TempRepoPath $TempRepoPath
                    }
                }
            }
        }
    }
}


function Add-AllModules {
    [CmdletBinding()]
    param(
        $ModulePaths,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepo,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepoPath,

        [ValidateNotNullOrEmpty()]
        [String]$NugetExe
    )
    $Keys = @('ClientModules', 'AdminModules', 'RollupModules')
    Write-Output "adding modules to local repo"
    foreach ($module in $Keys) {
        $modulePath = $Modules[$module]
        Write-Output "Adding $module modules to local repo"

        
        Save-PackagesFromPsGallery -TempRepo $TempRepo -TempRepoPath $TempRepoPath -ModulePaths $modulePath

        
        Add-Modules -TempRepo $TempRepo -TempRepoPath $TempRepoPath -ModulePath $modulePath -NugetExe $NugetExe
        Write-Output " "
    }
    Write-Output " "
}




function Add-PSM1Dependency {
    [CmdletBinding()]
    param(
        [string] $Path)

    PROCESS {
        $file = Get-Item -Path $Path
        $manifestFile = $file.Name
        $psm1file = $manifestFile -replace ".psd1", ".psm1"

        
        $regex = New-Object System.Text.RegularExpressions.Regex "
        $content = (Get-Content -Path $Path) -join "`r`n"
        $text = $regex.Replace($content, "RootModule = '$psm1file'")
        $text | Out-File -FilePath $Path
    }
}


function Add-Module {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [string]$TempRepo,

        [ValidateNotNullOrEmpty()]
        [string]$TempRepoPath,

        [ValidateNotNullOrEmpty()]
        [string]$NugetExe
    )

    PROCESS {

        $moduleName = (Get-Item -Path $Path).Name
        $moduleManifest = $moduleName + ".psd1"
        $moduleSourcePath = Join-Path -Path $Path -ChildPath $moduleManifest
        $file = Get-Item $moduleSourcePath
        Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $file.DirectoryName -FileName $file.Name

        $moduleVersion = $ModuleMetadata.ModuleVersion.ToString()
        if ($ModuleMetadata.PrivateData.PSData.Prerelease -ne $null) {
            $moduleVersion += ("-" + $ModuleMetadata.PrivateData.PSData.Prerelease -replace "--", "-")
        }

        if (Find-Module -Name $moduleName -Repository $TempRepo -RequiredVersion $moduleVersion -AllowPrerelease -ErrorAction SilentlyContinue)
        {
            Write-Output "Existing module found: $moduleName"
            $moduleNupkgPath = Join-Path -Path $TempRepoPath -ChildPath ($moduleName + "." + $moduleVersion + ".nupkg")
            Write-Output "Deleting the module: $moduleNupkgPath"
            Remove-Item -Path $moduleNupkgPath -Force
        }

        Write-Output "Publishing the module $moduleName"
        Publish-Module -Path $Path -Repository $TempRepo -Force | Out-Null
        Write-Output "$moduleName published"

        
        
        if ($ModuleMetadata.RootModule) {
            Write-Output "Root module found, done"
            return
        }
        Write-Output "No root module found, creating"

        Write-Output "Changing to local repository directory for module modifications $TempRepoPath"
        Push-Location $TempRepoPath

        try {

            
            $nupkgPath = Join-Path -Path . -ChildPath ($moduleName + "." + $moduleVersion + ".nupkg")
            $zipPath = Join-Path -Path . -ChildPath ($moduleName + "." + $moduleVersion + ".zip")
            $dirPath = Join-Path -Path . -ChildPath $moduleName
            $unzippedManifest = Join-Path -Path $dirPath -ChildPath ($moduleName + ".psd1")

            
            if (!(Test-Path -Path $nupkgPath)) {
                throw "Module at $nupkgPath in $TempRepoPath does not exist"
            }

            Write-Output "Renaming package $nupkgPath to zip archive $zipPath"
            Rename-Item $nupkgPath $zipPath

            Write-Output "Expanding $zipPath"
            Expand-Archive $zipPath -DestinationPath $dirPath

            Write-Output "Adding PSM1 dependency to $unzippedManifest"
            Add-PSM1Dependency -Path $unzippedManifest

            Write-Output "Removing module manifest dependencies for $unzippedManifest"
            Remove-ModuleDependencies -Path (Join-Path $TempRepoPath $unzippedManifest)

            Remove-Item -Path $zipPath -Force

            Write-Output "Repackaging $dirPath"
            Update-NugetPackage -TempRepoPath $TempRepoPath -ModuleName $moduleName -DirPath $dirPath -NugetExe $NugetExe
            Write-Output "Removing temporary folder $dirPath"
            Remove-Item -Recurse $dirPath -Force -ErrorAction Stop
        } finally {
            Pop-Location
        }
    }
}


function Publish-PowershellModule {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$ApiKey,
        [string]$TempRepoPath,
        [string]$RepoLocation,
        [string]$NugetExe
    )

    PROCESS {
        $moduleName = (Get-Item -Path $Path).Name
        $moduleManifest = $moduleName + ".psd1"
        $moduleSourcePath = Join-Path -Path $Path -ChildPath $moduleManifest
        $manifest = Test-ModuleManifest -Path $moduleSourcePath
        $nupkgPath = Join-Path -Path $TempRepoPath -ChildPath ($moduleName + "." + $manifest.Version.ToString() + ".nupkg")
        if (!(Test-Path -Path $nupkgPath)) {
            throw "Module at $nupkgPath in $TempRepoPath does not exist"
        }

        Write-Output "Pushing package $moduleName to nuget source $RepoLocation"
        &$NugetExe push $nupkgPath $ApiKey -s $RepoLocation
        Write-Output "Pushed package $moduleName to nuget source $RepoLocation"
    }
}


function Publish-AllModules {
    [CmdletBinding()]
    param(
        $ModulePaths,

        [ValidateNotNullOrEmpty()]
        [String]$ApiKey,

        [ValidateNotNullOrEmpty()]
        [String]$TempRepoPath,

        [ValidateNotNullOrEmpty()]
        [String]$RepoLocation,

        [ValidateNotNullOrEmpty()]
        [String]$NugetExe,

        [switch]$PublishLocal
    )
    if (!$PublishLocal) {
        foreach ($module in $ModulePaths.Keys) {
            $paths = $Modules[$module]
            foreach ($modulePath in $paths) {
                $module = Get-Item -Path $modulePath
                Write-Host "Pushing $module module from $modulePath"
                Publish-PowershellModule -Path $modulePath -ApiKey $apiKey -TempRepoPath $TempRepoPath -RepoLocation $RepoLocation -NugetExe $NugetExe
                Write-Host "Pushed $module module"
            }
        }
    }
}



if ([string]::IsNullOrEmpty($buildConfig)) {
    Write-Verbose "Setting build configuration to 'Release'"
    $buildConfig = "Release"
}

if ([string]::IsNullOrEmpty($repositoryLocation)) {
    Write-Verbose "Setting repository location to 'https://dtlgalleryint.cloudapp.net/api/v2'"
    $repositoryLocation = "https://dtlgalleryint.cloudapp.net/api/v2"
}

if ([string]::IsNullOrEmpty($nugetExe)) {
    Write-Verbose "Use default nuget path"
    $nugetExe = "$PSScriptRoot\nuget.exe"
}

Write-Host "Publishing $Scope package (and its dependencies)"

Get-PackageProvider -Name NuGet -Force
Write-Host " "


$packageFolder = "$PSScriptRoot\..\artifacts"
if ($Scope -eq 'Stack') {
    $packageFolder = "$PSScriptRoot\..\src\Stack"
}

$PublishLocal = test-path $repositoryLocation
[string]$tempRepoPath = "$packageFolder"
if ($PublishLocal) {
    if ($Scope -eq 'Stack') {
        $tempRepoPath = (Join-Path $repositoryLocation -ChildPath "Stack")
    } else {
        $tempRepoPath = (Join-Path $repositoryLocation -ChildPath "..\artifacts")
    }
}

$null = New-Item -ItemType Directory -Force -Path $tempRepoPath
$tempRepoName = ([System.Guid]::NewGuid()).ToString()
$repo = Get-PSRepository | Where-Object { $_.SourceLocation -eq $tempRepoPath }
if ($repo -ne $null) {
    $tempRepoName = $repo.Name
} else {
    Register-PSRepository -Name $tempRepoName -SourceLocation $tempRepoPath -PublishLocation $tempRepoPath -InstallationPolicy Trusted -PackageManagementProvider NuGet
}

$env:PSModulePath = "$env:PSModulePath;$tempRepoPath"

$Errors = $null

try {
    $modules = Get-AllModules -BuildConfig $BuildConfig -Scope $Scope -PublishLocal:$PublishLocal -IsNetCore:$IsNetCore
    Add-AllModules -ModulePaths $modules -TempRepo $tempRepoName -TempRepoPath $tempRepoPath -NugetExe $NugetExe
    Publish-AllModules -ModulePaths $modules -ApiKey $apiKey -TempRepoPath $tempRepoPath -RepoLocation $repositoryLocation -NugetExe $NugetExe -PublishLocal:$PublishLocal
} catch {
    $Errors = $_
    Write-Error ($_ | Out-String)
} finally {
    Unregister-PSRepository -Name $tempRepoName
}

if ($Errors -ne $null) {
    exit 1
}
exit 0
