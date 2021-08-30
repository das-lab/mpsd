
function Invoke-ConsoleCommand
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Target,

        [Parameter(Mandatory=$true)]
        [string]
        
        $Action,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        
        $ScriptBlock
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $PSCmdlet.ShouldProcess( $Target, $Action ) )
    {
        return
    }

    $output = Invoke-Command -ScriptBlock $ScriptBlock
    if( $LASTEXITCODE )
    {
        $output = $output -join [Environment]::NewLine
        Write-Error ('Failed action ''{0}'' on target ''{1}'' (exit code {2}): {3}' -f $Action,$Target,$LASTEXITCODE,$output)
    }
    else
    {
        $output | Where-Object { $_ -ne $null } | Write-Verbose
    }
}
