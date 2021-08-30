
function Start-PacketTrace {

	[CmdletBinding()]
	[OutputType()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path ($_ | Split-Path -Parent) -PathType Container })]
		[ValidatePattern('.*\.etl$')]
		[string[]]$TraceFilePath,
		[Parameter()]
		[switch]$Force
	)
	begin {
		Set-StrictMode -Version Latest
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	}
	process {
		try {
			if (Test-Path -Path $TraceFilePath -PathType Leaf) {
				if (-not ($Force.IsPresent)) {
					throw "An existing trace file was found at [$($TraceFilePath)] and -Force was not used. Exiting.."
				} else {
					Remove-Item -Path $TraceFilePath
				}
			}
			$OutFile = "$PSScriptRoot\temp.txt"
			$Process = Start-Process "$($env:windir)\System32\netsh.exe" -ArgumentList "trace start persistent=yes capture=yes tracefile=$TraceFilePath" -RedirectStandardOutput $OutFile -Wait -NoNewWindow -PassThru
			if ($Process.ExitCode -notin @(0, 3010)) {
				throw "Failed to start the packet trace. Netsh exited with an exit code [$($Process.ExitCode)]"
			} else {
				Write-Verbose -Message "Successfully started netsh packet capture. Capturing all activity to [$($TraceFilePath)]"
			}
		} catch {
			Write-Error -Message "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		} finally {
			if (Test-Path -Path $OutFile -PathType Leaf) {
				Remove-Item -Path $OutFile
			}	
		}
	}
}



function Stop-PacketTrace {

	[CmdletBinding()]
	[OutputType()]
	param
	()
	begin {
		Set-StrictMode -Version Latest
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	}
	process {
		try {
			$OutFile = "$PSScriptRoot\temp.txt"
			$Process = Start-Process "$($env:windir)\System32\netsh.exe" -ArgumentList 'trace stop' -Wait -NoNewWindow -PassThru -RedirectStandardOutput $OutFile
			if ((Get-Content $OutFile) -eq 'There is no trace session currently in progress.'){
				Write-Verbose -Message 'There are no trace sessions currently in progress'
			} elseif ($Process.ExitCode -notin @(0, 3010)) {
				throw "Failed to stop the packet trace. Netsh exited with an exit code [$($Process.ExitCode)]"
			} else {
				Write-Verbose -Message 'Successfully stopped netsh packet capture'
			}
		} catch {
			Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		} finally {
			if (Test-Path -Path $OutFile -PathType Leaf) {
				Remove-Item -Path $OutFile
			}
		}
	}
}
