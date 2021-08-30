function New-MrScriptModule {



    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        
        [ValidateScript({
          If (Test-Path -Path $_ -PathType Container) {
            $true
          }
          else {
            Throw "'$_' is not a valid directory."
          }
        })]
        [String]$Path,

        [Parameter(Mandatory)]
        [string]$Author,

        [Parameter(Mandatory)]
        [string]$CompanyName,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$PowerShellVersion
    )

    New-Item -Path $Path -Name $Name -ItemType Directory | Out-Null
    Out-File -FilePath "$Path\$Name\$Name.psm1" -Encoding utf8
    Add-Content -Path "$Path\$Name\$Name.psm1" -Value '
Get-ChildItem -Path $PSScriptRoot\*.ps1 -Exclude *.tests.ps1, *profile.ps1 |
ForEach-Object {
    . $_.FullName
}'
    New-ModuleManifest -Path "$Path\$Name\$Name.psd1" -RootModule $Name -Author $Author -Description $Description -CompanyName $CompanyName `
    -PowerShellVersion $PowerShellVersion -AliasesToExport $null -FunctionsToExport $null -VariablesToExport $null -CmdletsToExport $null
}
