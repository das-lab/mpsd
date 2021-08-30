
function Test-CIisWebsite
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
    try
    {
        $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
        if( $site )
        {
            return $true
        }
        return $false
    }
    finally
    {
        $manager.Dispose()
    }
}

Set-Alias -Name Test-IisWebsiteExists -Value Test-CIisWebsite

