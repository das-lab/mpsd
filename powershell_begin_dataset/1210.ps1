











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldTestExistingIPV4Address
{
    Get-IPAddress -V4 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_) }
}

function Test-ShouldTestExistingIPV4String
{
    Get-IPAddress -V4 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_.ToString()) }
}

function Test-ShouldTestNonExistentIPV4Address
{
    Assert-False (Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('255.255.255.0')))
}

function Test-ShouldTestNonExistentIPV4String
{
    Assert-False (Test-IPAddress -IPAddress '255.255.255.0')
}


function Test-ShouldHandleExistentIPV6Address
{
    Get-IPAddress -V6 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_ ) }
}

function Test-ShouldHandleExistentIPV6String
{
    Get-IPAddress -V6 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_.ToString() ) }
}

function Test-ShouldHandleNonExistentIP6Address
{
    Assert-False (Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('::1')))
}

function Test-ShouldHandleNonExistentIPV6String
{
    Assert-False (Test-IPAddress -IPAddress '::1')
}

