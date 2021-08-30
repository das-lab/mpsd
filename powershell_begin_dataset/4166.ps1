
[CmdletBinding()]
param ()

Import-Module ActiveDirectory

[System.Environment]::SetEnvironmentVariable("EmailAddress", $null, 'User')

$EmailAddress = (Get-ADUser $env:USERNAME -Properties mail).mail

[System.Environment]::SetEnvironmentVariable("EmailAddress", $EmailAddress, 'User')
