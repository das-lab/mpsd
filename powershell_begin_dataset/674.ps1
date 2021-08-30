


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