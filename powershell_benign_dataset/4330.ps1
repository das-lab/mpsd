function Get-EnvironmentVariable
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [int]
        $Target
    )

    if ($Target -eq $script:EnvironmentVariableTarget.Process)
    {
        return [System.Environment]::GetEnvironmentVariable($Name)
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.Machine)
    {
        if ($Name -eq "path")
        {
            
            
            
            
            
            
            
            $hklmHive = [Microsoft.Win32.Registry]::LocalMachine
            $EnvRegKey = $hklmHive.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $FALSE)
            $itemPropertyValue = $EnvRegKey.GetValue($Name, "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            return $itemPropertyValue
        }
        else
        {
            $itemPropertyValue = Microsoft.PowerShell.Management\Get-ItemProperty -Path $script:SystemEnvironmentKey -Name $Name -ErrorAction SilentlyContinue

            if($itemPropertyValue)
            {
                return $itemPropertyValue.$Name
            }
        }
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.User)
    {
        $itemPropertyValue = Microsoft.PowerShell.Management\Get-ItemProperty -Path $script:UserEnvironmentKey -Name $Name -ErrorAction SilentlyContinue

        if($itemPropertyValue)
        {
            return $itemPropertyValue.$Name
        }
    }
}