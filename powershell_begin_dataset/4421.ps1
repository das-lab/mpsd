function Get-InstalledScript
{
    
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=619790')]
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
        [Switch]
        $AllowPrerelease
    )

    Process
    {
        $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                                                       -Name $Name `
                                                       -MinimumVersion $MinimumVersion `
                                                       -MaximumVersion $MaximumVersion `
                                                       -RequiredVersion $RequiredVersion `
                                                       -AllowPrerelease:$AllowPrerelease

        if(-not $ValidationResult)
        {
            
            
            return
        }

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlockForScriptCmdlets
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeScript
        if($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        PackageManagement\Get-Package @PSBoundParameters | Microsoft.PowerShell.Core\ForEach-Object {New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeScript}
    }
}