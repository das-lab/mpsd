
Import-Module C:\git-repositories\PowerShell\MSFVMLab\MSFVMLab.psm1 -Force

$LabConfig = Get-Content C:\git-repositories\PowerShell\MSFVMLab\LabVMS.json | ConvertFrom-Json
$WorkingDirectory = $LabConfig.WorkingDirectory


If(-not (Test-Path $WorkingDirectory)){
    Write-Error "$WorkingDirectory does not exist!" -ErrorAction Stop
}


foreach($network in $LabConfig.Switches){
    If(!(Get-VMSwitch $network.Name -ErrorAction SilentlyContinue)){
            New-VMSwitch -Name $network.Name -SwitchType $network.Type
        }
}


Get-Credential -Message 'Local Adminstrator Credential' -UserName 'localhost\administrator' | Export-Clixml "$WorkingDirectory\vmlab_localadmin.xml"
Get-Credential -Message 'Domain Credential' -UserName "$($LabConfig.domain)\administrator" | Export-Clixml "$WorkingDirectory\vmlab_domainadmin.xml"
Get-Credential -Message 'SQL Server Service credential' -UserName "$($LabConfig.domain)\sqlsvc" | Export-Clixml "$WorkingDirectory\vmlab_sqlsvc.xml"
