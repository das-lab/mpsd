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
