
function Set-CIisMimeMap
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ForWebServer')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForWebsite')]
        [string]
        
        $SiteName,

        [Parameter(ParameterSetName='ForWebsite')]
        [string]
        
        $VirtualPath = '',

        [Parameter(Mandatory=$true)]
        [string]
        
        $FileExtension,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $MimeType
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
    
    $mimeMap = $mimeMapCollection | Where-Object { $_['fileExtension'] -eq $FileExtension }
    
    if( $mimeMap )
    {
        $action = 'setting'
        $mimeMap['fileExtension'] = $FileExtension
        $mimeMap['mimeType'] = $MimeType
    }
    else
    {
        $action = 'adding'
        $mimeMap = $mimeMapCollection.CreateElement("mimeMap");
        $mimeMap["fileExtension"] = $FileExtension
        $mimeMap["mimeType"] = $MimeType
        [void] $mimeMapCollection.Add($mimeMap)
    }
     
    if( $PSCmdlet.ShouldProcess( 'IIS web server', ('{0} MIME map {1} -> {2}' -f $action,$FileExtension,$MimeType) ) )
    {
        $staticContent.CommitChanges()
    }
}

