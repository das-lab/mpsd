







$vComputerName = "PSQLDLS34"


$vInstanceName = "MSSQLSERVER"

Write-Host "IP Address(es) that the SQL instance " $vComputerName "\" $vInstanceName " is listening on are listed below: "

$vListenAll = 0
$vTCPProps = get-WMIObject ServerNetworkProtocolProperty -ComputerName $vComputerName -NameSpace "root\Microsoft\SqlServer\ComputerManagement10" | Where-Object {$_.PropertyName  -eq "ListenOnAllIPs" -and $_.InstanceName -eq $vInstanceName}
foreach ($vTCPProp in $vTCPProps)
{
$vListenAll = $vTCPProp.PropertyNumVal
}

if($vListenAll -eq 1)
{
Write-Host "Is instance configured to listen on All IPs (Listen All property): TRUE"

$vIPconfig = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $vComputerName


foreach ($vIP in $vIPconfig)
{
if ($vIP.IPaddress)
{
foreach ($vAddr in $vIP.Ipaddress)
{
$vAddr
}
}
}
}
else
{


$vIPProps = get-WMIObject ServerNetworkProtocolProperty -ComputerName $vComputerName -NameSpace "root\Microsoft\SqlServer\ComputerManagement10" | Where-Object {$_.InstanceName -eq $vInstanceName -and $_.ProtocolName  -eq "Tcp"} | Sort-Object IPAddressName,PropertyName
$vActive = 0
$vEnabled = 0

Write-Host "Is instance configured to listen on All IPs (Listen All property): FALSE"

foreach ($vIPProp in $vIPProps)
{

if ($vIPProp.Name -ne "IPAll" -and ($vIPProp.PropertyName -eq "Active"))
{
$vActive =  $vIPProp.PropertyNumVal
}

if ($vIPProp.Name -ne "IPAll" -and ($vIPProp.PropertyName -eq "Enabled"))
{
$vEnabled = $vIPProp.PropertyNumVal
}

if ($vIPProp.Name -ne "IPAll" -and $vIPProp.PropertyName -eq "IPAddress" -and $vEnabled -eq 1 -and $vActive -eq 1)
{

$vTCPProp.PropertyStrVal
}
}
}