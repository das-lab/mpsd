
function Test-CScheduledTask
{
    
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Name = Join-Path -Path '\' -ChildPath $Name

    $task = Get-CScheduledTask -Name $Name -AsComObject -ErrorAction Ignore
    if( $task )
    {
        return $true
    }
    else
    {
        return $false
    }
}
