
function Get-CIisWebsite
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [string]
        [Alias('SiteName')]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Name -and -not (Test-CIisWebsite -Name $Name) )
    {
        return $null
    }
    
    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $mgr.Sites | 
        Where-Object {
            if( $Name )
            {
                $_.Name -eq $Name
            }
            else
            {
                $true
            }
        } | Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

