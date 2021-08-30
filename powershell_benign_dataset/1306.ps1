
function Test-CPathIsJunction
{
    
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Path',Position=0)]
        [string]
        
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        
        
        
        $LiteralPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'Path' )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Path) )
        {
            $junctions = Get-Item -Path $Path -Force |
                            Where-Object { $_.PsIsContainer -and $_.IsJunction }
            
            return ($junctions -ne $null)        
        }

        return Test-CPathIsJunction -LiteralPath $Path
    }

    if( Test-Path -LiteralPath $LiteralPath -PathType Container )
    {
        return (Get-Item -LiteralPath $LiteralPath -Force).IsJunction
    }

    return $false
}

