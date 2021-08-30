function Get-PSFUserChoice
{

	[OutputType([System.Int32])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object[]]
		$Options,
		
		[string]
		$Caption,
		
		[string]
		$Message,
		
		[int]
		$DefaultChoice = 0
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		$choices = @()
		foreach ($option in $Options)
		{
			if ($option -is [hashtable])
			{
				$label = $option.Keys -match '^l' | Select-Object -First 1
				[string]$labelValue = $option[$label]
				$help = $option.Keys -match '^h' | Select-Object -First 1
				[string]$helpValue = $option[$help]
				
			}
			else
			{
				$labelValue = "$option"
				$helpValue = "$option"
			}
			if ($labelValue -match "&") { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList $labelValue, $helpValue }
			else { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&$($labelValue.Trim())", $helpValue }
		}
	}
	process
	{
		
		
		if ($Options.Count -eq 1) { return 0 }
		
		$Host.UI.PromptForChoice($Caption, $Message, $choices, $DefaultChoice)
	}
}