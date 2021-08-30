
function Join-CIisVirtualPath
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        
        $Path,

        [Parameter(Position=1)]
        [string]
        $ChildPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $ChildPath )
    {
        $Path = Join-Path -Path $Path -ChildPath $ChildPath
    }
    $Path.Replace('\', '/').Trim('/')
}

