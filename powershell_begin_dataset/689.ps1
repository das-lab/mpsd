


function Restore-RSEncryptionKey
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $Password,

        [Parameter(Mandatory = $True)]
        [string]
        $KeyPath,

        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,

        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,

        [string]
        $ComputerName,

        [System.Management.Automation.PSCredential]
        $Credential
    )

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Restore encryptionkey from file $KeyPath"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters

        $KeyPath = Resolve-Path $KeyPath

        $reportServerService = 'ReportServer'

        if ($rsWmiObject.InstanceName -ne "MSSQLSERVER")
        {
            if($rsWmiObject.InstanceName -eq "PBIRS")
            {
                $reportServerService = 'PowerBIReportServer'
            }
            else
            {
                $reportServerService = $reportServerService + '$' + $rsWmiObject.InstanceName
            }
        }

        Write-Verbose "Checking if key file path is valid..."
        if (-not (Test-Path $KeyPath))
        {
            throw "No key was found at the specified location: $path"
        }

        try
        {
            $keyBytes = [System.IO.File]::ReadAllBytes($KeyPath)
        }
        catch
        {
            throw
        }

        Write-Verbose "Restoring encryption key..."
        $restoreKeyResult = $rsWmiObject.RestoreEncryptionKey($keyBytes, $keyBytes.Length, $Password)

        if ($restoreKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Success!"
        }
        else
        {
            throw "Failed to restore the encryption key! Errors: $($restoreKeyResult.ExtendedErrors)"
        }

        try
        {
            
            
            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $getServiceParams = @{
                    Class        = 'Win32_Service'
                    Filter       = "Name = '$reportServerService'"
                    ComputerName = $rsWmiObject.PSComputerName
                    Credential   = $Credential
                }
                $service = Get-WmiObject @getServiceParams

                Write-Verbose "Stopping Reporting Services Service... $reportServerService"
                $null = $service.StopService()
                do {
                    $service = Get-WmiObject @getServiceParams
                    Start-Sleep -Seconds 1
                } until ($service.State -eq 'Stopped')

                Write-Verbose "Starting Reporting Services Service... $reportServerService"
                $null = $service.StartService()
                do {
                    $service = Get-WmiObject @getServiceParams
                    Start-Sleep -Seconds 1
                } until ($service.State -eq 'Running')
            }
            else
            {
                $service = Get-Service -Name $reportServerService -ComputerName $rsWmiObject.PSComputerName -ErrorAction Stop
                Write-Verbose "Stopping Reporting Services Service... $reportServerService"
                $service.Stop()
                $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped)

                Write-Verbose "Starting Reporting Services Service... $reportServerService"
                $service.Start()
                $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running)
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to restart Report Server database service. Manually restart it for the change to take effect! $($_.Exception.Message)", $_.Exception))
        }
    }
}
