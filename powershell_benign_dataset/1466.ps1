
function Set-ReleaseNotesReleaseDate
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ReleaseNotesPath
    )

    Set-StrictMode -Version 'Latest'

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $setHeader = $false
    $releaseNotes = Get-Content -Path $ReleaseNotesPath |
                        ForEach-Object {
                            if( $_ -match '^
                            {
                                $setHeader = $true
                                return "
                            }
                            return $_
                        }
    if( $setHeader )
    {
        $releaseNotes | Set-Content -Path $releaseNotesPath
    }
}
