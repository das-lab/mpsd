











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Get-ExpectedIPAddress
{
    [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } | 
        ForEach-Object { $_.GetIPProperties() } | 
        Select-Object -ExpandProperty UnicastAddresses  | 
        Select-Object -ExpandProperty Address 
}

function Test-ShouldGetIPAddress
{
    $expectedIPAddress = Get-ExpectedIPAddress
    Assert-NotNull $expectedIPAddress

    $actualIPAddress = Get-IPAddress
    Assert-NotNull $actualIPAddress

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Test-ShouldGetIPv4Addresses
{
    [Object[]]$expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' }

    [Object[]]$actualIPAddress = Get-IPAddress -V4

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Test-ShouldGetIPv6Addresses
{
    [Object[]]$expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetworkV6' }
    if( -not $expectedIPAddress )
    {
        Write-Warning ('Unable to test if Get-IPAddress returns just IPv6 addresses: there are on IPv6 addresses on this computer.')
        return
    }

    [Object[]]$actualIPAddress = Get-IPAddress -V6

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Assert-IPAddress
{
    param(
        [IPAddress[]]
        $Expected,

        [IPAddress[]]
        $Actual
    )
    Assert-Equal $Expected.Length $Actual.Length 
    for( $idx = 0; $idx -lt $Expected.Length; ++$idx )
    {
        Assert-Equal $Expected[$idx] $Actual[$idx]
    }
}

