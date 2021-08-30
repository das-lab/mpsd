











& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)


if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

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

    function Test-ShouldAddNewHost
    {
        Add-TrustedHost -Entries example.com 
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal 1 $trustedHosts.Count
    }

    function Test-ShouldAddMultipleHosts
    {
        Add-TrustedHost -Entry example.com,webmd.com
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-True ($trustedHosts -contains 'webmd.com')
        Assert-Equal 2 $trustedHosts.Count
    }

    function Test-ShouldNotDuplicateEntries
    {
        Add-TrustedHost -Entry example.com
        Add-TrustedHost -Entry example.com
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal 1 $trustedHosts.Count
    }
    
    function Test-ShouldSupportWhatIf
    {
        $preTrustedHosts = @( Get-TrustedHost )
        Add-TrustedHost -Entry example.com -WhatIf
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -notcontains 'example.com')
        Assert-Equal $preTrustedHosts.Count $trustedHosts.Count
        
    }
}

