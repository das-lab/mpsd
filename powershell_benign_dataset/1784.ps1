

Describe "DSC MOF Compilation" -tags "CI" {

    AfterAll {
        $env:PSModulePath = $_modulePath
    }

    BeforeAll {
        $IsAlpine = (Get-PlatformInfo) -eq "alpine"
        Import-Module PSDesiredStateConfiguration
        $dscModule = Get-Module PSDesiredStateConfiguration
        $baseSchemaPath = Join-Path $dscModule.ModuleBase 'Configuration'
        $testResourceSchemaPath = Join-Path -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath assets) -ChildPath dsc) schema

        
        Copy-Item $testResourceSchemaPath $baseSchemaPath -Recurse -Force

        $_modulePath = $env:PSModulePath
        $powershellexe = (get-process -pid $PID).MainModule.FileName
        $env:PSModulePath = join-path ([io.path]::GetDirectoryName($powershellexe)) Modules
    }

    It "Should be able to compile a MOF from a basic configuration" -Skip:($IsMacOS -or $IsWindows -or $IsAlpine) {
        [Scriptblock]::Create(@"
        configuration DSCTestConfig
        {
            Import-DscResource -ModuleName PSDesiredStateConfiguration
            Node "localhost" {
                nxFile f1
                {
                    DestinationPath = "/tmp/file1";
                }
            }
        }

        DSCTestConfig -OutputPath TestDrive:\DscTestConfig1
"@) | Should -Not -Throw

        "TestDrive:\DscTestConfig1\localhost.mof" | Should -Exist
    }

    It "Should be able to compile a MOF from another basic configuration" -Skip:($IsMacOS -or $IsWindows -or $IsAlpine) {
        [Scriptblock]::Create(@"
        configuration DSCTestConfig
        {
            Import-DscResource -ModuleName PSDesiredStateConfiguration
            Node "localhost" {
                nxScript f1
                {
                    GetScript = "";
                    SetScript = "";
                    TestScript = "";
                    User = "root";
                }
            }
        }

        DSCTestConfig -OutputPath TestDrive:\DscTestConfig2
"@) | Should -Not -Throw

        "TestDrive:\DscTestConfig2\localhost.mof" | Should -Exist
    }

    It "Should be able to compile a MOF from a complex configuration" -Skip:($IsMacOS -or $IsWindows -or $IsAlpine) {
        [Scriptblock]::Create(@"
    Configuration WordPressServer{

                Import-DscResource -ModuleName PSDesiredStateConfiguration

        Node CentOS{

            
                nxPackage httpd {
                    Ensure = "Present"
                    Name = "httpd"
                    PackageManager = "yum"
                }

        
        nxFile vHostDir{
           DestinationPath = "/etc/httpd/conf.d/vhosts.conf"
           Ensure = "Present"
           Contents = "IncludeOptional /etc/httpd/sites-enabled/*.conf`n"
           Type = "File"
        }

        nxFile vHostDirectory{
            DestinationPath = "/etc/httpd/sites-enabled"
            Type = "Directory"
            Ensure = "Present"
        }

        
        nxFile wpHttpDir{
            DestinationPath = "/var/www/wordpress"
            Type = "Directory"
            Ensure = "Present"
            Mode = "755"
        }

        
        nxFile share{
            DestinationPath = "/mnt/share"
            Type = "Directory"
            Ensure = "Present"
            Mode = "755"
        }

        
        nxFile HttpdPort{
           DestinationPath = "/etc/httpd/conf.d/listen.conf"
           Ensure = "Present"
           Contents = "Listen 8080`n"
           Type = "File"
        }

        
        nxScript nfsMount{
            TestScript= "
            GetScript="
            SetScript="

        }

        
        nxFile WordPressTar{
            SourcePath = "/mnt/share/latest.zip"
            DestinationPath = "/tmp/wordpress.zip"
            Checksum = "md5"
            Type = "file"
            DependsOn = "[nxScript]nfsMount"
        }

        
        nxArchive ExtractSite{
            SourcePath = "/tmp/wordpress.zip"
            DestinationPath = "/var/www/wordpress"
            Ensure = "Present"
            DependsOn = "[nxFile]WordpressTar"
         }

         

         
         
            
            
            
         

         
         nxFileLine SELinux {
            Filepath = "/etc/selinux/config"
            DoesNotContainPattern = "SELINUX=enforcing"
            ContainsLine = "SELINUX=disabled"
         }

        nxScript SELinuxHTTPNet{
          GetScript = "
          setScript = "
          TestScript = "
        }

        }

    }
        WordPressServer -OutputPath TestDrive:\DscTestConfig3
"@) | Should -Not -Throw

        "TestDrive:\DscTestConfig3\CentOS.mof" | Should -Exist
    }

    It "Should be able to compile a MOF from a basic configuration on Windows" -Skip:($IsMacOS -or $IsLinux -or $IsAlpine) {
        [Scriptblock]::Create(@"
        configuration DSCTestConfig
        {
            Import-DscResource -ModuleName PSDesiredStateConfiguration
            Node "localhost" {
                File f1
                {
                    DestinationPath = "$env:SystemDrive\\Test.txt";
                    Ensure = "Present"
                }
            }
        }

        DSCTestConfig -OutputPath TestDrive:\DscTestConfig4
"@) | Should -Not -Throw

        "TestDrive:\DscTestConfig4\localhost.mof" | Should -Exist
    }

    It "Should be able to compile a MOF from a configuration with multiple resources on Windows" -Skip:($IsMacOS -or $IsLinux -or $IsAlpine) {
        [Scriptblock]::Create(@"
        configuration DSCTestConfig
        {
            Import-DscResource -ModuleName PSDesiredStateConfiguration
            Node "localhost" {
                File f1
                {
                    DestinationPath = "$env:SystemDrive\\Test.txt";
                    Ensure = "Present"
                }
                Script s1
                {
                    GetScript = {return @{}}
                    SetScript = "Write-Verbose Hello"
                    TestScript = {return $false}
                }
                Log l1
                {
                    Message = "This is a log message"
                }
            }
        }

        DSCTestConfig -OutputPath TestDrive:\DscTestConfig5
"@) | Should -Not -Throw

        "TestDrive:\DscTestConfig5\localhost.mof" | Should -Exist
    }
}
