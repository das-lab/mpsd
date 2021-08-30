
function Get-MrService {



    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]        
        [string[]]$Name = '*',

        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )

    $ServiceParams = @{}

    if ($PSBoundParameters.CimSession) {
        $ServiceParams.CimSession = $CimSession
    }    

    foreach ($n in $Name) {
        if ($n -match '\*') {
            $n = $n -replace '\*', '%'
        }
        
        $Services = Get-CimInstance -ClassName Win32_Service -Filter "Name like '$n'" @ServiceParams
        
        foreach ($Service in $Services) {

            if ($Service.ProcessId -ne 0) {
                $ProcessParams = @{}

                if ($PSBoundParameters.CimSession) {
                    $ProcessParams.CimSession = $CimSession | Where-Object ComputerName -eq $Service.SystemName
                }

                $Process = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = '$($Service.ProcessId)'" @ProcessParams
            }
            else {
                $Process = ''
            }
    
            [pscustomobject]@{
                ComputerName = $Service.SystemName
                Status = $Service.State
                Name = $Service.Name
                DisplayName = $Service.DisplayName
                StartTime = $Process.CreationDate
            }

        }

    }
    
}