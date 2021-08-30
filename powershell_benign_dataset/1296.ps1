
function Install-CMsmqMessageQueue
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Private,
        
        [Switch]
        
        $Transactional
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-CMsmqMessageQueuePath @queueArgs 
    
    $cmdletArgs = @{ }
    if( $PSBoundParameters.ContainsKey( 'WhatIf' ) )
    {
        $cmdletArgs.WhatIf = $true
    }
    
    $logMessage = "MSMQ message queue '$Name'."
    if( Test-CMsmqMessageQueue @queueArgs )
    {
        Write-Verbose "Re-creating $logMessage"
        Uninstall-CMsmqMessageQueue @queueArgs @cmdletArgs
    }
    else
    {
        Write-Verbose "Creating $logMessage"
    }
    
    $MaxWait = [TimeSpan]'0:00:10'
    $endAt = (Get-Date) + $MaxWait
    $created = $false
    if( $pscmdlet.ShouldProcess( $path, 'install MSMQ queue' ) )
    {
        
        do
        {
            try
            {
                
                $queue = [Messaging.MessageQueue]::Create( $path, $Transactional )
                $created = $true
                break
            }
            catch 
            { 
                if( $_.Exception.Message -like '*A workgroup installation computer does not support the operation.*' )
                {
                    Write-Error ("Can't create MSMSQ queues on this computer.  {0}" -f $_.Exception.Message)
                    return
                }
            }
            Start-Sleep -Milliseconds 100
        }
        while( -not $created -and (Get-Date) -lt $endAt )
        
        if( -not $created )
        {
            Write-Error ('Unable to create MSMQ queue {0}.' -f $path)
            return
        }
        
        $endAt = (Get-Date) + $MaxWait
        $exists = $false
        do
        {
            Start-Sleep -Milliseconds 100
            if( (Test-CMsmqMessageQueue @queueArgs) )
            {
                $exists = $true
                break
            }
        }
        while( (Get-Date) -lt $endAt -and -not $exists )
        
        if( -not $exists )
        {
            Write-Warning ('MSMSQ queue {0} created, but can''t be found.  Please double-check that the queue was created.' -f $path)
        }
    }
}

