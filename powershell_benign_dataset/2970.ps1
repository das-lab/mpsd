
$dotnetCLIChannel = 'Current'
$dotnetCLIRequiredVersion = 'latest'
$NoSudo = $false

. "$PSScriptRoot/tools.ps1"

$DotnetArguments = @{ Channel = $dotnetCLIChannel; Version = $dotnetCLIRequiredVersion; NoSudo = $NoSudo }
Install-Dotnet @DotnetArguments


$Env:PATH += "$([IO.Path]::PathSeparator)$Env:HOME/.dotnet"


dotnet build -version -nologo



