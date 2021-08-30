
function Uninstall-CGroup
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        
        $Name
    )

	Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CGroup -Name $Name) )
    {
        return
    }

    $group = Get-CGroup -Name $Name
    if( -not $group )
    {
        return
    }

    if( $PSCmdlet.ShouldProcess(('local group {0}' -f $Name), 'remove') )
    {
        Write-Verbose -Message ('[{0}]              -' -f $Name)
        $group.Delete()
    }

}
