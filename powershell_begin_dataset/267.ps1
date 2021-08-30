function Get-SCSMWorkItemUserInput
{
	
	[CmdletBinding()]
	Param (
		$WorkItemObject
	)
	BEGIN
	{
		
		$userInput = ""
		$ListArray = @()
	}
	PROCESS
	{
		$UserInput = $WorkItemObject.UserInput
		$nl = [Environment]::NewLine
		$content = [XML]$UserInput
		$inputs = $content.UserInputs.UserInput
		foreach ($input in $inputs)
		{
			if ($($input.Answer) -like "<value*")
			{
				[xml]$answer = $input.answer
				foreach ($value in $($($answer.values)))
				{
					foreach ($item in $value)
					{
						foreach ($txt in $($item.value))
						{
							$ListArray += $($txt.DisplayName)
						}
						
						$Props = @{
							Question = $input.question
							Answer = $([string]::Join(", ", $ListArray))

						}
						New-Object -TypeName PSObject -Property $Props
						$ListArray = $null
					}
				}
			}
			else
			{
				if ($input.type -eq "enum")
				{
					$ListGuid = Get-SCSMEnumeration -Id $input.Answer

					$Props = @{
						Question = $input.question
						Answer = $ListGuid.displayname

					}
					New-Object -TypeName PSObject -Property $Props
				}
				else
				{
					$Props = @{
						Question = $input.question
						Answer = $input.answer
					}

					New-Object -TypeName PSObject -Property $Props
				}
			}
		}
		
	}
}



Get-SCSMWorkItemUserInput -WorkItemObject $SRsToProcess