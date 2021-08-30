












function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldCreateCredential
{
    $cred = New-Credential -User 'Credential' -Password 'password1'
    Assert-IsNotNull $cred 'New-Credential didn''t create credential object.'
    Assert-Is $cred 'Management.Automation.PSCredential' "didn't create credential object of right type"
    Assert-Equal 'Credential' $cred.UserName 'username not set correctly'
    Assert-NotEmpty (ConvertFrom-SecureString $cred.Password) 'password not set correctly'
}

function Test-ShouldCreateCredentialFromSecureString
{
    $secureString = New-Object 'Security.SecureString'
    $secureString.AppendChar( 'a' )

    $c = New-Credential -UserName 'fubar' -Password $secureString
    Assert-NotNull $c
    Assert-Equal 'a' $c.GetNetworkCredential().Password
}

function Test-ShouldGiveAnErrorIfPassNotAStringOrSecureString
{
    $c = New-Credential -UserName 'fubar' -Password 1 -ErrorAction SilentlyContinue
    Assert-Null $c
    Assert-Error -Last -Regex 'must be'
}

function Test-ShouldAcceptPipelineInput
{
    $c = 'fubar' | New-Credential -UserName 'fizzbuzz'
    Assert-NotNull $c
    Assert-Equal 'fizzbuzz' $c.UserName
    Assert-Equal 'fubar' $c.GetNetworkCredential().Password
}

