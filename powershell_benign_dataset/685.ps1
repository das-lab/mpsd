


function Set-RsDatabaseCredentials
{
    
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Authentication')]
        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [switch]
        $IsRemoteDatabaseServer,

        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,

        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,

        [string]
        $ComputerName,

        [System.Management.Automation.PSCredential]
        $Credential,

        [int]
        $QueryTimeout = 30
    )

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Configure to use $DatabaseCredentialType authentication"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters

        
        $username = ''
        $password = $null
        if ($DatabaseCredentialType -like 'serviceaccount')
        {
            $username = $rsWmiObject.WindowsServiceIdentityActual
            $password = ''
        }

        else
        {
            if ($DatabaseCredential -eq $null)
            {
                throw "No Database Credential specified! Database credential must be specified when configuring $DatabaseCredentialType authentication."
            }
            $username = $DatabaseCredential.UserName
            $password = $DatabaseCredential.GetNetworkCredential().Password
        }
        

        $databaseName = $rsWmiObject.DatabaseName
        $databaseServerName = $rsWmiObject.DatabaseServerName

        
        
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($DatabaseCredentialType -like "Windows") -or ($DatabaseCredentialType -like "ServiceAccount")
        $result = $rsWmiObject.GenerateDatabaseRightsScript($username, $databaseName, $IsRemoteDatabaseServer, $isWindowsAccount)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Generating database rights script... Failed!"
            throw "Failed to generate the database rights script from the report server using WMI. Errorcode: $($result.HRESULT)"
        }
        else
        {
            $SQLscript = $result.Script
            Write-Verbose "Generating database rights script... Complete!"
        }

        
        Write-Verbose "Executing database rights script..."
        try
        {
            Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLscript -QueryTimeout $QueryTimeout -ErrorAction Stop
        }
        catch
        {
            Write-Verbose "Executing database rights script... Failed!"
            throw
        }
        Write-Verbose "Executing database rights script... Complete!"
        

        
        
        Write-Verbose "Updating Reporting Services to connect to new database..."
        $result = $rsWmiObject.SetDatabaseConnection($DatabaseServerName, $databaseName, $DatabaseCredentialType.Value__, $username, $password)
        if ($result.HRESULT -ne 0)
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Failed!"
            throw "Failed to update the reporting services to connect to the new database using WMI! Errorcode: $($result.HRESULT)"
        }
        else
        {
            Write-Verbose "Updating Reporting Services to connect to new database... Complete!"
        }
        
    }
}
