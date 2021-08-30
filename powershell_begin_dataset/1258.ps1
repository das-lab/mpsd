
function Uninstall-CIisWebsite
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( Test-CIisWebsite -Name $Name )
    {
        $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
        try
        {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            $manager.Sites.Remove( $site )
            $manager.CommitChanges()
        }
        finally
        {
            $manager.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-IisWebsite' -Value 'Uninstall-CIisWebsite'

