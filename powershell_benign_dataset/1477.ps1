
function Set-ModuleNuspec
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $NuspecPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ReleaseNotesPath,

        [string[]]
        
        $Tags
    )

    Set-StrictMode -Version 'Latest'

    $NuspecPath = Resolve-Path -Path $NuspecPath
    if( -not $NuspecPath )
    {
        return
    }

    $nuspec = [xml](Get-Content -Path $NuspecPath -Raw)
    if( -not $nuspec )
    {
        return
    }

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $releaseNotes = Get-ModuleReleaseNotes -ManifestPath $ManifestPath -ReleaseNotesPath $ReleaseNotesPath
    if( -not $releaseNotes )
    {
        return
    }

    $nuspecMetadata = $nuspec.package.metadata

    $nuspecMetadata.description = $manifest.Description
    $nuspecMetadata.version = $manifest.Version.ToString()
    $nuspecMetadata.copyright = $manifest.Copyright
    $nuspecMetadata.releaseNotes = $releaseNotes
    if( $Tags )
    {
        $nuspecMetadata.tags = $Tags -join ' '
    }

    $nuspec.Save( $NuspecPath )
}