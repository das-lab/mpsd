
function Install-CService
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='NetworkServiceAccount')]
    [OutputType([ServiceProcess.ServiceController])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,

        [string[]]
        
        $ArgumentList,
        
        [ServiceProcess.ServiceStartMode]
        
        
        
        $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,

        [Switch]
        
        
        
        $Delayed,
        
        [Carbon.Service.FailureAction]
        
        $OnFirstFailure = [Carbon.Service.FailureAction]::TakeNoAction,
        
        [Carbon.Service.FailureAction]
        
        $OnSecondFailure = [Carbon.Service.FailureAction]::TakeNoAction,
        
        [Carbon.Service.FailureAction]
        
        $OnThirdFailure = [Carbon.Service.FailureAction]::TakeNoAction,

        [int]
        
        $ResetFailureCount = 0,
        
        [int]
        
        $RestartDelay = 60000,
        
        [int]
        
        $RebootDelay = 60000,

        [Alias('Dependencies')]
        [string[]]
        
        $Dependency,
        
        [string]
        
        $Command,
        
        [int]
        
        $RunCommandDelay = 0,

        [string]
        
        
        
        $Description,

        [string]
        
        
        
        $DisplayName,
        
        [Parameter(ParameterSetName='CustomAccount',Mandatory=$true)]
        [string]
        
        $UserName,
        
        [Parameter(ParameterSetName='CustomAccount',DontShow=$true)]
        [string]
        
        $Password,

        [Parameter(ParameterSetName='CustomAccountWithCredential',Mandatory=$true)]
        [pscredential]
        
        
        
        $Credential,

        [Switch]
        
        $Force,

        [Switch]
        
        $PassThru,

        [Switch]
        
        $EnsureRunning
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function ConvertTo-FailureActionArg($action)
    {
        if( $action -eq 'Reboot' )
        {
            return "reboot/{0}" -f $RebootDelay
        }
        elseif( $action -eq 'Restart' )
        {
            return "restart/{0}" -f $RestartDelay
        }
        elseif( $action -eq 'RunCommand' )
        {
            return 'run/{0}' -f $RunCommandDelay
        }
        elseif( $action -eq 'TakeNoAction' )
        {
            return '""/0'
        }
        else
        {
            Write-Error "Service failure action '$action' not found/recognized."
            return ''
        }
    }

    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $PSCmdlet.ParameterSetName -like '*WithCredential' )
        {
            $UserName = $Credential.UserName
        }
        elseif( $Password )
        {
            Write-Warning ('`Install-CService` function''s `Password` parameter is obsolete and will be removed in a future major version of Carbon. Please use the `Credential` parameter instead.')
            $Credential = New-CCredential -UserName $UserName -Password $Password
        }
        else
        {
            $Credential = $null
        }


        $identity = Resolve-CIdentity -Name $UserName

        if( -not $identity )
        {
            Write-Error ("Identity '{0}' not found." -f $UserName)
            return
        }
    }
    else
    {
        $identity = Resolve-CIdentity "NetworkService"
    }
    
    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Warning ('Service ''{0}'' executable ''{1}'' not found.' -f $Name,$Path)
    }
    else
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
    }


    if( $ArgumentList )	
    {	
        $binPathArg = Invoke-Command -ScriptBlock {	
                            $Path	
                            $ArgumentList 	
                        } |	
                        ForEach-Object { 	
                            if( $_.Contains(' ') )	
                            {	
                                return '"{0}"' -f $_.Trim('"')	
                            }	
                            return $_	
                        }	
        $binPathArg = $binPathArg -join ' '	
    }	
    else	
    {	
        $binPathArg = $Path	
    }

    $doInstall = $false
    if( -not $Force -and (Test-CService -Name $Name) )
    {
        Write-Debug -Message ('Service {0} exists. Checking if configuration has changed.' -f $Name)
        $service = Get-Service -Name $Name
        $serviceConfig = Get-CServiceConfiguration -Name $Name
        $dependedOnServiceNames = $service.ServicesDependedOn | Select-Object -ExpandProperty 'Name'

        if( $service.Path -ne $binPathArg )
        {
            Write-Verbose ('[{0}] Path              {1} -> {2}' -f $Name,$serviceConfig.Path,$binPathArg)
            $doInstall = $true
        }

        
        
        
        if( $PSBoundParameters.ContainsKey('DisplayName') )
        {
            if( $service.DisplayName -ne $DisplayName )
            {
                Write-Verbose ('[{0}] DisplayName       {1} -> {2}' -f $Name,$service.DisplayName,$DisplayName)
                $doInstall = $true
            }
        }
        elseif( $service.DisplayName -ne $service.Name )
        {
            Write-Verbose ('[{0}] DisplayName       {1} -> ' -f $Name,$service.DisplayName)
            $doInstall = $true
        }

        if( $serviceConfig.FirstFailure -ne $OnFirstFailure )
        {
            Write-Verbose ('[{0}] OnFirstFailure    {1} -> {2}' -f $Name,$serviceConfig.FirstFailure,$OnFirstFailure)
            $doInstall = $true
        }

        if( $serviceConfig.SecondFailure -ne $OnSecondFailure )
        {
            Write-Verbose ('[{0}] OnSecondFailure   {1} -> {2}' -f $Name,$serviceConfig.SecondFailure,$OnSecondFailure)
            $doInstall = $true
        }

        if( $serviceConfig.ThirdFailure -ne $OnThirdFailure )
        {
            Write-Verbose ('[{0}] OnThirdFailure    {1} -> {2}' -f $Name,$serviceConfig.ThirdFailure,$OnThirdFailure)
            $doInstall = $true
        }

        if( $serviceConfig.ResetPeriod -ne $ResetFailureCount )
        {
            Write-Verbose ('[{0}] ResetFailureCount {1} -> {2}' -f $Name,$serviceConfig.ResetPeriod,$ResetFailureCount)
            $doInstall = $true
        }
        
        $failureActions = $OnFirstFailure,$OnSecondFailure,$OnThirdFailure
        if( ($failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Reboot }) -and $serviceConfig.RebootDelay -ne $RebootDelay )
        {
            Write-Verbose ('[{0}] RebootDelay       {1} -> {2}' -f $Name,$serviceConfig.RebootDelay,$RebootDelay)
            $doInstall = $true
        }

        if( ($failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Restart }) -and $serviceConfig.RestartDelay -ne $RestartDelay)
        {
            Write-Verbose ('[{0}] RestartDelay      {1} -> {2}' -f $Name,$serviceConfig.RestartDelay,$RestartDelay)
            $doInstall = $true
        }

        if( $failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::RunCommand } )
        {
            if( $serviceConfig.FailureProgram -ne $Command )
            {
                Write-Verbose ('[{0}] Command           {1} -> {2}' -f $Name,$serviceConfig.FailureProgram,$Command)
                $doInstall = $true
            }

            if( $serviceConfig.RunCommandDelay -ne $RunCommandDelay )
            {
                Write-Verbose ('[{0}] RunCommandDelay   {1} -> {2}' -f $Name,$serviceConfig.RunCommandDelay,$RunCommandDelay)
                $doInstall = $true
            }
        }

        if( $service.StartMode -ne $StartupType )
        {
            Write-Verbose ('[{0}] StartupType       {1} -> {2}' -f $Name,$serviceConfig.StartType,$StartupType)
            $doInstall = $true
        }

        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic -and $Delayed -ne $serviceConfig.DelayedAutoStart )
        {
            Write-Verbose ('[{0}] DelayedAutoStart  {1} -> {2}' -f $Name,$service.DelayedAutoStart,$Delayed)
            $doInstall = $true
        }

        if( ($Dependency | Where-Object { $dependedOnServiceNames -notcontains $_ }) -or `
            ($dependedOnServiceNames | Where-Object { $Dependency -notcontains $_ })  )
        {
            Write-Verbose ('[{0}] Dependency        {1} -> {2}' -f $Name,($dependedOnServiceNames -join ','),($Dependency -join ','))
            $doInstall = $true
        }

        if( $Description -and $serviceConfig.Description -ne $Description )
        {
            Write-Verbose ('[{0}] Description       {1} -> {2}' -f $Name,$serviceConfig.Description,$Description)
            $doInstall = $true
        }

        $currentIdentity = Resolve-CIdentity $serviceConfig.UserName
        if( $currentIdentity.FullName -ne $identity.FullName )
        {
            Write-Verbose ('[{0}] UserName          {1} -> {2}' -f $Name,$currentIdentity.FullName,$identity.FullName)
            $doinstall = $true
        }
    }
    else
    {
        $doInstall = $true
    }

    try
    {
        if( -not $doInstall )
        {
            Write-Debug -Message ('Skipping {0} service configuration: settings unchanged.' -f $Name)
            return
        }

        if( $Dependency )
        {
            $missingDependencies = $false
            $Dependency | 
                ForEach-Object {
                    if( -not (Test-CService -Name $_) )
                    {
                        Write-Error ('Dependent service {0} not found.' -f $_)
                        $missingDependencies = $true
                    }
                }
            if( $missingDependencies )
            {
                return
            }
        }
    
        $sc = Join-Path $env:WinDir system32\sc.exe -Resolve
    
        $startArg = 'auto'
        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic -and $Delayed )
        {
            $startArg = 'delayed-auto'
        }
        elseif( $StartupType -eq [ServiceProcess.ServiceStartMode]::Manual )
        {
            $startArg = 'demand'
        }
        elseif( $StartupType -eq [ServiceProcess.ServiceStartMode]::Disabled )
        {
            $startArg = 'disabled'
        }
    
        $passwordArgName = ''
        $passwordArgValue = ''
        if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
        {
            if( $Credential )
            {
                $passwordArgName = 'password='
                $passwordArgValue = $Credential.GetNetworkCredential().Password -replace '"', '\"'
            }
        
            if( $PSCmdlet.ShouldProcess( $identity.FullName, "grant the log on as a service right" ) )
            {
                Grant-CPrivilege -Identity $identity.FullName -Privilege SeServiceLogonRight
            }
        }
    
        if( $PSCmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity.FullName) ) )
        {
            Grant-CPermission -Identity $identity.FullName -Permission ReadAndExecute -Path $Path
        }
    
        $service = Get-Service -Name $Name -ErrorAction Ignore
    
        $operation = 'create'
        $serviceIsRunningStatus = @(
                                      [ServiceProcess.ServiceControllerStatus]::Running,
                                      [ServiceProcess.ServiceControllerStatus]::StartPending
                                   )

        if( -not $EnsureRunning )
        {
            $EnsureRunning = ($StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic)
        }

        if( $service )
        {
            $EnsureRunning = ( $EnsureRunning -or ($serviceIsRunningStatus -contains $service.Status) )
            if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Disabled )
            {
                $EnsureRunning = $false
            }

            if( $service.CanStop )
            {
                Stop-Service -Name $Name -Force -ErrorAction Ignore
                if( $? )
                {
                    $service.WaitForStatus( 'Stopped' )
                }
            }

            if( -not ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Stopped) )
            {
                Write-Warning "Unable to stop service '$Name' before applying config changes.  You may need to restart this service manually for any changes to take affect."
            }
            $operation = 'config'
        }
    
        $dependencyArgValue = '""'
        if( $Dependency )
        {
            $dependencyArgValue = $Dependency -join '/'
        }

        $displayNameArgName = 'DisplayName='
        $displayNameArgValue = '""'
        if( $DisplayName )
        {
            $displayNameArgValue = $DisplayName
        }

        $binPathArg = $binPathArg -replace '"','\"'
        if( $PSCmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ) )
        {
            Write-Verbose "$sc $operation $Name binPath= $binPathArg start= $startArg obj= $($identity.FullName) $passwordArgName $('*' * $passwordArgValue.Length) depend= $dependencyArgValue $displayNameArgName $displayNameArgValue" -Verbose
            & $sc $operation $Name binPath= $binPathArg start= $startArg obj= $identity.FullName $passwordArgName $passwordArgValue depend= $dependencyArgValue $displayNameArgName $displayNameArgValue |
                Write-Verbose
            $scExitCode = $LastExitCode
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to {0} service '{1}'. {2} returned exit code {3}: {4}" -f $operation,$Name,$sc,$scExitCode,$reason)
                return
            }

            if( $Description )
            {
                & $sc 'description' $Name $Description | Write-Verbose
                $scExitCode = $LastExitCode
                if( $scExitCode -ne 0 )
                {
                    $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                    Write-Error ("Failed to set {0} service's description. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                    return
                }
            }
        }
    
        $firstAction = ConvertTo-FailureActionArg $OnFirstFailure
        $secondAction = ConvertTo-FailureActionArg $OnSecondFailure
        $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure

        if( -not $Command )
        {
            $Command = '""'
        }

        if( $PSCmdlet.ShouldProcess( $Name, "setting service failure actions" ) )
        {
            & $sc failure $Name reset= $ResetFailureCount actions= $firstAction/$secondAction/$thirdAction command= $Command |
                Write-Verbose
            $scExitCode = $LastExitCode
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to set {0} service's failure actions. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                return
            }
        }
    }
    finally
    {
        if( $EnsureRunning )
        {
            if( $PSCmdlet.ShouldProcess( $Name, 'start service' ) )
            {
                Start-Service -Name $Name -ErrorAction $ErrorActionPreference
                if( (Get-Service -Name $Name).Status -ne [ServiceProcess.ServiceControllerStatus]::Running )
                {
                    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' -and -not $Credential )
                    {
                        Write-Warning ('Service ''{0}'' didn''t start and you didn''t supply a password to Install-CService.  Is ''{1}'' a managed service account or virtual account? (See http://technet.microsoft.com/en-us/library/dd548356.aspx.)  If not, please use the `Credential` parameter to pass the account''s credentials.' -f $Name,$UserName)
                    }
                    else
                    {
                        Write-Warning ('Failed to re-start service ''{0}''.' -f $Name)
                    }
                }
            }
        }
        else
        {
            Write-Verbose ('Not re-starting {0} service. Its startup type is {1} and it wasn''t running when configuration began. To always start a service after configuring it, use the -EnsureRunning switch.' -f $Name,$StartupType)
        }

        if( $PassThru )
        {
            Get-Service -Name $Name -ErrorAction Ignore
        }
    }
}
