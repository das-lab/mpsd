
function Write-CDscError
{
    
    [CmdletBinding()]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Diagnostics.Eventing.Reader.EventLogRecord[]]
        
        $EventLogRecord,

        [Switch]
        
        $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        foreach( $record in $EventLogRecord )
        {
            [string[]]$property = $record.Properties | Select-Object -ExpandProperty Value

            $message = $property[-1]

            Write-Error -Message ('[{0}] [{1}] [{2}] {3}' -f $record.TimeCreated,$record.MachineName,($property[0..($property.Count - 2)] -join '] ['),$message)

            if( $PassThru )
            {
                return $record
            }
        }
    }
}
