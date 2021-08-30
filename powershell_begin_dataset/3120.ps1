









function Update-StringInFile
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(
			Position=0,
			HelpMessage="Folder where the files are stored (will search recursive)")]
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
			Position=1,
			Mandatory=$true,
			HelpMessage="String to find")]
		[String]$Find,
	
		[Parameter(
			Position=2,
			Mandatory=$true,
			HelpMessage="String to replace")]
		[String]$Replace,

		[Parameter(
			Position=3,
			HelpMessage="String must be case sensitive (Default=false)")]
		[switch]$CaseSensitive=$false
	)

	Begin{

	}

	Process{
		Write-Verbose -Message "Binary files like (*.zip, *.exe, etc...) are ignored"

		$Files = Get-ChildItem -Path $Path -Recurse | Where-Object { ($_.PSIsContainer -eq $false) -and ((Test-IsFileBinary -FilePath $_.FullName) -eq $false) } | Select-String -Pattern ([regex]::Escape($Find)) -CaseSensitive:$CaseSensitive | Group-Object Path 
		
		Write-Verbose -Message "Total files with string to replace found: $($Files.Count)"

		
		foreach($File in $Files)
		{
			Write-Verbose -Message "File:`t$($File.Name)"
			Write-Verbose -Message "Number of strings to replace in current file:`t$($File.Count)"
    
			if($PSCmdlet.ShouldProcess($File.Name))
			{
				try
				{	
					
					if($CaseSensitive)
					{
						(Get-Content -Path $File.Name) -creplace [regex]::Escape($Find), $Replace | Set-Content -Path $File.Name -Force
					}
					else
					{
						(Get-Content -Path $File.Name) -replace [regex]::Escape($Find), $Replace | Set-Content -Path $File.Name -Force
					}
				}
				catch
				{
					Write-Error -Message "$($_.Exception.Message)" -Category InvalidData
				}
			}
		}
	}

	End{

	}
}