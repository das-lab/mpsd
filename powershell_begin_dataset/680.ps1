


Describe "New-RsFolder" {
    Context "Create Folder with minimum parameters"{
        $folderName = 'SutFolderMinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        $folderPath = '/' + $folderName
        It "Should be a new folder" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create Folder with hidden parameter"{
        $folderName = 'SutFolderHidden' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -Hidden
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        $folderPath = '/' + $folderName
        It "Should be a new folder" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create Folder with Description"{
        $folderName = 'SutFolderDescription' + [guid]::NewGuid()
        $folderDescription = "$folderName Test Description"
        New-RsFolder -Path / -FolderName $folderName -Description $folderDescription
        $folderList = Get-RsFolderContent -RsFolder /
        $folderDescriptionValue = ($folderList | Where-Object name -eq $folderName).Description
        $folderPath = '/' + $folderName
        It "Should be a new folder with description " {
            $folderDescriptionValue | Should Be $folderDescription
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create a subfolder"{
        
        $parentFolderName = 'SutParentFolder' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $parentFolderName
        $folderPath = '/'+ $parentFolderName
        
        $folderList = Get-RsFolderContent -RsFolder /
        $parentfolderCount = ($folderList | Where-Object path -eq $folderPath).Count
        
        $subFolderName = 'SutSubFolder' + [guid]::NewGuid()
        New-RsFolder -Path $folderPath -FolderName $subFolderName
        
        $allFolderList = Get-RsFolderContent -RsFolder / -Recurse
        $subFolderPath = $folderPath + '/' + $subFolderName
        $subFolderCount = ($allFolderList | Where-Object path -eq $subFolderPath).Count
        It "Should the parent folder"{
            $parentFolderCount | Should be 1
        }
        It "Should the subfolder"{
            $subFolderCount | Should be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

     Context "Create a folder with proxy"{
        
        $folderName = 'SutFolderParameterProxy' + [guid]::NewGuid()
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        
        New-RsFolder -Path / -FolderName $folderName -Proxy $proxy
        
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with the parameter proxy"{
            $folderCount | Should be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create a folder with ReportServerUri"{
        
        $folderName = 'SutFolderParameterReportServerUri' + [guid]::NewGuid()
        $folderPath = '/'  + $folderName
        $folderReportServerUri = 'http://localhost/reportserver'
        
        New-RsFolder -ReportServerUri $folderReportServerUri -Path / -FolderName $folderName
        
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with the parameter ReportServerUri" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Create a folder with all the parameters except credentials"{
        
        $folderName = 'SutFolderAllParameters' + [guid]::NewGuid()
        $folderPath = '/'  + $folderName
        $folderReportServerUri = 'http://localhost/reportserver'
        $proxy = New-RsWebServiceProxy
        
        New-RsFolder -ReportServerUri $folderReportServerUri -Path / -FolderName $folderName -Proxy $proxy
        
        $folderList = Get-RsFolderContent -RsFolder /
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should be a new folder with all parameters except credentials" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }
}