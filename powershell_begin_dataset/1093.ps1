











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldEscapeADSpecialCharacters
{
    $specialCharacters = "*()\`0/"
    $escapedCharacters = Format-ADSearchFilterValue -String $specialCharacters
    Assert-Equal '\2a\28\29\5c\00\2f' $escapedCharacters
}

