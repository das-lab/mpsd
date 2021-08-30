






param (
    
    [string] $location = $env:BUILD_REPOSITORY_LOCALPATH,

    
    [Parameter(Mandatory, ParameterSetName = 'Build')]
    [string] $destination = '/mnt',

    [Parameter(Mandatory, ParameterSetName = 'Build')]
    [ValidatePattern("^v\d+\.\d+\.\d+(-\w+(\.\d+)?)?$")]
    [ValidateNotNullOrEmpty()]
    [string]$ReleaseTag,

    [Parameter(ParameterSetName = 'Build')]
    [ValidateSet("zip", "tar")]
    [string[]]$ExtraPackage,

    [Parameter(Mandatory, ParameterSetName = 'Bootstrap')]
    [switch] $BootStrap,

    [Parameter(Mandatory, ParameterSetName = 'Build')]
    [switch] $Build
)

$repoRoot = $location

if ($Build.IsPresent) {
    $releaseTagParam = @{}
    if ($ReleaseTag) {
        $releaseTagParam = @{ 'ReleaseTag' = $ReleaseTag }
    }
}

Push-Location
try {
    Write-Verbose -Message "Init..." -Verbose
    Set-Location $repoRoot
    Import-Module "$repoRoot/build.psm1"
    Import-Module "$repoRoot/tools/packaging"
    Sync-PSTags -AddRemoteIfMissing

    if ($BootStrap.IsPresent) {
        Start-PSBootstrap -Package
    }

    if ($Build.IsPresent) {
        Start-PSBuild -Configuration 'Release' -Crossgen -PSModuleRestore @releaseTagParam

        Start-PSPackage @releaseTagParam
        switch ($ExtraPackage) {
            "tar" { Start-PSPackage -Type tar @releaseTagParam }
        }
    }
} finally {
    Pop-Location
}

if ($Build.IsPresent) {
    $macPackages = Get-ChildItem "$repoRoot/powershell*" -Include *.pkg, *.tar.gz
    foreach ($macPackage in $macPackages) {
        $filePath = $macPackage.FullName
        $name = split-path -Leaf -Path $filePath
        $extension = (Split-Path -Extension -Path $filePath).Replace('.', '')
        Write-Verbose "Copying $filePath to $destination" -Verbose
        Write-Host "
        Write-Host "
        Copy-Item -Path $filePath -Destination $destination -force
    }
}
