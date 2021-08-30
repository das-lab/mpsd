











if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WORKGROUP' )
{
    Write-Warning -Message ('Get-ADDomainController tests can''t run because this computer is not part of a domain.')
}
else
{
    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Test-ShouldFindDomainController
    {
        $domainController = Get-ADDomainController
        
        Assert-NotNull $domainController
        
        Assert-CanFindCurrentUser $domainController
        
    }

    function Test-ShouldFindDomainControllerForSpecificDomain
    {
        $domainController = Get-ADDomainController -Domain $env:USERDOMAIN
        
        Assert-NotNull $domainController
        
        Assert-CanFindCurrentUser $domainController
    }

    function Test-ShouldNotFindNonExistentDomain
    {
        $error.Clear()
        $domainController = Get-ADDomainController -Domain 'FJDSKLJDSKLFJSDA' -ErrorAction SilentlyContinue
        Assert-Null $domainController
        Assert-equal 2 $error.Count
    }

    function Assert-CanFindCurrentUser($domainController)
    {
        $domain = [adsi] "LDAP://$domainController"
        $searcher = [adsisearcher] $domain
        
        $searcher.Filter = "(&(objectClass=User) (sAMAccountName=$($env:Username)))"
        $result = $searcher.FindOne() 
        Assert-NotNull $result
    }
}
