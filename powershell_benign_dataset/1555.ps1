
function Test-MrIpAddress {



    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true)]
        [string[]]$IpAddress,

        [switch]$Detailed
    )

    PROCESS {

        foreach ($Ip in $IpAddress) {
    
            try {
                $Results = $Ip -match ($DetailedInfo = [IPAddress]$Ip)
            }
            catch {
                Write-Output $false
                Continue
            }

            if (-not($PSBoundParameters.Detailed)){
                Write-Output $Results
            }
            else {
                Write-Output $DetailedInfo
            }    
    
        }

    }

}