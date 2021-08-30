
function Get-CIisApplication
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Parameter()]
        [Alias('Name')]
        [string]
        
        $VirtualPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if( -not $site )
    {
        return
    }

    $site.Applications |
        Where-Object {
            if( $VirtualPath )
            {
                return ($_.Path -eq "/$VirtualPath")
            }
            return $true
        } | 
        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
}

