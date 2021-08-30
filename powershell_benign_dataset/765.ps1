
function Import-FileNoWildcard {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    begin {
    }

    process {
        
        $paths = @()
        foreach ($aPath in $Path) {
            if (!(Test-Path -LiteralPath $aPath)) {
                $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                $psCmdlet.WriteError($errRecord)
                continue
            }

            
            $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
        }

        foreach ($aPath in $paths) {
            if ($pscmdlet.ShouldProcess($aPath, 'Operation')) {
                
                $aPath
            }
        }
    }

    end {
    }
}