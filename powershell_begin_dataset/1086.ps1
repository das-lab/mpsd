











& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-FirewallRule.when getting all rules' {
    It 'should get firewall rules' {
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule
        $rules | Should -Not -BeNullOrEmpty
        
        $expectedCount = netsh advfirewall firewall show rule name=all verbose |
                            Where-Object { $_ -like 'Rule Name:*' } |
                            Measure-Object |
                            Select-Object -ExpandProperty 'Count'
        $rules.Count | Should -Be $expectedCount
    }
 }

 Describe 'Get-FirewallRule.when getting a specific rule' {
    It 'should get firewall rule' {
        Get-FirewallRule | 
            Select-Object -First 1 | 
            ForEach-Object {
                $rule = $_
                $actualRule = Get-FirewallRule -Name $rule.Name | ForEach-Object {
                    $actualRule = $_
    
                    $actualRule | Should -Not -BeNullOrEmpty
                    $actualRule.Name | Should -Be $rule.Name
            }
        }
    }
}

Describe 'Get-FirewallRule.when getting a specific rule with a wildcard pattern' {
    It 'should support wildcard firewall rule' {
        [Carbon.Firewall.Rule[]]$allRules = Get-FirewallRule
        $allRules | Should -Not -BeNullOrEmpty
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule -Name '*HTTP*' 
        $rules | Should -Not -BeNullOrEmpty
        $rules.Length | Should -BeLessThan $allRules.Length
        $expectedCount = netsh advfirewall firewall show rule name=all | Where-Object { $_ -like 'Rule Name*HTTP*' } | Measure-Object | Select-Object -ExpandProperty 'Count'
        $rules.Length | Should -Be $expectedCount
    }
 }

 Describe 'Get-FirewallRule.when getting a specific rule with a literal name' {
    It 'should support literal name' {
        $rules = Get-FirewallRule -LiteralName '*HTTP*'
        $rules | Should -BeNullOrEmpty
    }
}
