function Get-MrAutoStoppedService {
    


    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        $Params = @{
        }
 
        If ($PSBoundParameters['Credential']) {
            $Params.Credential = $Credential
        }
    }

    PROCESS {

        $Params.ComputerName = $ComputerName

        Invoke-Command @Params {

            $autoServices = Get-WmiObject -Class Win32_Service -Filter {State != 'Running' and StartMode = 'Auto' and Name != 'ShellHWDetection' and Name != 'SysmonLog'} |
                            Select-Object -ExpandProperty Name

            $delayedServices = Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' |
                               Where-Object {$_.property -contains 'DelayedAutoStart'} |
                               Get-ItemProperty |
                               Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -eq 1} |
                               Select-Object -ExpandProperty PSChildName

            Compare-Object -ReferenceObject $autoServices -DifferenceObject $delayedServices |
            Where-Object {$_.SideIndicator -eq '<='} | 
            Select-Object -Property @{label='ServiceName';expression={$_.InputObject}} |
            Get-Service

        }
    }
}