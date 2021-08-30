
function Save-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        
        [Parameter(ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateSet('Module', 'Script', 'Library')]
        [string[]]
        $Type,

        
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [string]
        $Path,

        
        
        
        
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        
        [Parameter()]
        [switch]
        $Force,

        
        [Parameter(ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [switch]
        $Prerelease,

        
        [Parameter()]
        [switch]
        $AcceptLicense,

        
        [Parameter()]
        [switch]
        $AsNupkg,

        
        [Parameter()]
        [switch]
        $IncludeAllRuntimes
    )


    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Find-PSResource $n) {

                    
                    write-verbose -message "Successfully saved $n"
                }
            }
        }
    }
    end { }
}
