

if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Get-CWindowsFeature
    {
        
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]
            
            $Name
        )
        
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
        Write-Warning -Message ('Get-CWindowsFeature is obsolete and will be removed in a future major version of Carbon.')

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }
        
        if( $useOCSetup )
        {
            Get-WmiObject -Class Win32_OptionalFeature |
                Where-Object {
                    if( $Name )
                    {
                        return ($_.Name -like $Name)
                    }
                    else
                    {
                        return $true
                    }
                } |
                ForEach-Object {
                    $properties = @{
                        Installed = ($_.InstallState -eq 1);
                        Name = $_.Name;
                        DisplayName = $_.Caption;
                    }
                    New-Object PsObject -Property $properties
                }
        }
        elseif( $useServerManager )
        {
            servermanagercmd.exe -query | 
                Where-Object { 
                    if( $Name )
                    {
                        return ($_ -match ('\[{0}\]$' -f [Text.RegularExpressions.Regex]::Escape($Name)))
                    }
                    else
                    {
                        return $true
                    }
                } |
                Where-Object { $_ -match '\[(X| )\] ([^[]+) \[(.+)\]' } | 
                ForEach-Object { 
                    $properties = @{ 
                        Installed = ($matches[1] -eq 'X'); 
                        Name = $matches[3]
                        DisplayName = $matches[2]; 
                    }
                    New-Object PsObject -Property $properties
               }
        }
        else
        {
            Write-Error $supportNotFoundErrorMessage
        }        
    }

    Set-Alias -Name 'Get-WindowsFeature' -Value 'Get-CWindowsFeature'
}
