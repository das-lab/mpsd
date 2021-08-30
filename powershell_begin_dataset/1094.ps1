











if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WORKGROUP' )
{
    Write-Warning -Message ('Find-ADUser tests can''t run because this computer is not part of a domain.')
}
else
{
    $domainUrl = ''

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Setup
    {
        $domainController = Get-ADDomainController -Domain $env:USERDOMAIN
        Assert-NotNull $domainController
        $domainUrl = "LDAP://{0}:389" -f $domainController
    }

    function Test-ShouldFindUser
    {
        $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName $env:USERNAME
        Assert-NotNull $me
        Assert-Equal $env:USERNAME $me.sAMAccountName
    }

    function Test-ShouldEscapeSpecialCharacters
    {
        $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName "(user*with\special/characters)"
        Assert-Null $me
    }
}