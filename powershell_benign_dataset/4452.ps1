
function Update-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("PatchVersion", "MinorVersion", "MajorVersion")]
        [string]
        $UpdateTo,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        
        [Parameter()]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        
        [Parameter()]
        [Switch]
        $Force,

        
        [Parameter()]
        [Switch]
        $Prerelease,

        
        [Parameter()]
        [switch]
        $AcceptLicense,

        
        [Parameter()]
        [switch]
        $PassThru
    )

    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Get-InstalledResource $n) {
                    
                    write-verbose -message "Successfully updated $n"
                }
            }
        }
    }
    end { }

}
