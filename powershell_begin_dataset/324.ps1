function Write-PSFHostColor
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Write-PSFHostColor')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$String,
		
		[ConsoleColor]
		$DefaultColor = (Get-PSFConfigValue -FullName "psframework.message.info.color"),
		
		[switch]
		$NoNewLine,
		
		[PSFramework.Message.MessageLevel]
		$Level
	)
	begin
	{
		$em = [PSFramework.Message.MessageHost]::InfoColorEmphasis
		$sub = [PSFramework.Message.MessageHost]::InfoColorSubtle
		
		$max_info = [PSFramework.Message.MessageHost]::MaximumInformation
		$min_info = [PSFramework.Message.MessageHost]::MinimumInformation
	}
	process
	{
		if ($Level)
		{
			if (($max_info -lt $Level) -or ($min_info -gt $Level)) { return }
		}
		
		foreach ($line in $String)
		{
			foreach ($row in $line.Split("`n")) 
			{
				if ($row -notlike '*<c=["'']*["'']>*</c>*') { Microsoft.PowerShell.Utility\Write-Host -Object $row -ForegroundColor $DefaultColor -NoNewline:$NoNewLine }
				else
				{
					$row = $row -replace '<c=["'']em["'']>', "<c='$em'>" -replace '<c=["'']sub["'']>', "<c='$sub'>"
					$match = ($row | Select-String '<c=["''](.*?)["'']>(.*?)</c>' -AllMatches).Matches
					$index = 0
					$count = 0
					
					while ($count -le $match.Count)
					{
						if ($count -lt $Match.Count)
						{
							Microsoft.PowerShell.Utility\Write-Host -Object $row.SubString($index, ($match[$count].Index - $Index)) -ForegroundColor $DefaultColor -NoNewline
							try { Microsoft.PowerShell.Utility\Write-Host -Object $match[$count].Groups[2].Value -ForegroundColor $match[$count].Groups[1].Value -NoNewline -ErrorAction Stop }
							catch { Microsoft.PowerShell.Utility\Write-Host -Object $match[$count].Groups[2].Value -ForegroundColor $DefaultColor -NoNewline -ErrorAction Stop }
							
							$index = $match[$count].Index + $match[$count].Length
							$count++
						}
						else
						{
							Microsoft.PowerShell.Utility\Write-Host -Object $row.SubString($index) -ForegroundColor $DefaultColor -NoNewline:$NoNewLine
							$count++
						}
					}
				}
			}
		}
	}
}
