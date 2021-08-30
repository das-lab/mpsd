













[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $Name,

    [Parameter(Mandatory=$true,Position=1)]
    [string]
    $Value,

    [Parameter(Position=2)]
    [string]
    $ProviderName
)

Set-StrictMode -Version 'Latest'

$Name = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Name) )
$Value = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Value) )
$ProviderName = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($ProviderName) )

Add-Type -AssemblyName System.Configuration

$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
$connectionStrings = $config.ConnectionStrings.ConnectionStrings
if( $connectionStrings[$Name] )
{
    $connectionStrings.Remove( $Name )
}

$args = @( $Name, $Value )
if( $ProviderName )
{
    $args += $ProviderName
}
$connectionString = New-Object Configuration.ConnectionStringSettings $args
$connectionStrings.Add( $connectionString )

$config.Save()

