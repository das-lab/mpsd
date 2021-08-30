
function Get-MrOSInfo {



    [CmdletBinding()]
    param (
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )

    $Params = @{}

    if ($PSBoundParameters.CimSession) {
        $Params.CimSession = $CimSession
    }
   
    $OSInfo = Get-CimInstance @Params -ClassName Win32_OperatingSystem -Property Caption, BuildNumber, OSArchitecture, CSName

    $OSVersion = Invoke-CimMethod @Params -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                    hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\Windows NT\CurrentVersion'; sValueName='ReleaseId'}

    $PSVersion = Invoke-CimMethod @Params -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                    hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'; sValueName='PowerShellVersion'}

    foreach ($OS in $OSInfo) {
        if (-not $PSBoundParameters.CimSession) {
            $OSVersion.PSComputerName = $OS.CSName
            $PSVersion.PSComputerName = $OS.CSName
        }
        
        $PS = $PSVersion | Where-Object PSComputerName -eq $OS.CSName
                    
        if (-not $PS.sValue) {
            $Params2 = @{}
            
            if ($PSBoundParameters.CimSession) {
                $Params2.CimSession = $CimSession | Where-Object ComputerName -eq $OS.CSName
            }

            $PS = Invoke-CimMethod @Params2 -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                        hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine'; sValueName='PowerShellVersion'}
        }
            
        [pscustomobject]@{
            ComputerName = $OS.CSName
            OperatingSystem = $OS.Caption
            Version = ($OSVersion | Where-Object PSComputerName -eq $OS.CSName).sValue
            BuildNumber = $OS.BuildNumber
            OSArchitecture = $OS.OSArchitecture
            PowerShellVersion = $PS.sValue
                                        
        }
            
    }

}
