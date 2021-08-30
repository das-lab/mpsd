
function Test-CUser
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        
        $Username
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $user = Get-CUser -UserName $Username -ErrorAction Ignore
    if( $user )
    {
        $user.Dispose()
        return $true
    }
    else
    {
        return $false
    }
}
