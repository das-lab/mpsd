
function Restart-MrServiceOrDie {



    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [System.ServiceProcess.ServiceController[]]$Service
    )

    BEGIN {
        $StartTime = Get-Date
    }
    
    PROCESS {
        foreach ($s in $Service) {
            $i = [array]::IndexOf($Service, $s)

            Start-Job -Name "RestartService$i" {
                $s | Restart-Service -Force
            } | Out-Null

            while ((Get-Job -Name "RestartService$i").State -ne 'Completed') {
                Write-Verbose -Message "Waiting for service: '$($s.Name)' to restart."
                Start-Sleep -Seconds 5

                if ((New-TimeSpan -Start $StartTime).TotalSeconds -gt 90) {
                    Break
                }

            }

            while (Get-WmiObject -Class Win32_Service -Filter "Name = '$($s.Name)' and State = 'Stop Pending'" -OutVariable HungService) {
                try {
                    Write-Verbose -Message "Killing process ID: '$($HungService | Select-Object -ExpandProperty ProcessId)'"
                    Stop-Process -Id ($HungService | Select-Object -ExpandProperty ProcessId) -Force -ErrorAction Stop

                    if ($PSBoundParameters.WhatIf) {
                        Break
                    }
                    
                    Start-Sleep -Seconds 5
                }
                catch {
                    Write-Warning -Message "An unexpected error has occurred. Error details: $_.Exception.Message"
                }
            }

            if (($s | Get-Service).Status -eq 'Stopped') {
                Write-Verbose -Message "Starting service: '$($s.Name)'"
                $s | Start-Service
            }

            Remove-Job -Name "RestartService$i" -Force -ErrorAction SilentlyContinue

        }
    }

}
