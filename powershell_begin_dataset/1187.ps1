











$alreadyEnabled = $false

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $alreadyEnabled = Test-FirewallStatefulFtp
    
    if( -not $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
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

function Test-ShouldDisableStatefulFtp
{
    Disable-FirewallStatefulFtp
    $enabled = Test-FirewallStatefulFtp
    Assert-False $enabled 'StatefulFtp not enabled on firewall.'
}

function Test-ShouldSupportWhatIf
{
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP not enabled'
    Disable-FirewallStatefulFtp -WhatIf
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP disable with -WhatIf parameter given.'
}

