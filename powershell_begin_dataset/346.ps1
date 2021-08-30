function Get-PSFConfigValue
{
	
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectComparisonWithNull", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFConfigValue')]
	Param (
		[Alias('Name')]
		[Parameter(Mandatory = $true)]
		[string]
		$FullName,
		
		[object]
		$Fallback,
		
		[switch]
		$NotNull
	)
	
	$FullName = $FullName.ToLower()
	
	$temp = $null
	$temp = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Value
	if ($temp -eq $null) { $temp = $Fallback }
	
	if ($NotNull -and ($temp -eq $null))
	{
		Stop-PSFFunction -Message "No Configuration Value available for $FullName" -EnableException $true -Category InvalidData -Target $FullName
	}
	else
	{
		return $temp
	}
}
