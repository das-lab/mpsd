Function Invoke-Ping
{

    [cmdletbinding(DefaultParameterSetName = 'Ping')]
    param (
        [Parameter(ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Detail')]
        [validateset("*", "WSMan", "RemoteReg", "RPC", "RDP", "SMB")]
        [string[]]$Detail,

        [Parameter(ParameterSetName = 'Ping')]
        [switch]$Quiet,

        [int]$Timeout = 20,

        [int]$Throttle = 100,

        [switch]$NoCloseOnTimeout
    )
    Begin
    {

        
        function Invoke-Parallel
        {
            [cmdletbinding(DefaultParameterSetName = 'ScriptBlock')]
            Param (
                [Parameter(Mandatory = $false, position = 0, ParameterSetName = 'ScriptBlock')]
                [System.Management.Automation.ScriptBlock]$ScriptBlock,

                [Parameter(Mandatory = $false, ParameterSetName = 'ScriptFile')]
                [ValidateScript({ test-path $_ -pathtype leaf })]
                $ScriptFile,

                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
                [Alias('CN', '__Server', 'IPAddress', 'Server', 'ComputerName')]
                [PSObject]$InputObject,

                [PSObject]$Parameter,

                [switch]$ImportVariables,

                [switch]$ImportModules,

                [int]$Throttle = 20,

                [int]$SleepTimer = 200,

                [int]$RunspaceTimeout = 0,

                [switch]$NoCloseOnTimeout = $false,

                [int]$MaxQueue,

                [validatescript({ Test-Path (Split-Path $_ -parent) })]
                [string]$LogFile = "C:\temp\log.log",

                [switch]$Quiet = $false
            )

            Begin
            {

                
                
                if (-not $PSBoundParameters.ContainsKey('MaxQueue'))
                {
                    if ($RunspaceTimeout -ne 0) { $script:MaxQueue = $Throttle }
                    else { $script:MaxQueue = $Throttle * 3 }
                }
                else
                {
                    $script:MaxQueue = $MaxQueue
                }

                Write-Verbose "Throttle: '$throttle' SleepTimer '$sleepTimer' runSpaceTimeout '$runspaceTimeout' maxQueue '$maxQueue' logFile '$logFile'"

                
                if ($ImportVariables -or $ImportModules)
                {
                    $StandardUserEnv = [powershell]::Create().addscript({

                        
                        $Modules = Get-Module | Select-Object -ExpandProperty Name
                        $Snapins = Get-PSSnapin | Select-Object -ExpandProperty Name

                        
                        
                        $Variables = Get-Variable | Select-Object -ExpandProperty Name

                        
                        @{
                            Variables = $Variables
                            Modules = $Modules
                            Snapins = $Snapins
                        }
                    }).invoke()[0]

                    if ($ImportVariables)
                    {
                        
                        Function _temp { [cmdletbinding()]
                            param () }
                        $VariablesToExclude = @((Get-Command _temp | Select-Object -ExpandProperty parameters).Keys + $PSBoundParameters.Keys + $StandardUserEnv.Variables)
                        Write-Verbose "Excluding variables $(($VariablesToExclude | Sort-Object) -join ", ")"

                        
                        
                        
                        
                        $UserVariables = @(Get-Variable | Where-Object { -not ($VariablesToExclude -contains $_.Name) })
                        Write-Verbose "Found variables to import: $(($UserVariables | Select-Object -expandproperty Name | Sort-Object) -join ", " | Out-String).`n"

                    }

                    if ($ImportModules)
                    {
                        $UserModules = @(Get-Module | Where-Object { $StandardUserEnv.Modules -notcontains $_.Name -and (Test-Path $_.Path -ErrorAction SilentlyContinue) } | Select-Object -ExpandProperty Path)
                        $UserSnapins = @(Get-PSSnapin | Select-Object -ExpandProperty Name | Where-Object { $StandardUserEnv.Snapins -notcontains $_ })
                    }
                }

                

                Function Get-RunspaceData
                {
                    [cmdletbinding()]
                    param ([switch]$Wait)

                    
                    
                    Do
                    {

                        
                        $more = $false

                        
                        if (-not $Quiet)
                        {
                            Write-Progress -Activity "Running Query" -Status "Starting threads"`
                                           -CurrentOperation "$startedCount threads defined - $totalCount input objects - $script:completedCount input objects processed"`
                                           -PercentComplete $(Try { $script:completedCount / $totalCount * 100 }
                            Catch { 0 })
                        }

                        
                        Foreach ($runspace in $runspaces)
                        {

                            
                            $currentdate = Get-Date
                            $runtime = $currentdate - $runspace.startTime
                            $runMin = [math]::Round($runtime.totalminutes, 2)

                            
                            $log = "" | Select-Object Date, Action, Runtime, Status, Details
                            $log.Action = "Removing:'$($runspace.object)'"
                            $log.Date = $currentdate
                            $log.Runtime = "$runMin minutes"

                            
                            If ($runspace.Runspace.isCompleted)
                            {

                                $script:completedCount++

                                
                                if ($runspace.powershell.Streams.Error.Count -gt 0)
                                {

                                    
                                    $log.status = "CompletedWithErrors"
                                    Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                    foreach ($ErrorRecord in $runspace.powershell.Streams.Error)
                                    {
                                        Write-Error -ErrorRecord $ErrorRecord
                                    }
                                }
                                else
                                {

                                    
                                    $log.status = "Completed"
                                    Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                }

                                
                                $runspace.powershell.EndInvoke($runspace.Runspace)
                                $runspace.powershell.dispose()
                                $runspace.Runspace = $null
                                $runspace.powershell = $null

                            }

                            
                            ElseIf ($runspaceTimeout -ne 0 -and $runtime.totalseconds -gt $runspaceTimeout)
                            {

                                $script:completedCount++
                                $timedOutTasks = $true

                                
                                $log.status = "TimedOut"
                                Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                Write-Error "Runspace timed out at $($runtime.totalseconds) seconds for the object:`n$($runspace.object | out-string)"

                                
                                if (!$noCloseOnTimeout) { $runspace.powershell.dispose() }
                                $runspace.Runspace = $null
                                $runspace.powershell = $null
                                $completedCount++

                            }

                            
                            ElseIf ($runspace.Runspace -ne $null)
                            {
                                $log = $null
                                $more = $true
                            }

                            
                            if ($logFile -and $log)
                            {
                                ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1] | out-file $LogFile -append
                            }
                        }

                        
                        $temphash = $runspaces.clone()
                        $temphash | Where-Object { $_.runspace -eq $Null } | ForEach-Object {
                            $Runspaces.remove($_)
                        }

                        
                        if ($PSBoundParameters['Wait']) { Start-Sleep -milliseconds $SleepTimer }

                        
                    }
                    while ($more -and $PSBoundParameters['Wait'])

                    
                }

                

                

                if ($PSCmdlet.ParameterSetName -eq 'ScriptFile')
                {
                    $ScriptBlock = [scriptblock]::Create($(Get-Content $ScriptFile | out-string))
                }
                elseif ($PSCmdlet.ParameterSetName -eq 'ScriptBlock')
                {
                    
                    [string[]]$ParamsToAdd = '$_'
                    if ($PSBoundParameters.ContainsKey('Parameter'))
                    {
                        $ParamsToAdd += '$Parameter'
                    }

                    $UsingVariableData = $Null


                    
                    

                    if ($PSVersionTable.PSVersion.Major -gt 2)
                    {
                        
                        $UsingVariables = $ScriptBlock.ast.FindAll({ $args[0] -is [System.Management.Automation.Language.UsingExpressionAst] }, $True)

                        If ($UsingVariables)
                        {
                            $List = New-Object 'System.Collections.Generic.List`1[System.Management.Automation.Language.VariableExpressionAst]'
                            ForEach ($Ast in $UsingVariables)
                            {
                                [void]$list.Add($Ast.SubExpression)
                            }

                            $UsingVar = $UsingVariables | Group-Object Parent | ForEach-Object { $_.Group | Select-Object -First 1 }

                            
                            $UsingVariableData = ForEach ($Var in $UsingVar)
                            {
                                Try
                                {
                                    $Value = Get-Variable -Name $Var.SubExpression.VariablePath.UserPath -ErrorAction Stop
                                    $NewName = ('$__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                    [pscustomobject]@{
                                        Name = $Var.SubExpression.Extent.Text
                                        Value = $Value.Value
                                        NewName = $NewName
                                        NewVarName = ('__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                    }
                                    $ParamsToAdd += $NewName
                                }
                                Catch
                                {
                                    Write-Error "$($Var.SubExpression.Extent.Text) is not a valid Using: variable!"
                                }
                            }

                            $NewParams = $UsingVariableData.NewName -join ', '
                            $Tuple = [Tuple]::Create($list, $NewParams)
                            $bindingFlags = [Reflection.BindingFlags]"Default,NonPublic,Instance"
                            $GetWithInputHandlingForInvokeCommandImpl = ($ScriptBlock.ast.gettype().GetMethod('GetWithInputHandlingForInvokeCommandImpl', $bindingFlags))

                            $StringScriptBlock = $GetWithInputHandlingForInvokeCommandImpl.Invoke($ScriptBlock.ast, @($Tuple))

                            $ScriptBlock = [scriptblock]::Create($StringScriptBlock)

                            Write-Verbose $StringScriptBlock
                        }
                    }

                    $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param($($ParamsToAdd -Join ", "))`r`n" + $Scriptblock.ToString())
                }
                else
                {
                    Throw "Must provide ScriptBlock or ScriptFile"; Break
                }

                Write-Debug "`$ScriptBlock: $($ScriptBlock | Out-String)"
                Write-Verbose "Creating runspace pool and session states"

                
                $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                if ($ImportVariables)
                {
                    if ($UserVariables.count -gt 0)
                    {
                        foreach ($Variable in $UserVariables)
                        {
                            $sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Variable.Name, $Variable.Value, $null))
                        }
                    }
                }
                if ($ImportModules)
                {
                    if ($UserModules.count -gt 0)
                    {
                        foreach ($ModulePath in $UserModules)
                        {
                            $sessionstate.ImportPSModule($ModulePath)
                        }
                    }
                    if ($UserSnapins.count -gt 0)
                    {
                        foreach ($PSSnapin in $UserSnapins)
                        {
                            [void]$sessionstate.ImportPSSnapIn($PSSnapin, [ref]$null)
                        }
                    }
                }

                
                $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
                $runspacepool.Open()

                Write-Verbose "Creating empty collection to hold runspace jobs"
                $Script:runspaces = New-Object System.Collections.ArrayList

                
                $global:__bound = $false
                $allObjects = @()
                if ($PSBoundParameters.ContainsKey("inputObject"))
                {
                    $global:__bound = $true
                }

                
                if ($LogFile)
                {
                    New-Item -ItemType file -path $logFile -force | Out-Null
                    ("" | Select-Object Date, Action, Runtime, Status, Details | ConvertTo-Csv -NoTypeInformation -Delimiter ";")[0] | Out-File $LogFile
                }

                
                $log = "" | Select-Object Date, Action, Runtime, Status, Details
                $log.Date = Get-Date
                $log.Action = "Batch processing started"
                $log.Runtime = $null
                $log.Status = "Started"
                $log.Details = $null
                if ($logFile)
                {
                    ($log | convertto-csv -Delimiter ";" -NoTypeInformation)[1] | Out-File $LogFile -Append
                }

                $timedOutTasks = $false

                
            }

            Process
            {

                
                if (-not $global:__bound)
                {
                    $allObjects += $inputObject
                }
                else
                {
                    $allObjects = $InputObject
                }
            }

            End
            {

                
                Try
                {
                    
                    $totalCount = $allObjects.count
                    $script:completedCount = 0
                    $startedCount = 0

                    foreach ($object in $allObjects)
                    {

                        

                        
                        $powershell = [powershell]::Create()

                        if ($VerbosePreference -eq 'Continue')
                        {
                            [void]$PowerShell.AddScript({ $VerbosePreference = 'Continue' })
                        }

                        [void]$PowerShell.AddScript($ScriptBlock).AddArgument($object)

                        if ($parameter)
                        {
                            [void]$PowerShell.AddArgument($parameter)
                        }

                        
                        if ($UsingVariableData)
                        {
                            Foreach ($UsingVariable in $UsingVariableData)
                            {
                                Write-Verbose "Adding $($UsingVariable.Name) with value: $($UsingVariable.Value)"
                                [void]$PowerShell.AddArgument($UsingVariable.Value)
                            }
                        }

                        
                        $powershell.RunspacePool = $runspacepool

                        
                        $temp = "" | Select-Object PowerShell, StartTime, object, Runspace
                        $temp.PowerShell = $powershell
                        $temp.StartTime = Get-Date
                        $temp.object = $object

                        
                        $temp.Runspace = $powershell.BeginInvoke()
                        $startedCount++

                        
                        Write-Verbose ("Adding {0} to collection at {1}" -f $temp.object, $temp.starttime.tostring())
                        $runspaces.Add($temp) | Out-Null

                        
                        Get-RunspaceData

                        
                        
                        $firstRun = $true
                        while ($runspaces.count -ge $Script:MaxQueue)
                        {

                            
                            if ($firstRun)
                            {
                                Write-Verbose "$($runspaces.count) items running - exceeded $Script:MaxQueue limit."
                            }
                            $firstRun = $false

                            
                            Get-RunspaceData
                            Start-Sleep -Milliseconds $sleepTimer

                        }

                        
                    }

                    Write-Verbose ("Finish processing the remaining runspace jobs: {0}" -f (@($runspaces | Where-Object { $_.Runspace -ne $Null }).Count))
                    Get-RunspaceData -wait

                    if (-not $quiet)
                    {
                        Write-Progress -Activity "Running Query" -Status "Starting threads" -Completed
                    }

                }
                Finally
                {
                    
                    if (($timedOutTasks -eq $false) -or (($timedOutTasks -eq $true) -and ($noCloseOnTimeout -eq $false)))
                    {
                        Write-Verbose "Closing the runspace pool"
                        $runspacepool.close()
                    }

                    
                    [gc]::Collect()
                }
            }
        }

        Write-Verbose "PSBoundParameters = $($PSBoundParameters | Out-String)"

        $bound = $PSBoundParameters.keys -contains "ComputerName"
        if (-not $bound)
        {
            [System.Collections.ArrayList]$AllComputers = @()
        }
    }
    Process
    {

        
        if ($bound)
        {
            $AllComputers = $ComputerName
        }
        Else
        {
            foreach ($Computer in $ComputerName)
            {
                $AllComputers.add($Computer) | Out-Null
            }
        }

    }
    End
    {

        
        $params = @($Detail, $Quiet)
        $splat = @{
            Throttle = $Throttle
            RunspaceTimeout = $Timeout
            InputObject = $AllComputers
            parameter = $params
        }
        if ($NoCloseOnTimeout)
        {
            $splat.add('NoCloseOnTimeout', $True)
        }

        Invoke-Parallel @splat -ScriptBlock {

            $computer = $_.trim()
            $detail = $parameter[0]
            $quiet = $parameter[1]

            
            if ($detail)
            {
                Try
                {
                    
                    Function Test-Server
                    {
                        [cmdletBinding()]
                        param (
                            [parameter(
                                       Mandatory = $true,
                                       ValueFromPipeline = $true)]
                            [string[]]$ComputerName,

                            [switch]$All,

                            [parameter(Mandatory = $false)]
                            [switch]$CredSSP,

                            [switch]$RemoteReg,

                            [switch]$RDP,

                            [switch]$RPC,

                            [switch]$SMB,

                            [switch]$WSMAN,

                            [switch]$IPV6,

                            [Management.Automation.PSCredential]$Credential
                        )
                        begin
                        {
                            $total = Get-Date
                            $results = @()
                            if ($credssp -and -not $Credential)
                            {
                                Throw "Must supply Credentials with CredSSP test"
                            }

                            [string[]]$props = write-output Name, IP, Domain, Ping, WSMAN, CredSSP, RemoteReg, RPC, RDP, SMB

                            
                            $Hash = @{ }
                            foreach ($prop in $props)
                            {
                                $Hash.Add($prop, $null)
                            }

                            function Test-Port
                            {
                                [cmdletbinding()]
                                Param (
                                    [string]$srv,

                                    $port = 135,

                                    $timeout = 3000
                                )
                                $ErrorActionPreference = "SilentlyContinue"
                                $tcpclient = new-Object system.Net.Sockets.TcpClient
                                $iar = $tcpclient.BeginConnect($srv, $port, $null, $null)
                                $wait = $iar.AsyncWaitHandle.WaitOne($timeout, $false)
                                if (-not $wait)
                                {
                                    $tcpclient.Close()
                                    Write-Verbose "Connection Timeout to $srv`:$port"
                                    $false
                                }
                                else
                                {
                                    Try
                                    {
                                        $tcpclient.EndConnect($iar) | out-Null
                                        $true
                                    }
                                    Catch
                                    {
                                        write-verbose "Error for $srv`:$port`: $_"
                                        $false
                                    }
                                    $tcpclient.Close()
                                }
                            }
                        }

                        process
                        {
                            foreach ($name in $computername)
                            {
                                $dt = $cdt = Get-Date
                                Write-verbose "Testing: $Name"
                                $failed = 0
                                try
                                {
                                    $DNSEntity = [Net.Dns]::GetHostEntry($name)
                                    $domain = ($DNSEntity.hostname).replace("$name.", "")
                                    $ips = $DNSEntity.AddressList | ForEach-Object{
                                        if (-not (-not $IPV6 -and $_.AddressFamily -like "InterNetworkV6"))
                                        {
                                            $_.IPAddressToString
                                        }
                                    }
                                }
                                catch
                                {
                                    $rst = New-Object -TypeName PSObject -Property $Hash | Select-Object -Property $props
                                    $rst.name = $name
                                    $results += $rst
                                    $failed = 1
                                }
                                Write-verbose "DNS:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                if ($failed -eq 0)
                                {
                                    foreach ($ip in $ips)
                                    {

                                        $rst = New-Object -TypeName PSObject -Property $Hash | Select-Object -Property $props
                                        $rst.name = $name
                                        $rst.ip = $ip
                                        $rst.domain = $domain

                                        if ($RDP -or $All)
                                        {
                                            
                                            try
                                            {
                                                $socket = New-Object Net.Sockets.TcpClient($name, 3389) -ErrorAction stop
                                                if ($socket -eq $null)
                                                {
                                                    $rst.RDP = $false
                                                }
                                                else
                                                {
                                                    $rst.RDP = $true
                                                    $socket.close()
                                                }
                                            }
                                            catch
                                            {
                                                $rst.RDP = $false
                                                Write-Verbose "Error testing RDP: $_"
                                            }
                                        }
                                        Write-verbose "RDP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                        
                                        if (test-connection $ip -count 2 -Quiet)
                                        {
                                            Write-verbose "PING:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                            $rst.ping = $true

                                            if ($WSMAN -or $All)
                                            {
                                                try
                                                {
                                                    
                                                        Test-WSMan $ip -ErrorAction stop | Out-Null
                                                        $rst.WSMAN = $true
                                                    }
                                                    catch
                                                    {
                                                        $rst.WSMAN = $false
                                                        Write-Verbose "Error testing WSMAN: $_"
                                                    }
                                                    Write-verbose "WSMAN:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                                    if ($rst.WSMAN -and $credssp) 
                                                    {
                                                        try
                                                        {
                                                            Test-WSMan $ip -Authentication Credssp -Credential $cred -ErrorAction stop
                                                            $rst.CredSSP = $true
                                                        }
                                                        catch
                                                        {
                                                            $rst.CredSSP = $false
                                                            Write-Verbose "Error testing CredSSP: $_"
                                                        }
                                                        Write-verbose "CredSSP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                                    }
                                                }
                                                if ($RemoteReg -or $All)
                                                {
                                                    try 
                                                    {
                                                        [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $ip) | Out-Null
                                                        $rst.remotereg = $true
                                                    }
                                                    catch
                                                    {
                                                        $rst.remotereg = $false
                                                        Write-Verbose "Error testing RemoteRegistry: $_"
                                                    }
                                                    Write-verbose "remote reg:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                                }
                                                if ($RPC -or $All)
                                                {
                                                    try 
                                                    {
                                                        $w = [wmi] ''
                                                        $w.psbase.options.timeout = 15000000
                                                        $w.path = "\\$Name\root\cimv2:Win32_ComputerSystem.Name='$Name'"
                                                        $w | Select-Object none | Out-Null
                                                        $rst.RPC = $true
                                                    }
                                                    catch
                                                    {
                                                        $rst.rpc = $false
                                                        Write-Verbose "Error testing WMI/RPC: $_"
                                                    }
                                                    Write-verbose "WMI/RPC:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                                }
                                                if ($SMB -or $All)
                                                {

                                                    
                                                    try 
                                                    {
                                                        $path = "\\$name\c$"
                                                        Push-Location -Path $path -ErrorAction stop
                                                        $rst.SMB = $true
                                                        Pop-Location
                                                    }
                                                    catch
                                                    {
                                                        $rst.SMB = $false
                                                        Write-Verbose "Error testing SMB: $_"
                                                    }
                                                    Write-verbose "SMB:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"

                                                }
                                            }
                                            else
                                            {
                                                $rst.ping = $false
                                                $rst.wsman = $false
                                                $rst.credssp = $false
                                                $rst.remotereg = $false
                                                $rst.rpc = $false
                                                $rst.smb = $false
                                            }
                                            $results += $rst
                                        }
                                    }
                                    Write-Verbose "Time for $($Name): $((New-TimeSpan $cdt ($dt)).totalseconds)"
                                    Write-Verbose "----------------------------"
                                }
                            }
                            end
                            {
                                Write-Verbose "Time for all: $((New-TimeSpan $total ($dt)).totalseconds)"
                                Write-Verbose "----------------------------"
                                return $results
                            }
                        }

                        
                        $TestServerParams = @{
                            ComputerName = $Computer
                            ErrorAction = "Stop"
                        }

                        if ($detail -eq "*")
                        {
                            $detail = "WSMan", "RemoteReg", "RPC", "RDP", "SMB"
                        }

                        $detail | Select-Object -Unique | Foreach-Object { $TestServerParams.add($_, $True) }
                        Test-Server @TestServerParams | Select-Object -Property $("Name", "IP", "Domain", "Ping" + $detail)
                    }
                    Catch
                    {
                        Write-Warning "Error with Test-Server: $_"
                    }
                }
                
                else
                {
                    Try
                    {
                        
                        $result = $null
                        if ($result = @(Test-Connection -ComputerName $computer -Count 2 -erroraction Stop))
                        {
                            $Output = $result | Select-Object -first 1 -Property Address,
                                                       IPV4Address,
                                                       IPV6Address,
                                                       ResponseTime,
                                                       @{ label = "STATUS"; expression = { "Responding" } }

                            if ($quiet)
                            {
                                $Output.address
                            }
                            else
                            {
                                $Output
                            }
                        }
                    }
                    Catch
                    {
                        if (-not $quiet)
                        {
                            
                            if ($_ -match "No such host is known")
                            {
                                $status = "Unknown host"
                            }
                            elseif ($_ -match "Error due to lack of resources")
                            {
                                $status = "No Response"
                            }
                            else
                            {
                                $status = "Error: $_"
                            }

                            "" | Select-Object -Property @{ label = "Address"; expression = { $computer } },
                                        IPV4Address,
                                        IPV6Address,
                                        ResponseTime,
                                        @{ label = "STATUS"; expression = { $status } }
                        }
                    }
                }
            }
        }
    }
