function Uninstall-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        
        
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObject')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $AllVersions,

        
        [Parameter()]
        [Switch]
        $Force,

        
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $Prerelease
    )

    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Get-PSResource $n) {
                    
                    Write-Verbose -message "Successfully uninstalled $n"
                }
            }
        }
    }
    end { }
}
