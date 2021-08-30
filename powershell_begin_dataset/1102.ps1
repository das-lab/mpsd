











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetIISVersion
{
    $props = get-itemproperty hklm:\Software\Microsoft\InetStp
    $expectedVersion = $props.MajorVersion.ToString() + '.' + $props.MinorVersion.ToString()
    $actualVersion = Get-IISVersion
    Assert-Equal $expectedVersion $actualVersion "Didn't get the correct IIS version."
}

