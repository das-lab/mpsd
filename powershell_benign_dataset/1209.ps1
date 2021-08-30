











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$GroupName = 'Setup Group'
$userName = $CarbonTestUser.UserName
$description = 'Carbon user for use in Carbon tests.'

function Assert-GroupExists
{
    $groups = Get-Group
    try
    {
        $group = $groups |
                    Where-Object { $_.Name -eq $GroupName }
        $group | Should -Not -BeNullOrEmpty
    }
    finally
    {
        $groups | ForEach-Object { $_.Dispose() }
    }
}

Describe 'Install-Group' {
    BeforeEach {
        Remove-Group
    }
    
    AfterEach {
        Remove-Group
    }
    
    function Remove-Group
    {
        $groups = Get-Group 
        try
        {
            $group = $groups | Where-Object { $_.Name -eq $GroupName }
            if( $null -ne $group )
            {
                net localgroup `"$GroupName`" /delete
            }
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }
    
    function Invoke-NewGroup($Description = '', $Members = @())
    {
        $group = Install-Group -Name $GroupName -Description $Description -Members $Members -PassThru
        try
        {
            $group | Should -Not -BeNullOrEmpty
            Assert-GroupExists
            $expectedGroup = Get-Group -Name $GroupName
            try
            {
                $expectedGroup.Sid | Should -Be $group.Sid
            }
            finally
            {
                $expectedGroup.Dispose()
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
    
    It 'should create group' {
        $expectedDescription = 'Hello, wordl!'
        Invoke-NewGroup -Description $expectedDescription
        $group = Get-Group -Name $GroupName
        try
        {
            $group | Should -Not -BeNullOrEmpty
            $group.Name | Should -Be $GroupName
            $group.Description | Should -Be $expectedDescription
        }
        finally
        {
            $group.Dispose()
        }
    }
    
    It 'should pass thru group' {
        $group = Install-Group -Name $GroupName 
        try
        {
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    
        $group = Install-Group -Name $GroupName -PassThru
        try
        {
            $group | Should -Not -BeNullOrEmpty
            $group | Should -BeOfType ([DirectoryServices.AccountManagement.GroupPrincipal])
        }
        finally
        {
            $group.Dispose()
        }
    }
    
    It 'should add members' {
        Invoke-NewGroup -Members $userName
        
        $details = net localgroup `"$GroupName`"
        $details | Where-Object { $_ -like ('*{0}*' -f $userName) } | Should -Not -BeNullOrEmpty
    }
    
    It 'Should -Not recreate if group already exists' {
        Invoke-NewGroup -Description 'Description 1'
        $group1 = Get-Group -Name $GroupName
        try
        {
        
            Invoke-NewGroup -Description 'Description 2'
            $group2 = Get-Group -Name $GroupName
            
            try
            {
                $group2.Description | Should -Be 'Description 2'
                $group2.SID | Should -Be $group1.SID
            }
            finally
            {
                $group2.Dispose()
            }
        }
        finally
        {
            $group1.Dispose()
        }    
    }
    
    It 'Should -Not add member multiple times' {
        Invoke-NewGroup -Members $userName
        
        $Error.Clear()
        Invoke-NewGroup -Members $userName
        $Error.Count | Should -Be 0
    }
    
    It 'should add member with long name' {
        $longUsername = 'abcdefghijklmnopqrst' 
        Install-User -Credential (New-Credential -Username $longUsername -Password 'a1b2c34d!')
        try
        {
            Invoke-NewGroup -Members ('{0}\{1}' -f $env:COMPUTERNAME,$longUsername)
            $details = net localgroup `"$GroupName`"
            $details | Where-Object { $_ -like ('*{0}*' -f $longUsername) }| Should -Not -BeNullOrEmpty
        }
        finally
        {
            Uninstall-User -Username $userName
        }
    }
    
    It 'should support what if' {
        $Error.Clear()
        $group = Install-Group -Name $GroupName -WhatIf -Member 'Administrator'
        try
        {
            $Global:Error.Count | Should -Be 0
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    
        $group = Get-Group -Name $GroupName -ErrorAction SilentlyContinue
        try
        {
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    }
}
