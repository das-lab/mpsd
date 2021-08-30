











& (Join-Path $TestDir ..\Initialize-CarbonTest.ps1 -Resolve)


if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

    function Start-Test
    {
        $originalTrustedHosts = @( Get-TrustedHost )
    }

    function Stop-Test
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHost -Entry $originalTrustedHosts
        }
    }

    function Test-ShouldRemoveTrustedHosts
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost
        Assert-Null (Get-TrustedHost)
    }
    
    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHost)
    }
    
        
}
else
{
    Write-Warning "Only Administrators can modify the trusted hosts list."
}

