



function Set-RsDatabase
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $True)]
        [string]
        $DatabaseServerName,

        [switch]
        $IsRemoteDatabaseServer,

        [Parameter(Mandatory = $True)]
        [Alias('DatabaseName')]
        [string]
        $Name,

        [switch]
        $IsExistingDatabase,

        [Parameter(Mandatory = $true)]
        [Alias('Authentication')]
        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $DatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $DatabaseCredential,

        [Microsoft.ReportingServicesTools.SqlServerAuthenticationType]
        $AdminDatabaseCredentialType,

        [System.Management.Automation.PSCredential]
        $AdminDatabaseCredential,

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

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Configure to use $DatabaseServerName as database, using $DatabaseCredentialType runtime authentication and $AdminDatabaseCredentialType setup authentication"))
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
        

        
        $adminUsername = ''
        $adminPassword = $null

        
        $isSQLAdminAccount = ($AdminDatabaseCredentialType -like "SQL")

        
        if ($AdminDatabaseCredentialType -like 'serviceaccount')
        {
            throw "Can only use Admin Database Credentials Type of 'Windows' or 'SQL'"
        }

        
        if ($isSQLAdminAccount)
        {
            if ($AdminDatabaseCredential -eq $null)
            {
                throw "No Admin Database Credential specified! Admin Database credential must be specified when configuring $AdminDatabaseCredentialType authentication."
            }
            $adminUsername = $AdminDatabaseCredential.UserName
            $adminPassword = $AdminDatabaseCredential.GetNetworkCredential().Password
        }
        


        
        if (-not $IsExistingDatabase)
        {
            
            Write-Verbose "Generating database creation script..."
            $EnglishLocaleId = 1033
            $IsSharePointMode = $false
            $result = $rsWmiObject.GenerateDatabaseCreationScript($Name, $EnglishLocaleId, $IsSharePointMode)
            if ($result.HRESULT -ne 0)
            {
                Write-Verbose "Generating database creation script... Failed!"
                throw "Failed to generate the database creation script from the report server using WMI. Errorcode: $($result.HRESULT)"
            }
            else
            {
                $SQLScript = $result.Script
                Write-Verbose "Generating database creation script... Complete!"
            }

            
            Write-Verbose "Executing database creation script..."
            try
            {
                if ($isSQLAdminAccount)
                {
                    Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -ErrorAction Stop -Username $adminUsername -Password $adminPassword
                }
                else
                {
                    Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -ErrorAction Stop
                }
            }
            catch
            {
                Write-Verbose "Executing database creation script... Failed!"
                throw
            }
            Write-Verbose "Executing database creation script... Complete!"
        }
        

        
        
        Write-Verbose "Generating database rights script..."
        $isWindowsAccount = ($DatabaseCredentialType -like "Windows") -or ($DatabaseCredentialType -like "ServiceAccount")
        $result = $rsWmiObject.GenerateDatabaseRightsScript($username, $Name, $IsRemoteDatabaseServer, $isWindowsAccount)
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
            if ($isSQLAdminAccount)
            {
                Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -ErrorAction Stop -Username $adminUsername -Password $adminPassword
            }
            else
            {
                Invoke-Sqlcmd -ServerInstance $DatabaseServerName -Query $SQLScript -ErrorAction Stop
            }
        }
        catch
        {
            Write-Verbose "Executing database rights script... Failed!"
            throw
        }
        Write-Verbose "Executing database rights script... Complete!"
        

        
        
        Write-Verbose "Updating Reporting Services to connect to new database..."
        $result = $rsWmiObject.SetDatabaseConnection($DatabaseServerName, $Name, $DatabaseCredentialType.Value__, $username, $password)
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
