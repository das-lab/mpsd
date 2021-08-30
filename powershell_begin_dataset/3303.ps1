
function Get-PoshBotConfiguration {
    
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath
    )

    process {
        
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        foreach ($item in $paths) {
            if (Test-Path $item) {
                if ( (Get-Item -Path $item).Extension -eq '.psd1') {
                    Write-Verbose -Message "Loading bot configuration from [$item]"
                    $hash = Get-Content -Path $item -Raw | ConvertFrom-Metadata
                    $config = [BotConfiguration]::new()
                    foreach ($key in $hash.Keys) {
                        if ($config | Get-Member -MemberType Property -Name $key) {
                            switch ($key) {
                                'ChannelRules' {
                                    $config.ChannelRules = @()
                                    foreach ($item in $hash[$key]) {
                                        $config.ChannelRules += [ChannelRule]::new($item.Channel, $item.IncludeCommands, $item.ExcludeCommands)
                                    }
                                    break
                                }
                                'ApprovalConfiguration' {
                                    
                                    if ($hash[$key].ExpireMinutes -is [int]) {
                                        $config.ApprovalConfiguration.ExpireMinutes = $hash[$key].ExpireMinutes
                                    }
                                    
                                    if ($hash[$key].Commands.Count -ge 1) {
                                        foreach ($approvalConfig in $hash[$key].Commands) {
                                            $acc = [ApprovalCommandConfiguration]::new()
                                            $acc.Expression = $approvalConfig.Expression
                                            $acc.ApprovalGroups = $approvalConfig.Groups
                                            $acc.PeerApproval = $approvalConfig.PeerApproval
                                            $config.ApprovalConfiguration.Commands.Add($acc) > $null
                                        }
                                    }
                                    break
                                }
                                'MiddlewareConfiguration' {
                                    foreach ($type in [enum]::GetNames([MiddlewareType])) {
                                        foreach ($item in $hash[$key].$type) {
                                            $config.MiddlewareConfiguration.Add([MiddlewareHook]::new($item.Name, $item.Path), $type)
                                        }
                                    }
                                    break
                                }
                                Default {
                                    $config.$Key = $hash[$key]
                                    break
                                }
                            }
                        }
                    }
                    $config
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Write-Error -Message "Path [$item] is not valid."
            }
        }
    }
}

Export-ModuleMember -Function 'Get-PoshBotConfiguration'
