











[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $Name,

    [Parameter(Mandatory=$true)]
    [string]
    $Value
)

Set-StrictMode -Version 'Latest'

$Name,$Value = 
    $Name,$Value | 
    ForEach-Object { [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($_) ) }
    
[Environment]::SetEnvironmentVariable( $Name, $Value, [EnvironmentVariableTarget]::User )
