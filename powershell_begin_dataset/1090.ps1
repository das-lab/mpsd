











Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

$RuleName = 'CarbonDscFirewallRule'

Start-CarbonDscTestFixture 'FirewallRule'

Describe 'Carbon_FirewallRule' {
    
    function Remove-FirewallRule
    {
        param(
            $Name = $RuleName
        )
    
        if( Get-FirewallRule -Name $Name )
        {
            netsh advfirewall firewall delete rule name=$Name
        }
    }
    
    function Get-FirewallRuleUnique
    {
        [OutputType([Carbon.Firewall.Rule])]
        param(
        )
    
        Get-FirewallRule | 
            Group-Object -Property 'Name' | 
            Sort-Object -Property 'Count' | 
            Where-Object { $_.Count -eq 1 } |
            Select-Object -First 1 |
            Select-Object -ExpandProperty 'Group'
    }
    
    BeforeAll {
    }
    
    BeforeEach {
        $Global:Error.Clear()
        Remove-FirewallRule
    }
    
    AfterEach {
        Remove-FirewallRule
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
    }
    
    
    It 'should set security and edge' {
        
        Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security AuthEnc -EdgeTraversalPolicy Yes -Ensure Present
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Name | Should Be $RuleName
        $rule.Direction | Should Be 'In'
        $rule.Action | Should Be 'Allow'
        netsh advfirewall firewall show rule "name=$RuleName" verbose | 
            Where-Object { $_ -match '\bAuthEnc\b' } |
            Should Not BeNullOrEmpty
        $rule.EdgeTraversalPolicy | Should Be 'Yes'
    
        Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security Authenticate -EdgeTraversalPolicy No -Ensure Present
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        netsh advfirewall firewall show rule "name=$RuleName" verbose | 
            Where-Object { $_ -match '\bAuthenticate\b' } |
            Should Not BeNullOrEmpty
        $rule.EdgeTraversalPolicy | Should Be 'No'
    }
    return
    It 'should require direction and action when adding new rule' {
        Set-TargetResource -Name $RuleName -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match '\bDirection\b.*\bAction\b'
        (Get-FirewallRule -Name $RuleName) | Should BeNullOrEmpty
    }
}

Describe 'Carbon_FirewallRule.when run as a DSC resource' {
    
    $Global:Error.Clear()

    configuration DscConfiguration
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_FirewallRule set
            {
                Name = $RuleName;
                Direction = 'In';
                Action = 'Allow';
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Name | Should Be $RuleName
        $rule.Direction | Should Be 'In'
        $rule.Action | Should Be 'Allow'
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should BeNullOrEmpty
    
        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_FirewallRule' } | Should Not BeNullOrEmpty
    }
}

Describe 'Carbon_FirewallRule.when run through DSC with multiple profiles' {

    $Global:Error.Clear()
    $RuleName = 'SupportMultiplePRofiles'
    configuration DscConfiguration
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_FirewallRule set
            {
                Name = $RuleName;
                Direction = 'In';
                Action = 'Allow';
                Profile = 'Public','Private'
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    }

    It 'should set multiple profiles' {
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Profile | Should Match '\bPublic\b'
        $rule.Profile | Should Match '\bPrivate\b'
    }

    It 'should remove the rule' {
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Get-FirewallRule -Name $RuleName | Should BeNullOrEmpty
    }

}
