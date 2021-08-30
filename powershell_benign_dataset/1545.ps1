
function Start-MrAutoStoppedService {
    


    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,

        [switch]$PassThru
    )

    BEGIN {
        $Params = @{}
        $RemoteParams = @{}

        switch ($PSBoundParameters) {
            {$_.keys -contains 'Credential'} {$Params.Credential = $Credential}
            {$_.keys -contains 'PassThru'} {$RemoteParams.PassThru = $true}
            {$_.keys -contains 'Confirm'} {$RemoteParams.Confirm = $true}
            {$_.keys -contains 'WhatIf'} {$RemoteParams.WhatIf = $true}
        }

    }

    PROCESS {
        $Params.ComputerName = $ComputerName

        Invoke-Command @Params {            
            $Services = Get-WmiObject -Class Win32_Service -Filter {
                State != 'Running' and StartMode = 'Auto'
            }
            
            foreach ($Service in $Services.Name) {
                Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" |
                Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -ne 1} |
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Start-Service @Using:RemoteParams
            }            
        }
    }
}