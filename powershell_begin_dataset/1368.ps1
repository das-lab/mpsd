
function Test-CNtfsCompression
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path {0} not found.' -f $Path)
        return
    }

    $attributes = Get-Item -Path $Path -Force | Select-Object -ExpandProperty Attributes
    if( $attributes )
    {
        return (($attributes -band [IO.FileAttributes]::Compressed) -eq [IO.FileAttributes]::Compressed)
    }
    return $false
}
