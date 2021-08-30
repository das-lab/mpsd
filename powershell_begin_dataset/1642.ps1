










if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + ' (Elevated)'
    $Host.UI.RawUI.BackgroundColor = 'DarkBlue'
    Clear-Host
} else {
    $newProcess = New-Object Diagnostics.ProcessStartInfo 'PowerShell'
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
    $newProcess.Verb = 'runas'
    [Diagnostics.Process]::Start($newProcess)
    exit
}

Write-Host -NoNewLine 'Press any key to continue...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')


$UFD = [string[]]([io.driveinfo]::getdrives() | % {$_.name} | ? {test-path "$_\TEMPORARY\Helvetica Fonts\helveticaneue"})
$source = Read-Host "Source ($(if ($UFD) {$UFD[0]} else {'?'})) "
if (!$source) {$source = $UFD[0]}
$source = Join-Path $source '\TEMPORARY\Helvetica Fonts\helveticaneue'


$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
dir $source | % { $fonts.CopyHere($_.fullname) }

