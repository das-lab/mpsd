

try {
    $IEUrlInfo = Get-WmiObject -Namespace 'root\cimv2\IETelemetry' -Class IEURLInfo -ErrorAction Stop
    $IEUrlInfo
}
catch [System.Management.ManagementException] {
    throw 'WMI Namespace root\fimv2\IETelemetry does not exist.'
}