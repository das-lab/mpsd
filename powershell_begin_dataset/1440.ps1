











function Add-CIisDefaultDocument
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $FileName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/defaultDocument'
    if( -not $section )
    {
        return
    }

    [Microsoft.Web.Administration.ConfigurationElementCollection]$files = $section.GetCollection('files')
    $defaultDocElement = $files | Where-Object { $_["value"] -eq $FileName }
    if( -not $defaultDocElement )
    {
        Write-IisVerbose $SiteName 'Default Document' '' $FileName
        $defaultDocElement = $files.CreateElement('add')
        $defaultDocElement["value"] = $FileName
        $files.Add( $defaultDocElement )
        $section.CommitChanges() 
    }
}

