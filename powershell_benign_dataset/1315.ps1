

if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Install-CWindowsFeature
    {
        
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            
            [Alias('Features')]
            $Name,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            
            $Iis,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            
            $IisHttpRedirection,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            
            $Msmq,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            
            $MsmqHttpSupport,
            
            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            
            $MsmqActiveDirectoryIntegration
        )
        
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
        Write-Warning -Message ('Install-CWindowsFeature is obsolete and will be removed in a future major version of Carbon.')

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }
        
        if( $pscmdlet.ParameterSetName -eq 'ByFlag' )
        {
            $Name = Resolve-WindowsFeatureName -Name $PSBoundParameters.Keys
        }
        
        $componentsToInstall = $Name | 
                                    ForEach-Object {
                                        if( (Test-CWindowsFeature -Name $_) )
                                        {
                                            $_
                                        }
                                        else
                                        {
                                            Write-Error ('Windows feature {0} not found.' -f $_)
                                        } 
                                    } |
                                    Where-Object { -not (Test-CWindowsFeature -Name $_ -Installed) }
       
        if( -not $componentsToInstall -or $componentsToInstall.Length -eq 0 )
        {
            return
        }
        
        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$componentsToInstall'", "install" ) )
        {
            if( $useServerManager )
            {
                servermanagercmd.exe -install $componentsToInstall
            }
            else
            {
                $featuresArg = $componentsToInstall -join ';'
                & ocsetup.exe $featuresArg
                $ocsetup = Get-Process 'ocsetup' -ErrorAction SilentlyContinue
                if( -not $ocsetup )
                {
                    Write-Error "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                    return
                }
                $ocsetup.WaitForExit()
            }
        }
    }
    
    Set-Alias -Name 'Install-WindowsFeatures' -Value 'Install-CWindowsFeature'
    Set-Alias -Name 'Install-WindowsFeature' -Value 'Install-CWindowsFeature'
}
