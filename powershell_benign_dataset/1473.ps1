
function Get-ModuleReleaseNotes
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ReleaseNotesPath
    )

    Set-StrictMode -Version 'Latest'

    $Version = Test-ModuleManifest -Path $ManifestPath | Select-Object -ExpandProperty 'Version'
    if( -not $Version )
    {
        Write-Error -Message ('Version not found in module manifest ''{0}''.' -f $ManifestPath)
        return
    }

    $foundVersion = $false
    $versionReleaseNotes = Get-Content -Path $ReleaseNotesPath |
                            Where-Object {
                                $line = $_
                                if( -not $foundVersion )
                                {
                                    if( $line -match ('^
                                    {
                                        $foundVersion = $true
                                        return
                                    }
                                }
                                else
                                {
                                    if( $line -match ('^
                                    {
                                        $foundVersion = $false
                                    }
                                }
                                return( $foundVersion )
                            }
    if( -not $versionReleaseNotes )
    {
        Write-Error -Message ('There are no release notes for version {0} in ''{1}''.' -f $Version,$ReleaseNotesPath)
        return
    }

    $versionReleaseNotes -join [Environment]::NewLine

}