
function Uninstall-CDirectory
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,

        [Switch]
        
        $Recurse
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-Path -Path $Path -PathType Container) )
    {
        Remove-Item -Path $Path -Recurse:$Recurse
    }
}
