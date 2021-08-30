
function New-File {
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