
function Start-CDscPullConfiguration
{
    
    [CmdletBinding(DefaultParameterSetName='WithCredentials')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithCredentials')]
        [string[]]
        
        $ComputerName,

        [Parameter(ParameterSetName='WithCredentials')]
        [PSCredential]
        
        $Credential,

        [Parameter(ParameterSetName='WithCimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]
        $CimSession,

        [string[]]
        
        $ModuleName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $credentialParam = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'WithCredentials' )
    {
        if( $Credential )
        {
            $credentialParam.Credential = $Credential
        }

        $CimSession = New-CimSession -ComputerName $ComputerName @credentialParam
        if( -not $CimSession )
        {
            return
        }
    }

    $CimSession = Get-DscLocalConfigurationManager -CimSession $CimSession |
                    ForEach-Object {
                        if( $_.RefreshMode -ne 'Pull' )
                        {
                            Write-Error ('The Local Configuration Manager on ''{0}'' is not in Pull mode (current RefreshMode is ''{1}'').' -f $_.PSComputerName,$_.RefreshMode)
                            return
                        }

                        foreach( $session in $CimSession )
                        {
                            if( $session.ComputerName -eq $_.PSComputerName )
                            {
                                return $session
                            }
                        }
                    }

    if( -not $CimSession )
    {
        return
    }

    
    Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
        $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
        Get-ChildItem -Path $modulesRoot -Filter '*_tmp' -Directory | 
            Remove-Item -Recurse
    }

    if( $ModuleName )
    {
        
        Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
            param(
                [string[]]
                $ModuleName
            )

            $dscProcessID = Get-WmiObject msft_providers | 
                                Where-Object {$_.provider -like 'dsccore'} | 
                                Select-Object -ExpandProperty HostProcessIdentifier 
            Stop-Process -Id $dscProcessID -Force

            $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
            Get-ChildItem -Path $modulesRoot -Directory |
                Where-Object { $ModuleName -contains $_.Name } |
                Remove-Item -Recurse

        } -ArgumentList (,$ModuleName)
    }

    
    $win32OS = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_OperatingSystem'

    $results = Invoke-CimMethod -CimSession $CimSession `
                                -Namespace 'root/microsoft/windows/desiredstateconfiguration' `
                                -Class 'MSFT_DscLocalConfigurationManager' `
                                -MethodName 'PerformRequiredConfigurationChecks' `
                                -Arguments @{ 'Flags' = [uint32]1 } 

    $successfulComputers = $results | Where-Object { $_ -and $_.ReturnValue -eq 0 } | Select-Object -ExpandProperty 'PSComputerName'

    $CimSession | 
        Where-Object { $successfulComputers -notcontains $_.ComputerName } |
        ForEach-Object { 
            $session = $_
            $startedAt= $win32OS | Where-Object { $_.PSComputerName -eq $session.ComputerName } | Select-Object -ExpandProperty 'LocalDateTime'
            Get-CDscError -ComputerName $session.ComputerName -StartTime $startedAt -Wait 
        } | 
        Write-CDscError
}

