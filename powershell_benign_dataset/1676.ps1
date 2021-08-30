
$VerbosePreference = 'Continue'


while (-not (Test-Path -Path 'C:\test.txt')) {
	Start-Sleep -Seconds 1
	Write-Verbose -Message "Still waiting for action to complete..."
}



$timer = [Diagnostics.Stopwatch]::StartNew()
$timer.Elapsed.TotalSeconds
$timer.Stop()

$timer = [Diagnostics.Stopwatch]::StartNew()
while (($timer.Elapsed.TotalSeconds -lt 10) -and (-not (Test-Path -Path 'C:\test.txt'))) {
	Start-Sleep -Seconds 1
	$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)
	Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
}

function Wait-Action {
	

	[OutputType([void])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$Condition,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[int]$Timeout,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[object[]]$ArgumentList,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[int]$RetryInterval = 5
	)
	try {
		$timer = [Diagnostics.Stopwatch]::StartNew()
		while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (& $Condition $ArgumentList)) {
			Start-Sleep -Seconds $RetryInterval
			$totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)
			Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
		}
		$timer.Stop()
		if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
			throw 'Action did not complete before timeout period.'
		} else {
			Write-Verbose -Message 'Action completed before timeout period.'
		}
	} catch {
		Write-Error -Message $_.Exception.Message
	}
}