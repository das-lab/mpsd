


Function Get-ExistingDataExtension
{
    $proxy = New-RsWebServiceProxy
    return $proxy.ListExtensions("Data")[0].Name
}

Describe "Get-RsDataSource" { 

    Context "Get RsDataSource with ReportServerUri parameter"{
        $dataSourceName = 'SutGetDataSourceReportServerUri' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        $dataSource = Get-RsDataSource -Path $dataSourcePath -ReportServerUri $reportServerUri
        It "Should get a RsDataSource" {
            $dataSource.Count | Should Be 1
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Get RsDataSource with Proxy parameter"{
        $dataSourceName = 'SutGetDataSourceProxy' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        
        $dataSourcePath = '/' + $dataSourceName
        $proxy = New-RsWebServiceProxy 
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval 
        $dataSource = Get-RsDataSource -Path $dataSourcePath -Proxy $proxy
        It "Should get a RsDataSource" {
            $dataSource.Count | Should Be 1
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }

    Context "Get RsDataSource with Proxy y ReportServerUri parameters"{
        $dataSourceName = 'SutGetDataSourceProxyAndReporServerUri' + [guid]::NewGuid()
        $extension = Get-ExistingDataExtension
        $credentialRetrieval = 'None'
        
        $dataSourcePath = '/' + $dataSourceName
        $reportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy 
        
        New-RsDataSource -RsFolder '/' -Name $dataSourceName -Extension $extension -CredentialRetrieval $credentialRetrieval
        $dataSource = Get-RsDataSource -Path $dataSourcePath -Proxy $proxy -ReportServerUri $reportServerUri
        It "Should get a RsDataSource" {
            $dataSource.Count | Should Be 1
        }
        
        Remove-RsCatalogItem -RsFolder $dataSourcePath -Confirm:$false
    }
}