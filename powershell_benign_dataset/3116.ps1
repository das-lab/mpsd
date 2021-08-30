









function Add-TrustedHost
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true)]
        [String[]]$TrustedHost
    )

    Begin{
        if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            throw "Administrator rights are required to add a trusted host!"
        }
    }

    Process{
        $TrustedHost_Path = "WSMan:\localhost\Client\TrustedHosts"
        [System.Collections.ArrayList]$TrustedHosts = @()

        try{
            [String]$TrustedHost_Value = (Get-Item -Path $TrustedHost_Path).Value
            $TrustedHost_Value = (Get-Item -Path $TrustedHost_Path).Value
            $TrustedHost_ValueOrg = $TrustedHost_Value

            if(-not([String]::IsNullOrEmpty($TrustedHost_Value)))
            {
                $TrustedHosts = $TrustedHost_Value.Split(',')
            }
            
            foreach($TrustedHost2 in $TrustedHost)
            {
                if($TrustedHosts -contains $TrustedHost2)
                {
                    Write-Warning -Message "Trusted host ""$TrustedHost2"" already exists in ""$TrustedHost_Path"" and will be skipped."
                    continue
                }

                [void]$TrustedHosts.Add($TrustedHost2)

                $TrustedHost_Value = $TrustedHosts -join ","
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