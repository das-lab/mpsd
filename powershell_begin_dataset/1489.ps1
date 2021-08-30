
param(
)


Set-StrictMode -Version 'Latest'

& {
    $originalVerbosePreference = $Global:VerbosePreference
    $Global:VerbosePreference = [Management.Automation.ActionPreference]::SilentlyContinue

    if( (Get-Module -Name 'Blade') )
    {
        Remove-Module 'Blade'
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Blade.psd1' -Resolve)
}
