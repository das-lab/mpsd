
function Resolve-CFullPath
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not ( [System.IO.Path]::IsPathRooted($Path) ) )
    {
        $Path = Join-Path (Get-Location) $Path
    }
    return [IO.Path]::GetFullPath($Path)
}

Set-Alias -Name 'ConvertTo-FullPath' -Value 'Resolve-CFullPath'

