














function Publish-PowerShellGalleryModule
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ModulePath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ReleaseNotesPath,

        [string]
        
        $Name,

        [string]
        
        $ApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        
        $LicenseUri,

        [string[]]
        
        $Tags,

        [string]
        
        $ProjectUri
    )

    Set-StrictMode -Version 'Latest'

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    if( -not $Name )
    {
        $Name = $manifest.Name
    }

    if( Get-Module -ListAvailable -Name 'PowerShellGet' )
    {
        if( -not (Find-Module -Name $Name -RequiredVersion $manifest.Version -Repository 'PSGallery' -ErrorAction Ignore) )
        {
            $releaseNotes = Get-ModuleReleaseNotes -ManifestPath $ManifestPath -ReleaseNotesPath $ReleaseNotesPath
            Write-Verbose -Message ('Publishing to PowerShell Gallery.')
            if( -not $ApiKey )
            {
                $ApiKey = Read-Host -Prompt ('Please enter PowerShell Gallery API key')
            }

            Publish-Module -Path $ModulePath `
                           -Repository 'PSGallery' `
                           -NuGetApiKey $ApiKey `
                           -LicenseUri $LicenseUri `
                           -ReleaseNotes $releaseNotes `
                           -Tags $Tags `
                           -ProjectUri $ProjectUri

            Find-Module -Name $Name -RequiredVersion $manifest.Version -Repository 'PSGallery'
        }
        else
        {
            Write-Warning -Message ('{0} {1} already exists in the PowerShell Gallery.' -f $Name,$manifest.Version)
        }
    }
    else
    {
        Write-Error -Message ('Unable to publish to PowerShell Gallery: PowerShellGet module not found.')
    }

}