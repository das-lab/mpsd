
function Remove-CIisMimeMap
{
    
    [CmdletBinding(DefaultParameterSetName='ForWebServer')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForWebsite')]
        [string]
        
        $SiteName,

        [Parameter(ParameterSetName='ForWebsite')]
        [string]
        
        $VirtualPath = '',

        [Parameter(Mandatory=$true)]
        [string]
        
        $FileExtension
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getIisConfigSectionParams = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
    {
        $getIisConfigSectionParams['SiteName'] = $SiteName
        $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
    }
    
    $staticContent = Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams
    $mimeMapCollection = $staticContent.GetCollection()
    $mimeMapToRemove = $mimeMapCollection |
                            Where-Object { $_['fileExtension'] -eq $FileExtension }
    if( -not $mimeMapToRemove )
    {
        Write-Verbose ('MIME map for file extension {0} not found.' -f $FileExtension)
        return
    }
    
    $mimeMapCollection.Remove( $mimeMapToRemove )
    $staticContent.CommitChanges()
}

