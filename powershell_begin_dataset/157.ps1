function Get-LogFast
{

	[CmdletBinding()]
	PARAM (
		$Path = "c:\Biglog.log",

		$Match
	)
	BEGIN
	{
		
		
		$StreamReader = New-object -TypeName System.IO.StreamReader -ArgumentList (Resolve-Path -Path $Path -ErrorAction Stop).Path
	}
	PROCESS
	{
		
		while ($StreamReader.Peek() -gt -1)
		{
			
			
			$Line = $StreamReader.ReadLine()

			
			if ($Line.length -eq 0 -or $Line -match "^
			{
				continue
			}

			IF ($PSBoundParameters['Match'])
			{
				If ($Line -match $Match)
				{
					Write-Verbose -Message "[PROCESS] Match found"

					
					

					Write-Output $Line
				}
			}
			ELSE { Write-Output $Line }
		}
	} 
}