
function Install-CIisVirtualDirectory
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [string]
        
        $VirtualPath,
        
        [Parameter(Mandatory=$true)]
        [Alias('Path')]
        [string]
        
        $PhysicalPath,

        [Switch]
        
        
        
        
        
        $Force
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    [Microsoft.Web.Administration.Application]$rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    if( -not $rootApp )
    {
        Write-Error ('Default website application not found.')
        return
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath

    $VirtualPath = $VirtualPath.Trim('/')
    $VirtualPath = '/{0}' -f $VirtualPath

    $vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq $VirtualPath }
    if( $Force -and $vdir )
    {
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'REMOVE' '' ''
        $rootApp.VirtualDirectories.Remove($vdir)
        $site.CommitChanges()
        $vdir = $null

        $site = Get-CIisWebsite -Name $SiteName
        $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    }

    $modified = $false

    if( -not $vdir )
    {
        [Microsoft.Web.Administration.ConfigurationElementCollection]$vdirs = $rootApp.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'VirtualPath' '' $VirtualPath
        $vdir['path'] = $VirtualPath
        [void]$vdirs.Add( $vdir )
        $modified = $true
    }

    if( $vdir['physicalPath'] -ne $PhysicalPath )
    {
        Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'PhysicalPath' $vdir['physicalPath'] $PhysicalPath
        $vdir['physicalPath'] = $PhysicalPath
        $modified = $true
    }

    if( $modified )
    {
        $site.CommitChanges()
    }
}

