
function Stop-Poshbot {
    
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'high')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int[]]$Id,

        [switch]$Force
    )

    begin {
        $remove = @()
    }

    process {
        foreach ($jobId in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess($jobId, 'Stop PoshBot')) {
                $bot = $script:botTracker[$jobId]
                if ($bot) {
                    Write-Verbose -Message "Stopping PoshBot Id: $jobId"
                    Stop-Job -Id $jobId -Verbose:$false
                    Remove-Job -Id $JobId -Verbose:$false
                    $remove += $jobId
                } else {
                    throw "Unable to find PoshBot instance with Id [$Id]"
                }
            }
        }
    }

    end {
        
        $remove | ForEach-Object {
            $script:botTracker.Remove($_)
        }
    }
}

Export-ModuleMember -Function 'Stop-Poshbot'
