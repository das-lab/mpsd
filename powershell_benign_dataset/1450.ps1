
function Install-CPerformanceCounter
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='SimpleCounter')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        
        $Description,
        
        [Parameter(Mandatory=$true)]
        [Diagnostics.PerformanceCounterType]
        
        $Type,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [string]
        
        $BaseName,
        
        [Parameter(ParameterSetName='WithBaseCounter')]
        [string]
        
        $BaseDescription,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithBaseCounter')]
        [Diagnostics.PerformanceCounterType]
        
        $BaseType,
        
        [Switch]
        
        $Force
    )
    
    Set-StrictMode -Version Latest
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $currentCounters = @( Get-CPerformanceCounter -CategoryName $CategoryName )
    
    $counter = $currentCounters | 
                    Where-Object { 
                        $_.CounterName -eq $Name -and `
                        $_.CounterHelp -eq $Description -and `
                        $_.CounterType -eq $Type
                    }
            
    if( $counter -and -not $Force)
    {
        return
    }
    
    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $baseCounter = $currentCounters | 
                        Where-Object { 
                            $_.CounterName -eq $BaseName -and `
                            $_.CounterHelp -eq $BaseDescription -and `
                            $_.CounterType -eq $BaseType
                        }
                        
        if( $baseCounter -and -not $Force)
        {
            return
        }
    }
    else
    {
        $BaseName = $null
    }
        
    $counters = New-Object Diagnostics.CounterCreationDataCollection 
    $currentCounters  | 
        Where-Object { $_.CounterName -ne $Name -and $_.CounterName -ne $BaseName } |
        ForEach-Object {
            $creationData = New-Object Diagnostics.CounterCreationData $_.CounterName,$_.CounterHelp,$_.CounterType
            [void] $counters.Add( $creationData )
        }
    
    $newCounterData = New-Object Diagnostics.CounterCreationData $Name,$Description,$Type
    [void] $counters.Add( $newCounterData )
    
    $baseMsg = ''
    if( $PSCmdlet.ParameterSetName -eq 'WithBaseCounter' )
    {
        $newBaseCounterData = New-Object Diagnostics.CounterCreationData $BaseName,$BaseDescription,$BaseType
        [void] $counters.Add( $newBaseCounterData )
        $baseMsg = ' with base counter ''{0}'' ({1})' -f $BaseName,$BaseType
    }
    
    $msg = "Installing '{0}' performance counter '{1}' ({2}){3}." -f $CategoryName,$Name,$Type,$baseMsg
    
    if( $pscmdlet.ShouldProcess( $CategoryName, "install performance counter '$Name'" ) )
    {
        Uninstall-CPerformanceCounterCategory -CategoryName $CategoryName

        [void] [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', $counters )
    }
}

