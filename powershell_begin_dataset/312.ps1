function Get-PSFLicense
{

	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFLicense')]
	[OutputType([PSFramework.License.License])]
	param (
		[Parameter(Position = 0)]
		[Alias('Product')]
		[String]
		$Filter = "*",
		
		[PSFramework.License.ProductType[]]
		$ProductType,
		
		[PSFramework.License.LicenseType]
		$LicenseType,
		
		[String]
		$Manufacturer = "*"
	)
	
	[PSFramework.License.LicenseHost]::Get() | Where-Object {
		if ($_.Product -notlike $Filter) { return $false }
		if ($_.Manufacturer -notlike $Manufacturer) { return $false }
		if ($ProductType -and ($_.ProductType -notin $ProductType)) { return $false }
		if ($licenseType -and -not ($_.LicenseType -band $LicenseType)) { return $false }
		return $true
	}
}
