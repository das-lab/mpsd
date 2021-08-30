
function Write-IisVerbose
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        
        $SiteName,

        [string]
        $VirtualPath = '',

        [Parameter(Position=1)]
        [string]
        
        $Name,

        [Parameter(Position=2)]
        [string]
        $OldValue = '',

        [Parameter(Position=3)]
        [string]
        $NewValue = ''
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $VirtualPath )
    {
        $SiteName = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath
    }

    Write-Verbose -Message ('[IIS Website] [{0}] {1,-34} {2} -> {3}' -f $SiteName,$Name,$OldValue,$NewValue)
}

