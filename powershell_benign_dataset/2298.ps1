

 
param()

function Invoke-Process {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        [string[]]$ArgumentList
    )

    $ErrorActionPreference = 'Stop'

    try {
        $stdOutTempFile = "$env:TEMP\$(( New-Guid ).Guid)"
        $stdErrTempFile = "$env:TEMP\$(( New-Guid ).Guid)"

        $startProcessParams = @{
            FilePath               = $FilePath
            RedirectStandardError  = $stdErrTempFile
            RedirectStandardOutput = $stdOutTempFile
            Wait                   = $true
            PassThru               = $true
            NoNewWindow            = $true
        }
        if ($PSCmdlet.ShouldProcess("Process [$($FilePath)]", "Run with args: [$($ArgumentList)]")) {
            if ($ArgumentList) {
                Write-Verbose -Message "$FilePath $ArgumentList"
                $cmd = Start-Process @startProcessParams -ArgumentList $ArgumentList
            }
            else {
                Write-Verbose $FilePath
                $cmd = Start-Process @startProcessParams
            }
            $stdOut = Get-Content -Path $stdOutTempFile -Raw
            $stdErr = Get-Content -Path $stdErrTempFile -Raw
            if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
                $stdOut = $stdOut.Trim()
            }
            if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
                $stdErr = $stdErr.Trim()
            }
            $return = [PSCustomObject]@{
                Name     = $cmd.Name
                Id       = $cmd.Id
                ExitCode = $cmd.ExitCode
                Output   = $stdOut
                Error    = $stdErr
            }
            if ($return.ExitCode -ne 0) {
                throw $return
            }
            else {
                $return
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore
    }
}

