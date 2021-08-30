
class TeamsConnection : Connection {

    [object]$ReceiveJob = $null

    [System.Management.Automation.PowerShell]$PowerShell

    
    [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]$ReceiverControl = [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]@{}

    
    [System.Collections.Concurrent.ConcurrentQueue[string]]$ReceiverMessages = [System.Collections.Concurrent.ConcurrentQueue[string]]@{}

    [object]$Handler = $null

    hidden [pscustomobject]$_AccessTokenInfo

    hidden [datetime]$_AccessTokenExpiration

    [bool]$Connected

    TeamsConnection([TeamsConnectionConfig]$Config) {
        $this.Config = $Config
    }

    
    [void]Initialize() {
        $runspacePool = [RunspaceFactory]::CreateRunspacePool(1, 1)
        $runspacePool.Open()
        $this.PowerShell = [PowerShell]::Create()
        $this.PowerShell.RunspacePool = $runspacePool
        $this.ReceiverControl['ShouldRun'] = $true
    }

    
    [void]Connect() {
        
        if ($this.PowerShell.InvocationStateInfo.State -ne 'Running') {
            $this.Initialize()
            $this.Authenticate()
            $this.StartReceiveThread()
        } else {
            $this.LogDebug([LogSeverity]::Warning, 'Receive thread is already running')
        }
    }

    
    [void]Authenticate() {
        try {
            $this.LogDebug('Getting Bot Framework access token')
            $authUrl = 'https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token'
            $payload = @{
                grant_type    = 'client_credentials'
                client_id     = $this.Config.Credential.Username
                client_secret = $this.Config.Credential.GetNetworkCredential().password
                scope         = 'https://api.botframework.com/.default'
            }
            $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $payload -Verbose:$false
            $this._AccessTokenExpiration = ([datetime]::Now).AddSeconds($response.expires_in)
            $this._AccessTokenInfo = $response
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error authenticating to Teams', [ExceptionFormatter]::Summarize($_))
            throw $_
        }
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function', Target='*')]
    [void]StartReceiveThread() {

        
        $recv = {
            [cmdletbinding()]
            param(
                [parameter(Mandatory)]
                [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]$ReceiverControl,

                [parameter(Mandatory)]
                [System.Collections.Concurrent.ConcurrentQueue[string]]$ReceiverMessages,

                [parameter(Mandatory)]
                [string]$ModulePath,

                [parameter(Mandatory)]
                [string]$ServiceBusNamespace,

                [parameter(Mandatory)]
                [string]$QueueName,

                [parameter(Mandatory)]
                [string]$AccessKeyName,

                [parameter(Mandatory)]
                [string]$AccessKey
            )

            $connectionString = "Endpoint=sb://{0}.servicebus.windows.net/;SharedAccessKeyName={1};SharedAccessKey={2}" -f $ServiceBusNamespace, $AccessKeyName, $AccessKey
            $receiveTimeout = [timespan]::new(0, 0, 0, 5)

            
            
            
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                . "$ModulePath/lib/windows/ServiceBusReceiver_net45.ps1"
            } else {
                . "$ModulePath/lib/linux/ServiceBusReceiver_netstandard.ps1"
            }
        }

        try {
            $cred = [pscredential]::new($this.Config.AccessKeyName, $this.Config.AccessKey)
            $runspaceParams = @{
                ReceiverControl     = $this.ReceiverControl
                ReceiverMessages    = $this.ReceiverMessages
                ModulePath          = $script:moduleBase
                ServiceBusNamespace = $this.Config.ServiceBusNamespace
                QueueName           = $this.Config.QueueName
                AccessKeyName       = $this.Config.AccessKeyName
                AccessKey           = $cred.GetNetworkCredential().password
            }

            $this.PowerShell.AddScript($recv)
            $this.PowerShell.AddParameters($runspaceParams) > $null
            $this.Handler = $this.PowerShell.BeginInvoke()
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            $this.LogInfo('Started Teams Service Bus background thread')
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
            $this.PowerShell.EndInvoke($this.Handler)
            $this.PowerShell.Dispose()
            $this.Connected = $false
            $this.Status = [ConnectionStatus]::Disconnected
        }
    }

    [string[]]ReadReceiveThread() {
        
        
        
        
        
        

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        

        
        

        
        
        if (($this._AccessTokenExpiration - [datetime]::Now).TotalSeconds -lt 1800) {
            $this.LogDebug('Teams access token is expiring soon. Refreshing...')
            $this.Authenticate()
        }

        
        if ($this.PowerShell.InvocationStateInfo.State -ne 'Running') {

            
            if ($this.PowerShell.Streams.Error.Count -gt 0) {
                $this.PowerShell.Streams.Error.Foreach({
                    $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                })
            }
            $this.PowerShell.Streams.ClearStreams()

            $this.LogInfo([LogSeverity]::Warning, "Receive thread is [$($this.PowerShell.InvocationStateInfo.State)]. Attempting to reconnect...")
            Start-Sleep -Seconds 5
            $this.Connect()
        }

        
        if ($this.ReceiverMessages.Count -gt 0) {
            $dequeuedMessages = $null
            $messages = [System.Collections.Generic.LinkedList[string]]::new()
            while($this.ReceiverMessages.TryDequeue([ref]$dequeuedMessages)) {
                foreach ($m in $dequeuedMessages) {
                    $messages.Add($m) > $null
                }
            }
            return $messages
        } else {
            return $null
        }
    }

    
    [void]Disconnect() {
        $this.LogInfo('Stopping Service Bus receiver')
        $this.ReceiverControl.ShouldRun = $false
        $this.PowerShell.EndInvoke($this.Handler)
        $this.PowerShell.Dispose()
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
