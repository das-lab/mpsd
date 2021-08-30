









function Remove-TrustedHost
{
    [CmdletBinding(DefaultParameterSetName='TrustedHost', SupportsShouldProcess=$true, ConfirmImpact="High")]
    param(
        [Parameter(
            ParameterSetName='TrustedHost',
            Position=0,
            Mandatory=$true)]
        [String[]]$TrustedHost,

        [Parameter(
            ParameterSetName='All',
            Position=0,
            Mandatory=$true,
            HelpMessage="Remove all trusted host(s)")]
        [switch]$All
    )

    Begin{
        if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            throw "Administrator rights are required to remove a trusted host!"
        }
    }

    Process{
        $TrustedHost_Path = "WSMan:\localhost\Client\TrustedHosts"
        [System.Collections.ArrayList]$TrustedHosts = @()

        try{            
            $TrustedHost_Value = (Get-Item -Path $TrustedHost_Path).Value
            $TrustedHost_ValueOrg = $TrustedHost_Value

            if($PSCmdlet.ParameterSetName -eq "TrustedHost")
            {
                if(-not([String]::IsNullOrEmpty($TrustedHost_Value)))
                {
                    $TrustedHosts += $TrustedHost_Value.Split(',')
                }                

                foreach($TrustedHost2 in $TrustedHost)
                {                
                    if($TrustedHosts -notcontains $TrustedHost2)
                    {
                        Write-Warning -Message "Trusted host ""$TrustedHost2"" does not exists in ""$TrustedHost_Path"" and will be skipped."
                        continue
                    }

                    $TrustedHosts.Remove($TrustedHost2)                    
                }

                $TrustedHost_Value = $TrustedHosts -join ","
            }
            elseif($PSCmdlet.ParameterSetName -eq "All")
            {
                $TrustedHost_Value = ""
            }            

            if(($TrustedHost_Value -ne $TrustedHost_ValueOrg) -and ($PSCmdlet.ShouldProcess($TrustedHost_Path)))
            {
                Set-Item -Path $TrustedHost_Path -Value $TrustedHost_Value -Force
            }    
        }
        catch{
            throw
        }
    }

    End{

    }
}