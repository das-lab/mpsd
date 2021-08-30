
function New-MrCimSession {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,
 
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {
        $Opt = New-CimSessionOption -Protocol Dcom

        $SessionParams = @{
            ErrorAction = 'Stop'
        }

        If ($PSBoundParameters['Credential']) {
            $SessionParams.Credential = $Credential
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            $SessionParams.ComputerName  = $Computer

            if ((Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue).productversion -match 'Stack: ([3-9]|[1-9][0-9]+)\.[0-9]+') {
                try {
                    Write-Verbose -Message "Attempting to connect to $Computer using the WSMAN protocol."
                    New-CimSession @SessionParams
                }
                catch {
                    Write-Warning -Message "Unable to connect to $Computer using the WSMAN protocol. Verify your credentials and try again."
                }
            }
 
            else {
                $SessionParams.SessionOption = $Opt

                try {
                    Write-Verbose -Message "Attempting to connect to $Computer using the DCOM protocol."
                    New-CimSession @SessionParams
                }
                catch {
                    Write-Warning -Message "Unable to connect to $Computer using the WSMAN or DCOM protocol. Verify $Computer is online and try again."
                }

                $SessionParams.Remove('SessionOption')
            }            
        }
    }
}