











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-Group' {
    It 'should get all groups' {
        $groups = Get-Group
        try
        {
            $groups | Should -Not -BeNullOrEmpty
            $groups.Length | Should -BeGreaterThan 0
            
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should get one group' {
        Get-Group |
            ForEach-Object { 
                $expectedGroup = $_
                try
                {
                    $group = Get-Group -Name $expectedGroup.Name
                    try
                    {
                        $group | Should -HaveCount 1
                        $group.Sid | Should -Be $expectedGroup.Sid
                    }
                    finally
                    {
                        if( $group )
                        {
                            $group.Dispose()
                        }
                    }
                }
                finally
                {
                    $expectedGroup.Dispose()
                }
            }
    }
    
    It 'should error if group not found' {
        $Error.Clear()
        $group = Get-Group -Name 'fjksdjfkldj' -ErrorAction SilentlyContinue
        $group | Should -BeNullOrEmpty
        $Error.Count | Should -Be 1
        $Error[0].Exception.Message | Should -BeLike '*not found*'
    }

    It 'should get groups if WhatIfPreference is true' {
        $WhatIfPreference = $true
        $groups = Get-CGroup 
        $groups | Should -Not -BeNullOrEmpty
        $groups | 
            Select-Object -First 1 | 
            ForEach-Object { Get-CGroup -Name $_.Name } | 
            Should -Not -BeNullOrEmpty
    }
}
