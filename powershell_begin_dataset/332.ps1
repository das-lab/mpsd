function Join-PSFPath
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path,
		
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]
		$Child,
		
		[switch]
		$Normalize
	)
	
	$resultingPath = $Path
	
	foreach ($childItem in $Child)
	{
		$resultingPath = Join-Path -Path $resultingPath -ChildPath $childItem
	}
	
	if ($Normalize)
	{
		$defaultSeparator = [System.IO.Path]::DirectorySeparatorChar
		$altSeparator = "/"
		if ($defaultSeparator -eq "/") { $altSeparator = "\" }
		$resultingPath = $resultingPath.Replace($altSeparator, $defaultSeparator)
	}
	
	$resultingPath
}