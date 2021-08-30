









function Find-StringInFile
{
	[CmdletBinding()]
	param(
	[Parameter(
			Position=0,
			Mandatory=$true,
			HelpMessage="String to find")]
		[String]$Search,

		[Parameter(
			Position=1,
			HelpMessage="Folder where the files are stored (search is recursive)")]
		[ValidateScript({
			if(Test-Path -Path $_)
			{
				return $true
			}
			else 
			{
				throw "Enter a valid path!"	
			}
		})]
		[String]$Path = (Get-Location),
		
		[Parameter(
			Position=2,
			HelpMessage="String must be case sensitive (Default=false)")]
		[switch]$CaseSensitive
	)

	Begin{
		
	}

	Process{
		
		$Strings = Get-ChildItem -Path $Path -Recurse | Select-String -Pattern ([regex]::Escape($Search)) -CaseSensitive:$CaseSensitive | Group-Object -Property Path 
		
		
		foreach($String in $Strings)
		{		
			$IsBinary = Test-IsFileBinary -FilePath $String.Name

			
			foreach($Group in $String.Group)
			{	
				[pscustomobject] @{
					Filename = $Group.Filename
					Path = $Group.Path
					LineNumber = $Group.LineNumber
					IsBinary = $IsBinary
					Matches = $Group.Matches
				}
			}   
		}
	}

	End{
		
	}
}