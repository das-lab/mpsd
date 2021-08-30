function Get-InstalledModule
{
    
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=526863')]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter()]
        [switch]
        $AllVersions,

        [Parameter()]
        [switch]
        $AllowPrerelease
    )

    Process
    {
        $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                                                       -Name $Name `
                                                       -MinimumVersion $MinimumVersion `
                                                       -MaximumVersion $MaximumVersion `
                                                       -RequiredVersion $RequiredVersion `
                                                       -AllVersions:$AllVersions `
                                                       -AllowPrerelease:$AllowPrerelease

        if(-not $ValidationResult)
        {
            
            
            return
        }

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule
        if($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        PackageManagement\Get-Package @PSBoundParameters | Microsoft.PowerShell.Core\ForEach-Object {New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeModule}
    }
}