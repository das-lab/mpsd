











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetUser
{
    Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $user = Get-WmiLocalUserAccount -Username $_.Name
        Assert-NotNull $user
        Assert-Equal $_.Name $user.Name
        Assert-Equal $_.FullName $user.FullName
        Assert-Equal $_.SID $user.SID
    }
}

