












param(
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Debug', 'Release')]
    [System.String]$BuildConfig
)

$ProjectPaths = @( "$PSScriptRoot\..\artifacts\$BuildConfig" )
$DependencyMapPath = "$PSScriptRoot\..\artifacts\StaticAnalysisResults\DependencyMap.csv"

$DependencyMap = Import-Csv -Path $DependencyMapPath

$ModuleManifestFiles = $ProjectPaths | ForEach-Object { Get-ChildItem -Path $_ -Filter "*.psd1" -Recurse | Where-Object { $_.FullName -like "*$($BuildConfig)*" -and `
            $_.FullName -notlike "*Netcore*" -and `
            $_.FullName -notlike "*dll-Help.psd1*" -and `
            $_.FullName -notlike "*Stack*" } }

foreach ($ModuleManifest in $ModuleManifestFiles) {
    Write-Host "checking $($ModuleManifest.Fullname)"
    $ModuleName = $ModuleManifest.Name.Replace(".psd1", "")
    $Assemblies = $DependencyMap | Where-Object { $_.Directory.EndsWith($ModuleName) }
    Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $ModuleManifest.DirectoryName -FileName $ModuleManifest.Name

    $LoadedAssemblies = @()
    if ($ModuleMetadata.RequiredAssemblies.Count -gt 0) {
        $LoadedAssemblies += $ModuleMetadata.RequiredAssemblies
    }

    $LoadedAssemblies += $ModuleMetadata.NestedModules

    if ($ModuleMetadata.RequiredModules) {
        $RequiredModules = $ModuleMetadata.RequiredModules | ForEach-Object { $_["ModuleName"] }
        foreach ($RequiredModule in $RequiredModules) {
            Write-Output ("ModuleManifest: " + $RequiredModuleManifest)
            Write-Output ("Required Module: " + $RequiredModule)

            $RequiredModuleManifest = $ModuleManifestFiles | Where-Object { $_.Name.Replace(".psd1", "") -eq $RequiredModule } | Select-Object -First 1
            if (-not $RequiredModuleManifest) {
                continue
            }

            $RequiredModuleManifest | ForEach-Object {
                Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $_.DirectoryName -FileName $_.Name
                if ($ModuleMetadata.RequiredAssemblies.Count -gt 0) {
                    $LoadedAssemblies += $ModuleMetadata.RequiredAssemblies
                }
                $LoadedAssemblies += $ModuleMetadata.NestedModules
            }
        }
    }

    $LoadedAssemblies = $LoadedAssemblies | ForEach-Object { $_.Substring(2).Replace(".dll", "") }

    $Found = @()
    foreach ($Assembly in $Assemblies) {
        if ($Found -notcontains $Assembly.AssemblyName -and $LoadedAssemblies -notcontains $Assembly.AssemblyName -and $Assembly.AssemblyName -notlike "System.Management.Automation*") {
            $Found += $Assembly.AssemblyName
            Write-Error "ERROR: Assembly $($Assembly.AssemblyName) was not included in the required assemblies field for module $ModuleName"
        }
    }

    if ($Found.Count -gt 0) {
        throw
    }
}
