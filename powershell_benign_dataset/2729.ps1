
$ErrorActionPreference = "SilentlyContinue"
$o = "" | Select-Object IISInstalled
if ((Get-ItemProperty HKLM:\Software\Microsoft\InetStp\Components\).W3SVC) {
    $o.IISInstalled = "True"
} else {
    $o.IISInstalled = "False"
}
$o