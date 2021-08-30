












[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $Name,

    [Parameter(Mandatory=$true,Position=1)]
    [string]
    $Value
)

Set-StrictMode -Version 'Latest'

$Name = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Name) )
$Value = [Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($Value) )

Add-Type -AssemblyName System.Configuration

$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
$appSettings = $config.AppSettings.Settings
if( $appSettings[$Name] )
{
    $appSettings[$Name].Value = $Value
}
else
{
    $appSettings.Add( $Name, $Value )
}
$config.Save()

