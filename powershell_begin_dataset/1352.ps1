
function Grant-CMsmqMessageQueuePermission
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Private,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Username,
        
        [Parameter(Mandatory=$true)]
        [Messaging.MessageQueueAccessRights[]]
        
        $AccessRights
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $queue = Get-CMsmqMessageQueue @queueArgs
    if( -not $queue )
    {
        Write-Error "MSMQ queue '$Name' not found."
        return
    }
    
    if( $PSCmdlet.ShouldProcess( ('MSMQ queue ''{0}''' -f $Name), ("granting '{0}' rights to '{1}'" -f $AccessRights,$Username) ) )
    {
        $queue.SetPermissions( $Username, $AccessRights )
    }
}

Set-Alias -Name 'Grant-MsmqMessageQueuePermissions' -Value 'Grant-CMsmqMessageQueuePermission'

