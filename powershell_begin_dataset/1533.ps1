
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = "Debug",
    [switch]$SkipDocs,
    [string]$DotnetCli
)

function Find-DotnetCli()
{
    [string] $DotnetCli = ''
    $dotnetCmd = Get-Command dotnet
    return $dotnetCmd.Path
}


if (-not $DotnetCli) {
    $DotnetCli = Find-DotnetCli
}

if (-not $DotnetCli) {
    throw "dotnet cli is not found in PATH, install it from https://docs.microsoft.com/en-us/dotnet/core/tools"
} else {
    Write-Host "Using dotnet from $DotnetCli"
}

if (Get-Variable -Name IsCoreClr -ValueOnly -ErrorAction SilentlyContinue) {
    $framework = 'netstandard1.6'
} else {
    $framework = 'net451'
}

& $DotnetCli publish ./src/Markdown.MAML -f $framework --output=$pwd/publish /p:Configuration=$Configuration

$assemblyPaths = (
    (Resolve-Path "publish/Markdown.MAML.dll").Path,
    (Resolve-Path "publish/YamlDotNet.dll").Path
)


New-Item -Type Directory out -ErrorAction SilentlyContinue > $null
Copy-Item -Rec -Force src\platyPS out
foreach($assemblyPath in $assemblyPaths)
{
	$assemblyFileName = [System.IO.Path]::GetFileName($assemblyPath)
	$outputPath = "out\platyPS\$assemblyFileName"
	if ((-not (Test-Path $outputPath)) -or
		(Test-Path $outputPath -OlderThan (Get-ChildItem $assemblyPath).LastWriteTime))
	{
		Copy-Item $assemblyPath out\platyPS
	} else {
		Write-Host -Foreground Yellow "Skip $assemblyFileName copying"
	}
}


Copy-Item .\platyPS.schema.md out\platyPS
New-Item -Type Directory out\platyPS\docs -ErrorAction SilentlyContinue > $null
Copy-Item .\docs\* out\platyPS\docs\


New-Item -Type Directory out\platyPS\templates -ErrorAction SilentlyContinue > $null
Copy-Item .\templates\* out\platyPS\templates\


if ($env:APPVEYOR_REPO_TAG_NAME)
{
    $manifest = cat -raw out\platyPS\platyPS.psd1
    $manifest = $manifest -replace "ModuleVersion = '0.0.1'", "ModuleVersion = '$($env:APPVEYOR_REPO_TAG_NAME)'"
    Set-Content -Value $manifest -Path out\platyPS\platyPS.psd1 -Encoding Ascii
}


Remove-Module platyPS -ErrorAction SilentlyContinue
Import-Module $pwd\out\platyPS

if (-not $SkipDocs) {
    New-ExternalHelp docs -OutputPath out\platyPS\en-US -Force
    
    Import-Module $pwd\out\platyPS -Force
}

