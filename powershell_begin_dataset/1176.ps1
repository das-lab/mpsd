











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-User' {
    It 'should get all users' {
        $users = Get-User
        try
        {
            $users | Should -Not -BeNullOrEmpty
            $users.Length | Should -BeGreaterThan 0
            
        }
        finally
        {
            $users | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should get one user' {
        Get-User |
            ForEach-Object { 
                $expectedUser = $_
                try
                {
                    $user = Get-User -Username $expectedUser.SamAccountName
                    try
                    {
                        $user | Should -HaveCount 1
                        $user.Sid | Should -Be $expectedUser.Sid
                    }
                    finally
                    {
                        if( $user )
                        {
                            $user.Dispose()
                        }
                    }
                }
                finally
                {
                    $expectedUser.Dispose()
                }
            }
    }
    
    It 'should error if user not found' {
        $Error.Clear()
        $user = Get-User -Username 'fjksdjfkldj' -ErrorAction SilentlyContinue
        $user | Should -BeNullOrEmpty
        $Error.Count | Should -Be 1
        $Error[0].Exception.Message | Should -BeLike '*not found*'
    }

    It 'should get users if WhatIfPreference is true' {
        $WhatIfPreference = $true
        $users = Get-CUser 
        $users | Should -Not -BeNullOrEmpty
        $users | 
            Select-Object -First 1 | 
            ForEach-Object { Get-CUser -UserName $_.SamAccountName } | 
            Should -Not -BeNullOrEmpty
    }
}
