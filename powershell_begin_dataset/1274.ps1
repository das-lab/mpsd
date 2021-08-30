
function Get-CIisMimeMap
{
    
    [CmdletBinding(DefaultParameterSetName='ForWebServer')]
    [OutputType([Carbon.Iis.MimeMap])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForWebsite')]
        [string]
        
        $SiteName,
        
        [Parameter(ParameterSetName='ForWebsite')]
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [string]
        
        $FileExtension = '*',
        
        [string]
        
        $MimeType = '*'
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
    $staticContent.GetCollection() | 
        Where-Object { $_['fileExtension'] -like $FileExtension -and $_['mimeType'] -like $MimeType } |
        ForEach-Object {
            New-Object 'Carbon.Iis.MimeMap' ($_['fileExtension'],$_['mimeType'])
        }
}

