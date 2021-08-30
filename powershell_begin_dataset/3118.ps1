









function Set-TrustedHost
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
            throw "Administrator rights are required to set a trusted host!"
        }
    }

    Process{
        $TrustedHost_Path = "WSMan:\localhost\Client\TrustedHosts"

        try{
            $TrustedHost_Value = $TrustedHost -join ","

            if($PSCmdlet.ShouldProcess($TrustedHost_Path))
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