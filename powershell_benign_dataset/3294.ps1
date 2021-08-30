
function Start-PoshBot {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding(DefaultParameterSetName = 'bot')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'bot')]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'config')]
        [BotConfiguration]$Configuration,

        [parameter(Mandatory, ParameterSetName = 'path')]
        [string]$Path,

        [switch]$AsJob,

        [switch]$PassThru
    )

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'bot' {
                    $bot = $InputObject
                    $Configuration = $bot.Configuration
                }
                'config' {
                    $backend = New-PoshBotSlackBackend -Configuration $Configuration.BackendConfiguration
                    $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                }
                'path' {
                    $Configuration = Get-PoshBotConfiguration -Path $Path
                    $backend = New-PoshBotSlackBackend -Configuration $Configuration.BackendConfiguration
                    $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                }
            }

            if ($AsJob) {
                $sb = {
                    param(
                        [parameter(Mandatory)]
                        [hashtable]$Configuration,
                        [string]$PoshBotManifestPath
                    )

                    Import-Module $PoshBotManifestPath -ErrorAction Stop

                    try {
                        $tempConfig = New-PoshBotConfiguration
                        $realConfig = $tempConfig.Serialize($Configuration)

                        while ($true) {
                            try {
                                if ($realConfig.BackendConfiguration.Name -in @('Slack', 'SlackBackend')) {
                                    $backend = New-PoshBotSlackBackend -Configuration $realConfig.BackendConfiguration
                                } elseIf ($realConfig.BackendConfiguration.Name -in @('Teams', 'TeamsBackend')) {
                                    $backend = New-PoshBotTeamsBackend -Configuration $realConfig.BackendConfiguration
                                } else {
                                    Write-Error "Unable to determine backend type. Name property in BackendConfiguration should have a value of 'Slack', 'SlackBackend', 'Teams', or 'TeamsBackend'"
                                    break
                                }

                                $bot = New-PoshBotInstance -Backend $backend -Configuration $realConfig
                                $bot.Start()
                            } catch {
                                Write-Error $_
                                Write-Error 'PoshBot crashed :( Restarting...'
                                Start-Sleep -Seconds 5
                            }
                        }
                    } catch {
                        throw $_
                    }
                }

                $instanceId = (New-Guid).ToString().Replace('-', '')
                $jobName = "PoshBot_$instanceId"
                $poshBotManifestPath = (Join-Path -Path $PSScriptRoot -ChildPath "PoshBot.psd1")

                $job = Start-Job -ScriptBlock $sb -Name $jobName -ArgumentList $Configuration.ToHash(),$poshBotManifestPath

                
                $botTracker = @{
                    JobId = $job.Id
                    Name = $jobName
                    InstanceId = $instanceId
                    Config = $Configuration
                }
                $script:botTracker.Add($job.Id, $botTracker)

                if ($PSBoundParameters.ContainsKey('PassThru')) {
                    Get-PoshBot -Id $job.Id
                }
            } else {
                $bot.Start()
            }
        } catch {
            throw $_
        }
        finally {
            if (-not $AsJob) {
                
                
                if ($bot) {
                    Write-Verbose -Message 'Stopping PoshBot'
                    $bot.Disconnect()
                }
            }
        }
    }
}

Export-ModuleMember -Function 'Start-Poshbot'
