Function Import-XMLConfig
{

    [CmdletBinding()]
    Param
    (
        
        [Parameter(Mandatory = $true)]
        $ConfigPath
    )

    [hashtable]$Config = @{ }

    
    $xmlfile = [xml]([System.IO.File]::ReadAllText($configPath))

    
    $Config.CarbonServer = $xmlfile.Configuration.Graphite.CarbonServer
    $Config.CarbonServerPort = $xmlfile.Configuration.Graphite.CarbonServerPort

    
    $Config.NodeHostName = $xmlfile.Configuration.Graphite.NodeHostName
    
    
    if($Config.NodeHostName -eq '$env:COMPUTERNAME')
    {
        $Config.NodeHostName = $env:COMPUTERNAME
    }

    
    [int]$Config.MetricSendIntervalSeconds = $xmlfile.Configuration.Graphite.MetricSendIntervalSeconds

    
    [bool]$Config.SendUsingUDP = [System.Convert]::ToBoolean($xmlfile.Configuration.Graphite.SendUsingUDP)

    
    $Config.MetricTimeSpan = [timespan]::FromSeconds($Config.MetricSendIntervalSeconds)

    

    $Config.MetricPath = $xmlfile.Configuration.Graphite.MetricPath

    
    [bool]$Config.ShowOutput = [System.Convert]::ToBoolean($xmlfile.Configuration.Logging.VerboseOutput)

    
    $Config.Counters = @()

    
    foreach ($counter in $xmlfile.Configuration.PerformanceCounters.Counter)
    {
        $Config.Counters += $counter.Name
    }

    
    $Config.MetricReplace = New-Object System.Collections.Specialized.OrderedDictionary

    
    ForEach ($metricreplace in $xmlfile.Configuration.MetricCleaning.MetricReplace)
    {
        
        $Config.MetricReplace.Add($metricreplace.This,$metricreplace.With)
    }

    $Config.Filters = [string]::Empty;
    
    foreach ($MetricFilter in $xmlfile.Configuration.Filtering.MetricFilter)
    {
        $Config.Filters += $MetricFilter.Name + '|'
    }

    if($Config.Filters.Length -gt 0) {
        
        $Config.Filters = $Config.Filters.Trim()

        
        $Config.Filters = $Config.Filters.TrimEnd("|")
    }
    else
    {
        $Config.Filters = $null
    }

    
    try
    {
        
        $Config.MSSQLMetricPath = $xmlfile.Configuration.MSSQLMetics.MetricPath
        [int]$Config.MSSQLMetricSendIntervalSeconds = $xmlfile.Configuration.MSSQLMetics.MetricSendIntervalSeconds
        $Config.MSSQLMetricTimeSpan = [timespan]::FromSeconds($Config.MSSQLMetricSendIntervalSeconds)
        [int]$Config.MSSQLConnectTimeout = $xmlfile.Configuration.MSSQLMetics.SQLConnectionTimeoutSeconds
        [int]$Config.MSSQLQueryTimeout = $xmlfile.Configuration.MSSQLMetics.SQLQueryTimeoutSeconds

        
        $Config.MSSQLServers = @()     
     
        foreach ($sqlServer in $xmlfile.Configuration.MSSQLMetics)
        {
            
            $Config.MSSQLServers += [pscustomobject]@{
                ServerInstance = $sqlServer.ServerInstance;
                Username = $sqlServer.Username;
                Password = $sqlServer.Password;
                Queries = $sqlServer.Query
            }
        }
    }
    catch
    {
        Write-Verbose "SQL configuration has been left out, skipping."
    }

    Return $Config
}


function PSUsing
{
    param (
        [System.IDisposable] $inputObject = $(throw "The parameter -inputObject is required."),
        [ScriptBlock] $scriptBlock = $(throw "The parameter -scriptBlock is required.")
    )

    Try
    {
        &$scriptBlock
    }
    Finally
    {
        if ($inputObject -ne $null)
        {
            if ($inputObject.psbase -eq $null)
            {
                $inputObject.Dispose()
            }
            else
            {
                $inputObject.psbase.Dispose()
            }
        }
    }
}

function SendMetrics
{
    param (
        [string]$CarbonServer,
        [int]$CarbonServerPort,
        [string[]]$Metrics,
        [switch]$IsUdp = $false,
        [switch]$TestMode = $false
    )

    if (!($TestMode))
    {
        try
        {
            if ($isUdp)
            {
                PSUsing ($udpobject = new-Object system.Net.Sockets.Udpclient($CarbonServer, $CarbonServerPort)) -ScriptBlock {
                    $enc = new-object system.text.asciiencoding
                    foreach ($metricString in $Metrics)
                    {
                        $Message += "$($metricString)`n"
                    }
                    $byte = $enc.GetBytes($Message)

                    Write-Verbose "Byte Length: $($byte.Length)"
                    $Sent = $udpobject.Send($byte,$byte.Length)
                }

                Write-Verbose "Sent via UDP to $($CarbonServer) on port $($CarbonServerPort)."
            }
            else
            {
                PSUsing ($socket = New-Object System.Net.Sockets.TCPClient) -ScriptBlock {
                    $socket.connect($CarbonServer, $CarbonServerPort)
                    PSUsing ($stream = $socket.GetStream()) {
                        PSUSing($writer = new-object System.IO.StreamWriter($stream)) {
                            foreach ($metricString in $Metrics)
                            {
                                $writer.WriteLine($metricString)
                            }
                            $writer.Flush()
                            Write-Verbose "Sent via TCP to $($CarbonServer) on port $($CarbonServerPort)."
                        }
                    }
                }
            }
        }
        catch
        {
            $exceptionText = GetPrettyProblem $_
            Write-Error "Error sending metrics to the Graphite Server. Please check your configuration file. `n$exceptionText"
        }
    }
}

function GetPrettyProblem {
    param (
        $Problem
    )

    $prettyString = (Out-String -InputObject (format-list -inputobject $Problem -Property * -force)).Trim()
    return $prettyString
}