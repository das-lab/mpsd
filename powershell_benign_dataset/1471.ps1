
function Set-ModuleVersion
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [string]
        
        $SolutionPath,

        [string]
        
        $AssemblyInfoPath,

        [string]
        
        $ReleaseNotesPath,

        [string]
        
        $NuspecPath,

        [Version]
        
        $Version,

        [string]
        
        $PreReleaseVersion,

        [string]
        
        $BuildMetadata
    )

    Set-StrictMode -Version 'Latest'

    if( -not $Version )
    {
        $Version = Test-ModuleManifest -Path $ManifestPath | Select-Object -ExpandProperty 'Version'
        if( -not $Version )
        {
            return
        }
    }

    if( $Version.Build -lt 0 )
    {
        Write-Error ('Version number must have a build number, i.e. it must have three parts.' -f $Version)
        return
    }

    if( $Version.Revision -ge 0 )
    {
        Write-Error ('Version number must not have a revision number, i.e. it must only have three parts.' -f $Version)
        return
    }

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $moduleVersionRegex = 'ModuleVersion\s*=\s*(''|")([^''"])+(''|")' 
    $rawManifest = Get-Content -Raw -Path $manifestPath
    if( $rawManifest -notmatch ('ModuleVersion\s*=\s*(''|"){0}(''|")' -f [regex]::Escape($version.ToString())) )
    {
        $rawManifest = $rawManifest -replace $moduleVersionRegex,('ModuleVersion = ''{0}''' -f $version)
        $rawManifest | Set-Content -Path $manifestPath -NoNewline
    }

    if( $AssemblyInfoPath )
    {
        $assemblyVersionRegex = 'Assembly(File|Informational)?Version\("[^"]*"\)'
        $assemblyVersion = Get-Content -Path $AssemblyInfoPath |
                                ForEach-Object {
                                    if( $_ -match $assemblyVersionRegex )
                                    {
                                        $infoVersion = ''
                                        if( $Matches[1] -eq 'Informational' )
                                        {
                                            if( $PreReleaseVersion )
                                            {
                                                $infoVersion = '-{0}' -f $PreReleaseVersion
                                            }
                                            if( $BuildMetadata )
                                            {
                                                $infoVersion = '{0}+{1}' -f $infoVersion,$BuildMetadata
                                            }
                                        }
                                        return $_ -replace $assemblyVersionRegex,('Assembly$1Version("{0}{1}")' -f $Version,$infoVersion)
                                    }
                                    elseif( $_ -match 'AssemblyCopyright' )
                                    {
                                        return $_ -replace '\("[^"]*"\)',('("{0}")' -f $manifest.Copyright)
                                    }
                                    $_
                                }
        $assemblyVersion | Set-Content -Path $AssemblyInfoPath
    }

    if( $ReleaseNotesPath )
    {
        $newVersionHeader = "
        $updatedVersion = $false
        $releaseNotes = Get-Content -Path $releaseNotesPath |
                            ForEach-Object {
                                if( -not $updatedVersion -and $_ -match '^
                                {
                                    $updatedVersion = $true
                                    return $newVersionHeader
                                }

                                return $_
                            }
        $releaseNotes | Set-Content -Path $releaseNotesPath
    }

    if( $SolutionPath )
    {
        $msbuildRoot = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0 -Name 'MSBuildToolsPath' | Select-Object -ExpandProperty 'MSBuildToolsPath'
        $msbuildExe = Join-Path -Path $msbuildRoot -ChildPath 'MSBuild.exe' -Resolve
        if( -not $msbuildExe )
        {
            return
        }

        & $msbuildExe /target:"clean;build" $SolutionPath /v:m /nologo
    }

    if( $NuspecPath )
    {
        $nuspec = [xml](Get-Content -Raw -Path $nuspecPath)
        if( $nuspec.package.metadata.version -ne $version.ToString() )
        {
            $nuGetVersion = $version -replace '-([A-Z0-9]+)[^A-Z0-9]*(\d+)$','-$1$2'
            $nuspec.package.metadata.version = $nugetVersion
            $nuspec.Save( $nuspecPath )
        }
    }
}