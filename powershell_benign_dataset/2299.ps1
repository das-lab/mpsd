function Invoke-Program {
	
	[CmdletBinding()]
	[OutputType([System.Management.Automation.PSObject])]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,

		[Parameter(Mandatory)]
		[string]$ComputerName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ArgumentList,

		[Parameter()]
		[bool]$ExpandStrings = $false,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$WorkingDirectory,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[uint32[]]$SuccessReturnCodes = @(0, 3010)
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try {
			Write-Verbose -Message "Acceptable success return codes are [$($SuccessReturnCodes -join ',')]"
			
			$scriptBlock = {
				$VerbosePreference = $using:VerbosePreference
	
				$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo;
				$processStartInfo.FileName = $Using:FilePath;
				if ($Using:ArgumentList) {
					$processStartInfo.Arguments = $Using:ArgumentList;
					if ($Using:ExpandStrings) {
						$processStartInfo.Arguments = $ExecutionContext.InvokeCommandWithCred.ExpandString($Using:ArgumentList);
					}
				}
				if ($Using:WorkingDirectory) {
					$processStartInfo.WorkingDirectory = $Using:WorkingDirectory;
					if ($Using:ExpandStrings) {
						$processStartInfo.WorkingDirectory = $ExecutionContext.InvokeCommandWithCred.ExpandString($Using:WorkingDirectory);
					}
				}
				$processStartInfo.UseShellExecute = $false; 
				$ps = New-Object System.Diagnostics.Process;
				$ps.StartInfo = $processStartInfo;
				Write-Verbose -Message "Starting process path [$($processStartInfo.FileName)] - Args: [$($processStartInfo.Arguments)] - Working dir: [$($Using:WorkingDirectory)]"
				$null = $ps.Start();
				if (-not $ps) {
					throw "Error running program: $($ps.ExitCode)"
				} else {
					$ps.WaitForExit()
				}
				
				
				if ($ps.ExitCode -notin $Using:SuccessReturnCodes) {
					throw "Error running program: $($ps.ExitCode)"
				}
			}
			
			
			Write-Verbose -Message "Running command line [$FilePath $ArgumentList] on $ComputerName"
			
			Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptblock
		} catch {
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}