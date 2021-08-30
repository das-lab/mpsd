function Publish-PSResource {

    [OutputType([void])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        
        [Parameter(Mandatory = $true,
            ParameterSetName = "ModuleNameParameterSet",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        
        
        [Parameter(Mandatory = $true,
            ParameterSetName = "ModulePathParameterSet",
            ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ScriptPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        
        
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ModuleLiteralPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ScriptLiteralPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath,

        
        [Parameter(Mandatory = $true,
            ParameterSetName = 'DestinationPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RequiredVersion,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $NuGetApiKey,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        
        [Parameter()]
        [string[]]
        $ReleaseNotes,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        
        [Parameter(ParameterSetName = "ModuleNameParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Exclude,

        
        [Parameter()]
        [switch]
        $Force,

        
        [Parameter()]
        [switch]
        $Prerelease,

        
        [Parameter()]
        [switch]
        $SkipDependenciesCheck,

        
        [Parameter()]
        [switch]
        $Nuspec
    )


    begin { }
    process {
        if ($pscmdlet.ShouldProcess($Name)) {
            if ($Name) {
                
                Write-Verbose -message "Successfully published $Name"
            }
            elseif ($Path) {
                
                Write-Verbose -message "Successfully published $Path"
            }
            elseif ($LiteralPath) {
                
                Write-Verbose -message "Successfully published $LiteralPath"
            }
        }
    }

    end { }
}
