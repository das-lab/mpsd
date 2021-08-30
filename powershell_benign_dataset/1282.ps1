
function Uninstall-CIisAppPool
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name
    if( $appPool )
    {
        if( $pscmdlet.ShouldProcess( ('IIS app pool {0}' -f $Name), 'remove' ) )
        {
            $appPool.Delete()
            $appPool.CommitChanges()
        }
    }
}

