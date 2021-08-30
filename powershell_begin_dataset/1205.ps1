











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$user = $null
$url = 'http://test-revokehttpurlpermission:10383/'

function Start-Test
{
    $user = Resolve-Identity -Name $CarbonTestUser.UserName
    Grant-HttpUrlPermission -Url $url -Principal $user.FullName -Permission Listen
}

function Stop-Test
{
    netsh http delete urlacl url=$url
}

function Test-ShouldRevokePermission
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}

function Test-ShouldRevokePermissionMultipleTimes
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}

function Test-ShouldRevokeProperlyIfUrlDoesNotEndWithTrailingSlash
{
    Revoke-HttpUrlPermission -Url $url.TrimEnd('/') -Principal $user
    Assert-Null (Get-HttpUrlAcl -LiteralUrl $url -ErrorAction Ignore)
}