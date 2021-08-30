











$alreadyEnabled = $false

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $alreadyEnabled = Test-FirewallStatefulFtp
    
    if( $alreadyEnabled )
    {
        Disable-FirewallStatefulFtp
    }
}

function Stop-Test
{
    if( $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
    }
    else
    {
        Disable-FirewallStatefulFtp
    }
}

function Test-ShouldEnableStatefulFtp
{
    Enable-FirewallStatefulFtp
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFtp not enabled on firewall.'
}

function Test-ShouldSupportWhatIf
{
    Enable-FirewallStatefulFtp -WhatIf
    $enabled = Test-FirewallStatefulFtp
    Assert-False $enabled 'StatefulFTP enabled with -WhatIf parameter given.'
}

