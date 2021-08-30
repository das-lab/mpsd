
function New-PoshBotInstance {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding(DefaultParameterSetName = 'path')]
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
        [string[]]$LiteralPath,

        [parameter(
            Mandatory,
            ParameterSetName = 'config',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [BotConfiguration[]]$Configuration,

        [parameter(Mandatory)]
        [Backend]$Backend
    )

    begin {
        $here = $PSScriptRoot
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'path' -or $PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
            } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
                $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
            }

            $Configuration = @()
            foreach ($item in $paths) {
                if (Test-Path $item) {
                    if ( (Get-Item -Path $item).Extension -eq '.psd1') {
                        $Configuration += Get-PoshBotConfiguration -Path $item
                    } else {
                        Throw 'Path must be to a valid .psd1 file'
                    }
                } else {
                    Write-Error -Message "Path [$item] is not valid."
                }
            }
        }

        foreach ($config in $Configuration) {
            Write-Verbose -Message "Creating bot instance with name [$($config.Name)]"
            [Bot]::new($Backend, $here, $config)
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotInstance'
