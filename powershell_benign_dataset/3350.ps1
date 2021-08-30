
[cmdletbinding(DefaultParameterSetName = 'task')]
param(
    
    [parameter(ParameterSetName = 'task', Position = 0)]
    [ValidateSet('default','Init','Test','Analyze','Pester','Build','Compile','Clean','Publish','Build-Docker','Publish-Docker','RegenerateHelp','UpdateMarkdownHelp','CreateExternalHelp')]
    [string[]]$Task = 'default',

    
    [switch]$Bootstrap,

    [hashtable]$Properties = @{},

    
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'


if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap > $null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }
    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
}


$psakeFile = './psakeFile.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile  |
        Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force

    Invoke-psake -buildFile $psakeFile -taskList $Task -properties $properties -nologo
    exit ( [int]( -not $psake.build_success ) )
}
