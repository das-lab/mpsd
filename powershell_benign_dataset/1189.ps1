











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ComPermission' {
    It 'should get com access permissions' {
        $rules = Get-ComPermission -Access -Default
        $rules | Should -Not -BeNullOrEmpty
        $rules.Count | Should -BeGreaterThan 1
        $rules | ForEach-Object { 
            $_.IdentityReference | Should -Not -BeNullOrEmpty
            $_.ComAccessRights | Should -Not -BeNullOrEmpty
            $_.AccessControlType | Should -Not -BeNullOrEmpty
            $_.IsInherited | Should -Be $false
            $_.InheritanceFlags | Should -Be 'None'
            $_.PropagationFlags | Should -Be 'None'
         }
    }
    
    It 'should get permissions for specific user' {
        $rules = Get-ComPermission -Access -Default
        $rules.Count | Should -BeGreaterThan 1
        $rule = Get-ComPermission -Access -Default -Identity $rules[0].IdentityReference.Value
        $rule | Should -Not -BeNullOrEmpty
        $rules[0].IdentityReference | Should -Be $rule.IdentityReference
    }
}

Describe 'Get-ComPermission.when getting security limits' {
    It 'should get security limits' {
        $defaultRules = Get-ComPermission -Access -Default
        $defaultRules | Should -Not -BeNullOrEmpty
        
        $limitRules = Get-ComPermission -Access -Limits
        $limitRules | Should -Not -BeNullOrEmpty
        
        if( $defaultRules.Count -eq $limitRules.Count )
        {
            for( $idx = 0; $idx -lt $limitRules.Count; $idx++ )
            {
                $limitRules[$idx] | Should -Not -Be $defaultRules[$idx]
            }
        }    
    }
}

Describe 'Get-ComPermission.2' {
    
    It 'should get com launch and activation permissions' {
        $rules = Get-ComPermission -LaunchAndActivation -Default
        $rules | Should -Not -BeNullOrEmpty
        ($rules.Count -gt 1) | Should -Be $true
        $rules | ForEach-Object { 
            $_.IdentityReference | Should -Not -BeNullOrEmpty
            $_.ComAccessRights | Should -Not -BeNullOrEmpty
            $_.AccessControlType | Should -Not -BeNullOrEmpty
            $_.IsInherited | Should -Be $false
            $_.InheritanceFlags | Should -Be 'None'
            $_.PropagationFlags | Should -Be 'None'
         }
    }
    
    It 'should get launch and activation rule for specific user' {
        $rules = Get-ComPermission -LaunchAndActivation -Default
        $rules.Count | Should -BeGreaterThan 1
        $rule = Get-ComPermission -LaunchAndActivation -Default -Identity $rules[0].IdentityReference.Value
        $rule | Should -Not -BeNullOrEmpty
        $rules[0].IdentityReference | Should -Be $rule.IdentityReference
    }
    
    It 'should get launch and activation security limits' {
        $defaultRules = Get-ComPermission -LaunchAndActivation -Default
        $defaultRules | Should -Not -BeNullOrEmpty
        
        $limitRules = Get-ComPermission -LaunchAndActivation -Limits
        $limitRules | Should -Not -BeNullOrEmpty
        
        if( $defaultRules.Count -eq $limitRules.Count )
        {
            for( $idx = 0; $idx -lt $limitRules.Count; $idx++ )
            {
                $limitRules[$idx] | Should -Not -Be $defaultRules[$idx]
            }
        }    
    }
    
}
