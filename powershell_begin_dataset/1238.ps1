











[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $Name
)

Set-StrictMode -Version 'Latest'

$Name = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Name) ) 
[Environment]::SetEnvironmentVariable( $Name, $null, [EnvironmentVariableTarget]::User )
