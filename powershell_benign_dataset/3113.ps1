









function Get-RandomPIN
{
	[CmdletBinding(DefaultParameterSetName='NoClipboard')]
	param(
		[Parameter(
			Position=0,
			HelpMessage='Length of the PIN (Default=4)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Length of the PIN can not be 0!"
			}
			else 
			{
				return $true	
			}
		})]
		[Int32]$Length=4,

		[Parameter(
			ParameterSetName='NoClipboard',
			Position=1,
			HelpMessage='Number of PINs to be generated (Default=1)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Number of PINs to be generated can not be 0"
			}
			else 
			{
				return $true
			}
		})]
		[Int32]$Count=1,

		[Parameter(
			ParameterSetName='Clipboard',
			Position=1,
			HelpMessage='Copy PIN to clipboard')]
		[switch]$CopyToClipboard,

		[Parameter(
			Position=2,
			HelpMessage='Smallest possible number (Default=0)')]
		[Int32]$Minimum=0,
		
		[Parameter(
			Position=3,
			HelpMessage='Greatest possible number (Default=9)')]
		[ValidateScript({
			if($_ -lt $Minimum)
			{
				throw "Minimum can not be greater than maximum!"
			}
		})]
		[Int32]$Maximum=9		
	)

	Begin{

	}

	Process{
		for($i = 1; $i -ne $Count + 1; $i++)
		{ 
			$PIN = [String]::Empty
				
			while($PIN.Length -lt $Length)
			{
				
				$PIN += (Get-Random -Minimum $Minimum -Maximum $Maximum).ToString()
			}
			
			
			if($Count -eq 1)
			{
				
				if($CopyToClipboard)
				{
					Set-Clipboard -Value $PIN
				}

				[pscustomobject] @{
					PIN = $PIN
				}
			}
			else 
			{			
				[pscustomobject] @{
					Count = $i
					PIN = $PIN
				}	
			}
		}
	}

	End{
		
	}
}