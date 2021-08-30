









function Find-PSResource {
    [OutputType([PSCustomObject[]])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        
        
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Module', 'Script', 'DscResource', 'RoleCapability', 'Command')]
        [string[]]
        $Type,

        
        
        [Parameter(ParameterSetName = "ResourceParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        
        
        [Parameter()]
        [switch]
        $AllVersions,

        
        
        [Parameter()]
        [switch]
        $Prerelease,

        
        
        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Tag,

        
        
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Filter,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        
        
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "PackageParameterSet")]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "ScriptParameterSet")]
        [PSCredential]
        $Credential,

        
        
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [switch]
        $IncludeDependencies,

        
        
        
        
        
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [ValidateNotNull()]
        [ValidateSet('DscResource', 'Cmdlet', 'Function', 'RoleCapability', 'Workflow')]
        [string[]]
        $Includes,

        
        
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $DscResource,

        
        
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $RoleCapability,

        
        
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $Command

    )

    begin {
        
    }
    process {

        
        $foundResources

        foreach ($n in $name) {

            if ($pscmdlet.ShouldProcess($n)) {

                $PSResource = [PSCustomObject] @{
                    Name        = $Name
                    Version     = "placeholder-for-module-version"
                    Type        = $Type
                    Description = "placeholder-for-description"
                }

                $foundResources += $PSResource
            }
        }

        return $foundResources
    }
    end { }
}
