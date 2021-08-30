
function Remove-CRegistryKeyValue
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CRegistryKeyValue -Path $Path -Name $Name) )
    {
        if( $pscmdlet.ShouldProcess( ('Item: {0} Property: {1}' -f $Path,$Name), 'Remove Property' ) )
        {
            Remove-ItemProperty -Path $Path -Name $Name
        }
    }
}

