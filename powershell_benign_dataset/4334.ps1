function ValidateAndSet-PATHVariableIfUserAccepts
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Scope,

        [Parameter(Mandatory=$true)]
        [string]
        $ScopePath,

        [Parameter()]
        [Switch]
        $NoPathUpdate,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        $Request
    )

    if(-not $script:IsWindows)
    {
        return
    }

    Set-PSGetSettingsVariable

    
    if($Scope -eq 'AllUsers')
    {
        $envVariableTarget = $script:EnvironmentVariableTarget.Machine
        $scriptPATHPromptQuery=$LocalizedData.ScriptPATHPromptQuery -f $ScopePath
        $scopeSpecificKey = 'AllUsersScope_AllowPATHChangeForScripts'
    }
    else
    {
        $envVariableTarget = $script:EnvironmentVariableTarget.User
        $scriptPATHPromptQuery=$LocalizedData.ScriptPATHPromptQuery -f $ScopePath
        $scopeSpecificKey = 'CurrentUserScope_AllowPATHChangeForScripts'
    }

    $AlreadyPromptedForScope = $script:PSGetSettings.Contains($scopeSpecificKey)
    Write-Debug "Already prompted for the current scope:$AlreadyPromptedForScope"

    if(-not $AlreadyPromptedForScope)
    {
        
        Set-PSGetSettingsVariable -Force

        $AlreadyPromptedForScope = $script:PSGetSettings.Contains($scopeSpecificKey)
        Write-Debug "After reading contents of PowerShellGetSettings.xml file, the Already prompted for the current scope:$AlreadyPromptedForScope"

        if($AlreadyPromptedForScope)
        {
            return
        }

        $userResponse = $false

        if(-not $NoPathUpdate)
        {
            $scopePathEndingWithBackSlash = "$scopePath\"

            
            if( (($env:PATH -split ';') -notcontains $scopePath) -and
                (($env:PATH -split ';') -notcontains $scopePathEndingWithBackSlash))
            {
                if($Force)
                {
                    $userResponse = $true
                }
                else
                {
                    $scriptPATHPromptCaption = $LocalizedData.ScriptPATHPromptCaption

                    if($Request)
                    {
                        $userResponse = $Request.ShouldContinue($scriptPATHPromptQuery, $scriptPATHPromptCaption)
                    }
                    else
                    {
                        $userResponse = $PSCmdlet.ShouldContinue($scriptPATHPromptQuery, $scriptPATHPromptCaption)
                    }
                }

                if($userResponse)
                {
                    $currentPATHValue = Get-EnvironmentVariable -Name 'PATH' -Target $envVariableTarget

                    if((($currentPATHValue -split ';') -notcontains $scopePath) -and
                       (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
                    {
                        
                        
                        Set-EnvironmentVariable -Name 'PATH' `
                                                -Value "$currentPATHValue;$scopePath" `
                                                -Target $envVariableTarget

                        Write-Verbose ($LocalizedData.AddedScopePathToPATHVariable -f ($scopePath,$Scope))
                    }

                    
                    
                    
                    $target = $script:EnvironmentVariableTarget.Process
                    $currentPATHValue = Get-EnvironmentVariable -Name 'PATH' -Target $target

                    if((($currentPATHValue -split ';') -notcontains $scopePath) -and
                       (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
                    {
                        
                        
                        Set-EnvironmentVariable -Name 'PATH' `
                                                -Value "$currentPATHValue;$scopePath" `
                                                -Target $target

                        Write-Verbose ($LocalizedData.AddedScopePathToProcessSpecificPATHVariable -f ($scopePath,$Scope))
                    }
                }
            }
        }

        
        $script:PSGetSettings[$scopeSpecificKey] = $userResponse

        Save-PSGetSettings
    }
}