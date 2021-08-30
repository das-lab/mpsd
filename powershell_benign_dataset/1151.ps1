











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$svcName = 'Windows Firewall'
if( -not (Get-Service -Name $svcName -ErrorAction Ignore) )
{
    $svcName = 'Windows Defender Firewall'
}

if( -not (Get-Service -Name $svcName -ErrorAction Ignore) )
{
    Describe 'Assert-FirewallConfigurable' {
        It 'should have a firewall service' {
            $false | Should -BeTrue -Because ('unable to find the firewall service')
        }
    }
    return
}

Describe 'Assert-FirewallConfigurable' {
    It 'should detect when serivce is configurable' {
        $firewallSvc = Get-Service -Name $svcName
        $firewallSvc | Should -Not -BeNullOrEmpty
        $error.Clear()
        if( $firewallSvc.Status -eq 'Running' )
        {
            $result = Assert-FirewallConfigurable
            $result | Should -Be $true
            $error.Count | Should -Be 0
        }
        else
        {
            Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is configurable: the firewall service is not running."
        }
    }
    
    It 'should detect when serivce is not configurable' {
        $firewallSvc = Get-Service -Name $svcName
        $firewallSvc | Should -Not -BeNullOrEmpty
        $error.Clear()
        if( $firewallSvc.Status -eq 'Running' )
        {
            Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is not configurable: the firewall service is running."
        }
        else
        {
            $result = Assert-FirewallConfigurable -ErrorAction SilentlyContinue
            $result | Should -Be $false
            $error.Count | Should -Be 1
        }
    }
    
}
