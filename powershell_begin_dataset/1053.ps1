












if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Start-Test
    {
        $originalTrustedHosts = @( Get-TrustedHost )
        Clear-TrustedHost
    }

    function Stop-Test
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHost -Entry $originalTrustedHosts
        }
    }

    function Test-ShouldSetTrustedHosts
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Set-TrustedHost 'example.com','sub.example.com'
        $hosts = @( Get-TrustedHost )
        Assert-Equal 'example.com' $hosts[0]
        Assert-Equal 'sub.example.com' $hosts[1]
    }

    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Set-TrustedHost 'badexample.com' -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHost)
    }
}

