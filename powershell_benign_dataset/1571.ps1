function Get-MrAutoService {
    


    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {        
        $Params = @{}
 
        If ($PSBoundParameters['Credential']) {
            $Params.Credential = $Credential
        }
    }

    PROCESS {
        $Params.ComputerName = $ComputerName

        Invoke-Command @Params {
            $Services = Get-WmiObject -Class Win32_Service -Filter {
                StartMode = 'Auto'
            } -Property Name | Select-Object -ExpandProperty Name
            
            foreach ($Service in $Services) {
                Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" |
                Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -ne 1} |
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Get-Service
            }
        }
    }
}