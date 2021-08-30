
function Get-CDscError
{
    
    [CmdletBinding(DefaultParameterSetName='NoWait')]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [string[]]
        
        $ComputerName,

        [DateTime]
        
        $StartTime,

        [DateTime]
        
        $EndTime,

        [Parameter(Mandatory=$true,ParameterSetName='Wait')]
        [Switch]
        
        $Wait,

        [Parameter(ParameterSetName='Wait')]
        [uint32]
        
        $WaitTimeoutSeconds = 10
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CDscWinEvent @PSBoundParameters -ID 4103 -Level ([Diagnostics.Eventing.Reader.StandardEventLevel]::Error)
}
