function Clean-MacAddress
{

	[OutputType([String], ParameterSetName = "Upper")]
	[OutputType([String], ParameterSetName = "Lower")]
	[CmdletBinding(DefaultParameterSetName = 'Upper')]
	param
	(
		[Parameter(ParameterSetName = 'Lower')]
		[Parameter(ParameterSetName = 'Upper')]
		[String]$MacAddress,

		[Parameter(ParameterSetName = 'Lower')]
		[Parameter(ParameterSetName = 'Upper')]
		[ValidateSet(':', 'None', '.', "-")]
		$Separator,

		[Parameter(ParameterSetName = 'Upper')]
		[Switch]$Uppercase,

		[Parameter(ParameterSetName = 'Lower')]
		[Switch]$Lowercase
	)

	BEGIN
	{
		
		$MacAddress = $MacAddress -replace "-", "" 
		$MacAddress = $MacAddress -replace ":", "" 
		$MacAddress = $MacAddress -replace "/s", "" 
		$MacAddress = $MacAddress -replace " ", "" 
		$MacAddress = $MacAddress -replace "\.", "" 
		$MacAddress = $MacAddress.trim() 
		$MacAddress = $MacAddress.trimend() 
	}
	PROCESS
	{
		IF ($PSBoundParameters['Uppercase'])
		{
			$MacAddress = $macaddress.toupper()
		}
		IF ($PSBoundParameters['Lowercase'])
		{
			$MacAddress = $macaddress.tolower()
		}
		IF ($PSBoundParameters['Separator'])
		{
			IF ($Separator -ne "None")
			{
				$MacAddress = $MacAddress -replace '(..(?!$))', "`$1$Separator"
			}
		}
	}
	END
	{
		Write-Output $MacAddress
	}
}
