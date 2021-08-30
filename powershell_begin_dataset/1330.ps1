
function Test-CMsmqMessageQueue
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Private
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-CMsmqMessageQueuePath @queueArgs 
    return ( [Messaging.MessageQueue]::Exists( $path ) )
}

