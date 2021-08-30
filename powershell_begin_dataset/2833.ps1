





[cmdletbinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$buildFile,

    [Parameter(Position = 1, Mandatory = $false)]
    [string[]]$taskList = @(),

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$framework,

    [Parameter(Position = 3, Mandatory = $false)]
    [switch]$docs = $false,

    [Parameter(Position = 4, Mandatory = $false)]
    [System.Collections.Hashtable]$parameters = @{},

    [Parameter(Position = 5, Mandatory = $false)]
    [System.Collections.Hashtable]$properties = @{},

    [Parameter(Position = 6, Mandatory = $false)]
    [alias("init")]
    [scriptblock]$initialization = {},

    [Parameter(Position = 7, Mandatory = $false)]
    [switch]$nologo = $false,

    [Parameter(Position = 8, Mandatory = $false)]
    [switch]$help = $false,

    [Parameter(Position = 9, Mandatory = $false)]
    [string]$scriptPath,

    [Parameter(Position = 10, Mandatory = $false)]
    [switch]$detailedDocs = $false,

    [Parameter(Position = 11, Mandatory = $false)]
    [switch]$notr = $false
)


if (-not $scriptPath) {
    $scriptPath = $(Split-Path -Path $MyInvocation.MyCommand.path -Parent)
}


Remove-Module -Name [p]sake -Verbose:$false
Import-Module -Name (Join-Path -Path $scriptPath -ChildPath 'psake.psd1') -Verbose:$false
if ($help) {
    Get-Help -Name Invoke-psake -Full
    return
}

if ($buildFile -and (-not (Test-Path -Path $buildFile))) {
    $absoluteBuildFile = (Join-Path -Path $scriptPath -ChildPath $buildFile)
    if (Test-path -Path $absoluteBuildFile) {
        $buildFile = $absoluteBuildFile
    }
}

Invoke-psake $buildFile $taskList $framework $docs $parameters $properties $initialization $nologo $detailedDocs $notr

if (!$psake.build_success) {
    exit 1
}
