function Stop-MrPendingService {



    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    PROCESS {    
        [array]$Computer += $ComputerName    
    }

    END {
    
        $Params = @{
            ComputerName = $Computer
        }

        If ($PSBoundParameters.Credential) {
            $Params.Credential = $Credential
        }

        Invoke-Command @Params {
            Get-WmiObject -Class Win32_Service -Filter {state = 'Stop Pending'} |
            ForEach-Object {Stop-Process -Id $_.ProcessId -Force -PassThru}
        }
    
    }

}