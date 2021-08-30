
function Uninstall-CMsmqMessageQueue
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Private
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-CMsmqMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-CMsmqMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-CMsmqMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

Set-Alias -Name 'Remove-MsmqMessageQueue' -Value 'Uninstall-CMsmqMessageQueue'

