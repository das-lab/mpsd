function New-PSFLicense
{

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/New-PSFLicense')]
	[OutputType([PSFramework.License.License])]
	param
	(
		[Parameter(Mandatory = $true)]
		[String]
		$Product,
		
		[String]
		$Manufacturer = "ACME ltd.",
		
		[Version]
		$ProductVersion = "1.0.0.0",
		
		[Parameter(Mandatory = $true)]
		[PSFramework.License.ProductType]
		$ProductType,
		
		[String]
		$Name = "Unknown",
		
		[Version]
		$Version = "1.0.0.0",
		
		[DateTime]
		$Date = (Get-Date -Year 1989 -Month 10 -Day 3 -Hour 0 -Minute 0 -Second 0),
		
		[PSFramework.License.LicenseType]
		$Type = "Free",
		
		[Parameter(Mandatory = $true)]
		[String]
		$Text,
		
		[string]
		$Description,
		
		[PSFramework.License.License]
		$Parent
	)
	
	
	$license = New-Object PSFramework.License.License -Property @{
		Product	       = $Product
		Manufacturer   = $Manufacturer
		ProductVersion = $ProductVersion
		ProductType    = $ProductType
		LicenseName    = $Name
		LicenseVersion = $Version
		LicenseDate    = $Date
		LicenseType    = $Type
		LicenseText    = $Text
		Description    = $Description
		Parent		   = $Parent
	}
	if ($PSCmdlet.ShouldProcess("$($license.Product) $($license.ProductVersion) ($($license.LicenseName))", "Create License"))
	{
		if (-not ([PSFramework.License.LicenseHost]::Get($license)))
		{
			[PSFramework.License.LicenseHost]::Add($license)
		}
		
		return $license
	}
}
