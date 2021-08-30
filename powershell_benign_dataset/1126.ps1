











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve) -ForDsc

Describe 'Carbon_Group' {


    $groupName = 'CarbonGroupTest'
    $username1 = $CarbonTestUser.UserName
    $username2 = 'CarbonTestUser2'
    $username3 = 'CarbonTestUser3'
    $user1 = $null
    $user2 = $null
    $user3 = $null
    $description = 'Group for testing Carbon''s Group DSC resource.'

    Start-CarbonDscTestFixture 'Group'
    $user1 = Resolve-CIdentity -Name $CarbonTestUser.UserName
    $user2 = Install-User -Credential (New-Credential -UserName $username2 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    $user3 = Install-User -Credential (New-Credential -UserName $username3 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    Install-Group -Name $groupName -Description $description -Member $username1,$username2

    try
    {    
    
        BeforeEach {
            $Global:Error.Clear()
        }
            
        It 'get target resource' {
            $admins = Get-Group 'Administrators'
    
            $groupName = 'Administrators'
            $resource = Get-TargetResource -Name $groupName
            $resource | Should Not BeNullOrEmpty
            $groupName | Should Be $resource.Name
            $resource.Description | Should Be $admins.Description
            Assert-DscResourcePresent $resource
    
            $resource.Members.Count | Should Be $admins.Members.Count
    
            foreach( $admin in $admins.Members )
            {
                $found = $false
                foreach( $potentialAdmin in $resource.Members )
                {
                    if( $potentialAdmin.Sid -eq $admin.Sid )
                    {
                        $found = $true
                        break
                    }
                }
                $found | Should Be $true
            }
        }
    
        It 'get target resource does not exist' {
            $resource = Get-TargetResource -Name 'fubarsnafu'
            $resource | Should Not BeNullOrEmpty
            $resource.Name | Should Be 'fubarsnafu'
            $resource.Description | Should BeNullOrEmpty
            $resource.Members | Should BeNullOrEmpty
            Assert-DscResourceAbsent $resource
        }
    
        It 'test target resource' {
    
            $result = Test-TargetResource -Name $groupName -Description $description -Members ($username1,$username2)
            $result | Should Not BeNullOrEmpty
            $result | Should Be $true
    
            $result = Test-TargetResource -Name $groupName -Ensure Absent
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            
            $result = Test-TargetResource -Name $groupName
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            $result = Test-TargetResource -Name $groupName -Members ($username1,$username2) -Description $description
            $result | Should Not BeNullOrEmpty
            $result | Should Be $true
    
            
            $result = Test-TargetResource -Name $groupName -Members ($username1) -Description $description
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            
            $result = Test-TargetResource -Name $groupName -Members ($username1,$username2,$username3) -Description $description
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            
            $result = Test-TargetResource -Name $groupName -Members ($username1,$username2) -Description 'a new description'
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            
            $result = Test-TargetResource -Name $groupName -Members $username1,$username2 -Ensure Absent
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
    
            
            $result = Test-TargetResource -Name $groupName -Description $description -Ensure Absent
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false
        }
    
        It 'set target resource' {
            $VerbosePreference = 'Continue'
    
            $groupName = 'TestCarbonGroup01'
    
            
            Set-TargetResource -Name $groupName -Ensure 'Present'
        
            $group = Get-Group -Name $groupName
            $group | Should Not BeNullOrEmpty
            $group.Name | Should Be $groupName
            $group.Description | Should BeNullOrEmpty
            $group.Members.Count | Should Be 0
    
            
            Set-TargetResource -Name $groupName -Members $username1 -Ensure 'Present'
            $group = Get-Group -Name $groupName
            $group | Should Not BeNullOrEmpty
            $group.Name | Should Be $groupName
            $group.Description | Should BeNullOrEmpty
            $group.Members.Count | Should Be 1
            $group.Members[0].Sid | Should Be $user1.Sid
    
            
            Set-TargetResource -Name $groupName -Members $username1 -Description 'group description' -Ensure 'Present'
        
            $group = Get-Group -Name $groupName
            $group | Should Not BeNullOrEmpty
            $group.Name | Should Be $groupName
            $group.Description | Should Be 'group description'
            $group.Members.Count | Should Be 1
            $group.Members[0].Sid | Should Be $user1.Sid
        
            
            Set-TargetResource -Name $groupName -Members $username1,$username2 -Description 'group description' -Ensure 'Present'
            $group = Get-Group -Name $groupName
            $group | Should Not BeNullOrEmpty
            $group.Name | Should Be $groupName
            $group.Description | Should Be 'group description'
            $group.Members.Count | Should Be 2
            ($group.Members.Sid -contains $user1.Sid) | Should Be $true
            ($group.Members.Sid -contains $user2.Sid) | Should Be $true
    
            
            Set-TargetResource -Name $groupName -Description 'new description' -WhatIf
            $group = Get-Group -Name $groupName
            $group.Description | Should Be 'group description'
    
            
            Set-TargetResource -Name $groupName -Description 'group description' -WhatIf
            $group = Get-Group -Name $groupName
            $group.Members.Count | Should Be 2
    
            
            Set-TargetResource -Name $groupName -Ensure 'Present'
            $group = Get-Group -Name $groupName
            $group | Should Not BeNullOrEmpty
            $group.Name | Should Be $groupName
            $group.Description | Should BeNullOrEmpty
            $group.Members.Count | Should Be 0
    
            
            Set-TargetResource -Name $groupName -Ensure Absent -WhatIf
            (Test-Group -Name $groupName) | Should Be $true
    
            
            Set-TargetResource -Name $groupName -Ensure 'Absent'
            (Test-Group -Name $groupName) | Should Be $false
        }
    
        Configuration ShouldCreateGroup
        {
            param(
                $Ensure
            )
    
            Set-StrictMode -Off
    
            Import-DscResource -Name '*' -Module 'Carbon'
    
            node 'localhost'
            {
                Carbon_Group CarbonTestGroup
                {
                    Name = 'CDscGroup1'
                    Description = 'Carbon_Group DSC resource test group'
                    Members = @( $username1 )
                    Ensure = $Ensure
                }
            }
        }
    
        It 'should run through dsc' {
            $groupName = 'CDscGroup1'
    
            
            & ShouldCreateGroup -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
            Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
            $Global:Error.Count | Should Be 0
    
            $result = Test-TargetResource -Name $groupName -Description 'Carbon_Group DSC resource test group' -Members $username1
            $result | Should Not BeNullOrEmpty
            $result | Should Be $true
    
            
            & ShouldCreateGroup -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
            Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
            $Global:Error.Count | Should Be 0
    
            $result = Test-TargetResource -Name $groupName
            $result | Should Not BeNullOrEmpty
            $result | Should Be $false

            $result = Get-DscConfiguration
            $Global:Error.Count | Should Be 0
            $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
            $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Group' } | Should Not BeNullOrEmpty
        }
    }
    finally
    {
        Stop-CarbonDscTestFixture
    }
}
