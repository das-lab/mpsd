function Exec {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$cmd,

        [string]$errorMessage = ($msgs.error_bad_command -f $cmd),

        [int]$maxRetries = 0,

        [string]$retryTriggerErrorPattern = $null,

        [string]$workingDirectory = $null
    )

    $tryCount = 1

    do {
        try {

            if ($workingDirectory) {
                Push-Location -Path $workingDirectory
            }

            $global:lastexitcode = 0
            & $cmd
            if ($global:lastexitcode -ne 0) {
                throw "Exec: $errorMessage"
            }
            break
        }
        catch [Exception] {
            if ($tryCount -gt $maxRetries) {
                throw $_
            }

            if ($retryTriggerErrorPattern -ne $null) {
                $isMatch = [regex]::IsMatch($_.Exception.Message, $retryTriggerErrorPattern)

                if ($isMatch -eq $false) {
                    throw $_
                }
            }

            "Try $tryCount failed, retrying again in 1 second..."

            $tryCount++

            [System.Threading.Thread]::Sleep([System.TimeSpan]::FromSeconds(1))
        }
        finally {
            if ($workingDirectory) {
                Pop-Location
            }
        }
    }
    while ($true)
}
