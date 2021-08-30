function Get-ValidModuleLocation
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LocationString,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParameterName,

        [Parameter()]
        $Credential,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential
    )

    
    if(-not (Microsoft.PowerShell.Management\Test-Path $LocationString))
    {
        
        if(($LocationString -notmatch 'LinkID') -and
           -not ($LocationString.EndsWith('/nuget/v2', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('/nuget/v2/', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('/nuget', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('/nuget/', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('index.json', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('index.json/', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('/api/v2', [System.StringComparison]::OrdinalIgnoreCase)) -and
           -not ($LocationString.EndsWith('/api/v2/', [System.StringComparison]::OrdinalIgnoreCase))
            )
        {
            $tempLocation = $null

            if($LocationString.EndsWith('/', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $tempLocation = $LocationString + 'api/v2/'
            }
            else
            {
                $tempLocation = $LocationString + '/api/v2/'
            }

            if($tempLocation)
            {
                
                $tempLocation = Resolve-Location -Location $tempLocation `
                                                 -LocationParameterName $ParameterName `
                                                 -Credential $Credential `
                                                 -Proxy $Proxy `
                                                 -ProxyCredential $ProxyCredential `
                                                 -ErrorAction SilentlyContinue `
                                                 -WarningAction SilentlyContinue
                if($tempLocation)
                {
                   return $tempLocation
                }
                
            }
        }

        
        $LocationString = Resolve-Location -Location $LocationString `
                                           -LocationParameterName $ParameterName `
                                           -Credential $Credential `
                                           -Proxy $Proxy `
                                           -ProxyCredential $ProxyCredential `
                                           -CallerPSCmdlet $PSCmdlet
    }

    return $LocationString
}