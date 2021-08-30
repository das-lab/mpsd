
function Get-CPathProvider
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
    if( -not $pathQualifier )
    {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
        $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
        if( -not $pathQualifier )
        {
            Write-Error "Qualifier for path '$Path' not found."
            return
        }
    }

    $pathQualifier = $pathQualifier.Trim(':')
    $drive = Get-PSDrive -Name $pathQualifier -ErrorAction Ignore
    if( -not $drive )
    {
        $drive = Get-PSDrive -PSProvider $pathQualifier -ErrorAction Ignore
    }

    if( -not $drive )
    {
        Write-Error -Message ('Unable to determine the provider for path {0}.' -f $Path)
        return
    }

    $drive  |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'Provider'

}
