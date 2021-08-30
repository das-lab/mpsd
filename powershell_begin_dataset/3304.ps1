
function Save-PoshBotConfiguration {
    
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Configuration')]
        [BotConfiguration]$InputObject,

        [string]$Path = (Join-Path -Path $script:defaultPoshBotDir -ChildPath 'PoshBot.psd1'),

        [switch]$Force,

        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ShouldProcess($Path, 'Save PoshBot configuration')) {
            $hash = @{}
            foreach ($prop in ($InputObject | Get-Member -MemberType Property)) {
                switch ($prop.Name) {
                    
                    
                    'ChannelRules' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    'ApprovalConfiguration' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    'MiddlewareConfiguration' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    Default {
                        $hash.Add($prop.Name, $InputObject.($prop.Name))
                        break
                    }
                }
            }

            $meta = $hash | ConvertTo-Metadata -WarningAction SilentlyContinue
            if (-not (Test-Path -Path $Path) -or $Force) {
                New-Item -Path $Path -ItemType File -Force | Out-Null

                $meta | Out-file -FilePath $Path -Force -Encoding utf8
                Write-Verbose -Message "PoshBot configuration saved to [$Path]"

                if ($PassThru) {
                    Get-Item -Path $Path | Select-Object -First 1
                }
            } else {
                Write-Error -Message 'File already exists. Use the -Force switch to overwrite the file.'
            }
        }
    }
}

Export-ModuleMember -Function 'Save-PoshBotConfiguration'
