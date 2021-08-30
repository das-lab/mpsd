


Describe "Get-RsFolderContent" {
    Context "Get folder with ReportServerUri parameter"{
        
        $folderName = 'SutGetFolderReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        
        $reportServerUri = 'http://localhost/reportserver'
        
        $folderList = Get-RsFolderContent -ReportServerUri $reportServerUri -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Get folder with proxy parameter"{
        
        $folderName = 'SutGetFolderProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        
        $proxy = New-RsWebServiceProxy 
        
        $folderList = Get-RsFolderContent -Proxy $proxy -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false
    }

    Context "Get folder with Proxy and ReportServerUri parameter"{
        
        $folderName = 'SutGetFolderProxyAndReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        
        $proxy = New-RsWebServiceProxy 
        $reportServerUri = 'http://localhost/reportserver'
        
        $folderList = Get-RsFolderContent -Proxy $proxy -ReportServerUri $reportServerUri -RsFolder / 
        $folderCount = ($folderList | Where-Object name -eq $folderName).Count
        It "Should found a folder" {
            $folderCount | Should Be 1
        }
        
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $folderPath -Confirm:$false 
    }

    Context "Get folder inside 4 folders"{
        
        $sutRootFolder = 'SutGetFolderParent' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $sutRootFolder
        
        $currentFolderDepth = 2
        $folderParentName = $sutRootFolder
        While ($currentFolderDepth -le 5)
        {
            
            $folderParentPath +=  '/' + $folderParentName
            $folderParentName = 'SutGetFolderParent' + $currentFolderDepth 
            New-RsFolder -Path $folderParentPath -FolderName $folderParentName
            $currentFolderDepth +=1
            
        }
        
        $fifthFolderPath = $folderParentPath + '/' + $folderParentName
        $rootFolderPath = '/'  + $sutRootFolder 
        $folderList = Get-RsFolderContent -RsFolder $rootFolderPath -Recurse
        $folderCount = ($folderList | Where-Object path -eq $fifthFolderPath).Count
        It "Should found 4 subfolders" {
            $folderCount | Should Be 1
            $folderList.Count | Should be 4
        }
         
        Remove-RsCatalogItem -ReportServerUri 'http://localhost/reportserver' -RsFolder $rootFolderPath -Confirm:$false
    }
}