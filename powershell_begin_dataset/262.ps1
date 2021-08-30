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
