
function Uninstall-CJunction
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Path')]
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
            Remove-CJunction -Path $Path
            return
        }

        $LiteralPath = $Path
    }

    if( (Test-Path -LiteralPath $LiteralPath) )
    {
        Remove-CJunction -LiteralPath $LiteralPath
    }
}

