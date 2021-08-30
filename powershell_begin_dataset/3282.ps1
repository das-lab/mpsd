
function New-PoshBotTeamsBackend {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )

    begin {
        $requiredProperties = @(
            'BotName', 'TeamId', 'Credential', 'ServiceBusNamespace', 'QueueName', 'AccessKeyName', 'AccessKey'
        )
    }

    process {
        foreach ($item in $Configuration) {

            
            if ($missingProperties = $requiredProperties.Where({$item.Keys -notcontains $_})) {
                throw "The following required backend properties are not defined: $($missingProperties -join ', ')"
            }
            Write-Verbose 'Creating new Teams backend instance'

            $connectionConfig = [TeamsConnectionConfig]::new()
            $connectionConfig.BotName             = $item.BotName
            $connectionConfig.TeamId              = $item.TeamId
            $connectionConfig.Credential          = $item.Credential
            $connectionConfig.ServiceBusNamespace = $item.ServiceBusNamespace
            $connectionConfig.QueueName           = $item.QueueName
            $connectionConfig.AccessKeyName       = $item.AccessKeyName
            $connectionConfig.AccessKey           = $item.AccessKey

            $backend = [TeamsBackend]::new($connectionConfig)
            if ($item.Name) {
                $backend.Name = $item.Name
            }
            $backend
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTeamsBackend'
