











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $expectedPath = $expectedPath -replace 'SysWOW64','sysnative'
    }
    Assert-Equal $expectedPath (Get-PowerShellPath)
}

function Test-ShouldGet32BitPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    if( Test-OSIs64Bit )
    {
        $expectedPath = $expectedPath -replace 'System32','SysWOW64'
    }
    
    Assert-Equal $expectedPath (Get-PowerShellPath -x86)
}

function Test-ShouldGet64BitPowerShellUnder32BitPowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $expectedPath = $PSHome -replace 'SysWOW64','sysnative'
        $expectedPath = Join-Path $expectedPath 'powershell.exe'
        Assert-Equal $expectedPath (Get-PowerShellPath)
    }
    else
    {
        Write-Warning 'This test is only valid if running 32-bit PowerShell on a 64-bit operating system.'
    }
}

function Test-ShouldGet32BitPowerShellUnder32BitPowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        Assert-Equal (Join-Path $PSHome 'powershell.exe') (Get-PowerShellPath -x86)
    }
    else
    {
        Write-Warning 'This test is only valid if running 32-bit PowerShell on a 64-bit operating system.'
    }
}


