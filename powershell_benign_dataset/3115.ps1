









function Get-TrustedHost
{
    [CmdletBinding()]
    param(
      
    )

    Begin{
    }

    Process{
        $TrustedHost_Path = "WSMan:\localhost\Client\TrustedHosts"

        try{
            [String]$TrustedHost_Value = (Get-Item -Path $TrustedHost_Path).Value
        }
        catch{
            throw
        }

        if([String]::IsNullOrEmpty($TrustedHost_Value))
        {            
            return
        }

        foreach($TrustedHosts in $TrustedHost_Value.Split(','))
        {
            [pscustomobject] @{
                TrustedHost = $TrustedHosts
            }
        }                                    
    }

    End{

    }
}