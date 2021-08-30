
function Get-CDscWinEvent
{
    
    [CmdletBinding(DefaultParameterSetName='NoWait')]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [string[]]
        
        $ComputerName,

        [int]
        
        $ID,

        [int]
        
        $Level,

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

    $filter = @{ 
                    LogName = 'Microsoft-Windows-DSC/Operational'; 
              }

    if( $ID )
    {
        $filter['ID'] = $ID
    }

    if( $Level )
    {
        $filter['Level'] = $Level
    }

    if( $StartTime )
    {
        $filter['StartTime'] = $StartTime
    }

    if( $EndTime )
    {
        $filter['EndTime'] = $EndTime
    }

    function Invoke-GetWinEvent
    {
        param(
            [string]
            $ComputerName
        )

        Set-StrictMode -Version 'Latest'

        $startedAt = Get-Date
        $computerNameParam = @{ }
        if( $ComputerName )
        {
            $computerNameParam['ComputerName'] = $ComputerName
        }

        try
        {
            $events = @()
            while( -not ($events = Get-WinEvent @computerNameParam -FilterHashtable $filter -ErrorAction Ignore -Verbose:$false) )
            {
                if( $PSCmdlet.ParameterSetName -ne 'Wait' )
                {
                    break
                }

                Start-Sleep -Milliseconds 100

                [timespan]$duration = (Get-Date) - $startedAt
                if( $duration.TotalSeconds -gt $WaitTimeoutSeconds )
                {
                    break
                }
            }
            return $events
        }
        catch
        {
            if( $_.Exception.Message -eq 'The RPC server is unavailable' )
            {
                Write-Error -Message ("Unable to connect to '{0}': it looks like Remote Event Log Management isn't running or is blocked by the computer's firewall. To allow this traffic through the firewall, run the following command on '{0}':`n`tGet-FirewallRule -Name '*Remove Event Log Management*' |`n`t`t ForEach-Object {{ netsh advfirewall firewall set rule name= `$_.Name new enable=yes }}." -f $ComputerName)
            }
            else
            {
                Write-Error -Exception $_.Exception
            }
        }
    }

    if( $ComputerName )
    {
        $ComputerName = $ComputerName | 
                            Where-Object { 
                                
                                if( (Test-Connection -ComputerName $ComputerName -Quiet) )
                                {
                                    return $true
                                }
                                else
                                {
                                    Write-Error -Message ('Computer ''{0}'' not found.' -f $ComputerName)
                                    return $false
                                }
                            }

        if( -not $ComputerName )
        {
            return
        }

        $ComputerName | ForEach-Object { Invoke-GetWinEvent -ComputerName $_ }
    }
    else
    {
        Invoke-GetWinEvent
    }
}
