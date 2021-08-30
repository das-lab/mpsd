Function Start-StatsToGraphite
{

    [CmdletBinding()]
    Param
    (
        
        [Parameter(Mandatory = $false)]
        [switch]$TestMode,
        [switch]$ExcludePerfCounters = $false,
        [switch]$SqlMetrics = $false
    )

    
    $Config = Import-XMLConfig -ConfigPath $configPath

    
    $sleep = 0

    $configFileLastWrite = (Get-Item -Path $configPath).LastWriteTime

    if($ExcludePerfCounters -and -not $SqlMetrics) {
        throw "Parameter combination provided will prevent any metrics from being collected"
    }

    if($SqlMetrics) {
        if ($Config.MSSQLServers.Length -gt 0)
        {
            
            if (($listofSQLModules = Get-Module -List SQLPS).Length -eq 1)
            {
                
                Import-Module SQLPS -DisableNameChecking
            }
            
            elseif ((Test-Path ($env:ProgramFiles + '\Microsoft SQL Server\100\Tools\Binn\Microsoft.SqlServer.Management.PSProvider.dll')) `
                -or (Test-Path ($env:ProgramFiles + ' (x86)' + '\Microsoft SQL Server\100\Tools\Binn\Microsoft.SqlServer.Management.PSProvider.dll')))
            {
                
                Add-PSSnapin SqlServerCmdletSnapin100
                Add-PSSnapin SqlServerProviderSnapin100
            }
            
            else
            {
                throw "Unable to find any SQL CmdLets. Please install them and try again."
            }
        }
        else
        {
            Write-Warning "There are no SQL Servers in your configuration file. No SQL metrics will be collected."
        }
    }

    
    while ($true)
    {
        
        if($sleep -gt 0) {
            Start-Sleep -Milliseconds $sleep
        }

        
        $iterationStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

        $nowUtc = [datetime]::UtcNow

        
        $nowUtc = $nowUtc.AddSeconds(- ($nowUtc.Second % $Config.MetricSendIntervalSeconds))

        $metricsToSend = @{}

        if(-not $ExcludePerfCounters)
        {
            
            $collections = Get-Counter -Counter $Config.Counters -SampleInterval 1 -MaxSamples 1

            
            $samples = $collections.CounterSamples

            
            Write-Verbose "All Samples Collected"

            
            foreach ($sample in $samples)
            {
                if ($Config.ShowOutput)
                {
                    Write-Verbose "Sample Name: $($sample.Path)"
                }

                
                $filterStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

                
                if ([string]::IsNullOrWhiteSpace($Config.Filters) -or $sample.Path -notmatch [regex]$Config.Filters)
                {
                    
                    $cleanNameOfSample = ConvertTo-GraphiteMetric -MetricToClean $sample.Path -HostName $Config.NodeHostName -MetricReplacementHash $Config.MetricReplace

                    
                    $metricPath = $Config.MetricPath + '.' + $cleanNameOfSample

                    $metricsToSend[$metricPath] = $sample.Cookedvalue
                }
                else
                {
                    Write-Verbose "Filtering out Sample Name: $($sample.Path) as it matches something in the filters."
                }

                $filterStopWatch.Stop()

                Write-Verbose "Job Execution Time To Get to Clean Metrics: $($filterStopWatch.Elapsed.TotalSeconds) seconds."

            }
        }

        if($SqlMetrics) {
            
            foreach ($sqlServer in $Config.MSSQLServers)
            {
                Write-Verbose "Running through SQLServer $($sqlServer.ServerInstance)"
                
                foreach ($query in $sqlServer.Queries)
                {
                    Write-Verbose "Current Query $($query.TSQL)"

                    $sqlCmdParams = @{
                        'ServerInstance' = $sqlServer.ServerInstance;
                        'Database' = $query.Database;
                        'Query' = $query.TSQL;
                        'ConnectionTimeout' = $Config.MSSQLConnectTimeout;
                        'QueryTimeout' = $Config.MSSQLQueryTimeout
                    }

                    
                    if (-not [string]::IsNullOrWhitespace($sqlServer.Username) `
                        -and -not [string]::IsNullOrWhitespace($sqlServer.Password))
                    {
                        $sqlCmdParams['Username'] = $sqlServer.Username
                        $sqlCmdParams['Password'] = $sqlServer.Password
                    }

                    
                    try
                    {
                        $commandMeasurement = Measure-Command -Expression {
                            $sqlresult = Invoke-SQLCmd @sqlCmdParams

                            
                            $metricPath = $Config.MSSQLMetricPath + '.' + $query.MetricName

                            $metricsToSend[$metricPath] = $sqlresult[0]
                        }

                        Write-Verbose ('SQL Metric Collection Execution Time: ' + $commandMeasurement.TotalSeconds + ' seconds')
                    }
                    catch
                    {
                        $exceptionText = GetPrettyProblem $_
                        throw "An error occurred with processing the SQL Query. $exceptionText"
                    }
                } 
            } 
        }

        

        $sendBulkGraphiteMetricsParams = @{
            "CarbonServer" = $Config.CarbonServer
            "CarbonServerPort" = $Config.CarbonServerPort
            "Metrics" = $metricsToSend
            "DateTime" = $nowUtc
            "UDP" = $Config.SendUsingUDP
            "Verbose" = $Config.ShowOutput
            "TestMode" = $TestMode
        }

        Send-BulkGraphiteMetrics @sendBulkGraphiteMetricsParams

        
        if((Get-Item $configPath).LastWriteTime -gt (Get-Date -Date $configFileLastWrite)) {
            $Config = Import-XMLConfig -ConfigPath $configPath
        }

        $iterationStopWatch.Stop()
        $collectionTime = $iterationStopWatch.Elapsed
        $sleep = $Config.MetricTimeSpan.TotalMilliseconds - $collectionTime.TotalMilliseconds
        if ($Config.ShowOutput)
        {
            
            $VerboseOutPut = 'PerfMon Job Execution Time: ' + $collectionTime.TotalSeconds + ' seconds'
            Write-Output $VerboseOutPut
        }
    }
}