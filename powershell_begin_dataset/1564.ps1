
function Get-MrRemotePSSession {



    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME ,
        
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        $Params = @{
            ResourceURI = 'shell'
            Enumerate = $true
        }

        if ($PSBoundParameters.Credential) {
            $Params.Credential = $Credential
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            $Params.ConnectionURI = "http://$($Computer):5985/wsman"

            Get-WSManInstance @Params |
            Select-Object -Property @{label='PSComputerName';expression={$Computer}}, Name, Owner, ClientIP, State        
        }
    }

}