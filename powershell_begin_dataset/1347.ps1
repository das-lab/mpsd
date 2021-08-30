
function Install-CIisApplication
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
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
        
        [string]
        
        $AppPoolName,

        [Switch]
        
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if( -not $site )
    {
        Write-Error ('[IIS] Website ''{0}'' not found.' -f $SiteName)
        return
    }

    $iisAppPath = Join-CIisVirtualPath $SiteName $VirtualPath

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        Write-Verbose ('IIS://{0}: creating physical path {1}' -f $iisAppPath,$PhysicalPath)
        $null = New-Item $PhysicalPath -ItemType Directory
    }

    $appPoolDesc = ''
    if( $AppPoolName )
    {
        $appPoolDesc = '; appPool: {0}' -f $AppPoolName
    }
    
    $apps = $site.GetCollection()

    $appPath = "/{0}" -f $VirtualPath
    $app = Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    $modified = $false
    if( -not $app )
    {
        Write-Verbose ('IIS://{0}: creating application' -f $iisAppPath)
        $app = $apps.CreateElement('application') |
                    Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
        $app['path'] = $appPath
        $apps.Add( $app ) | Out-Null
        $modified = $true
    }

    if( $app['path'] -ne $appPath )
    {
        $app['path'] = $appPath
        $modified = $true
    }
        
    if( $AppPoolName -and $app['applicationPool'] -ne $AppPoolName)
    {
        $app['applicationPool'] = $AppPoolName
        $modified = $true
    }

    $vdir = $null
    if( $app | Get-Member 'VirtualDirectories' )
    {
        $vdir = $app.VirtualDirectories |
                    Where-Object { $_.Path -eq '/' }
    }

    if( -not $vdir )
    {
        Write-Verbose ('IIS://{0}: creating virtual directory' -f $iisAppPath)
        $vdirs = $app.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        $vdir['path'] = '/'
        $vdirs.Add( $vdir ) | Out-Null
        $modified = $true
    }

    if( $vdir['physicalPath'] -ne $PhysicalPath )
    {
        Write-Verbose ('IIS://{0}: setting physical path {1}' -f $iisAppPath,$PhysicalPath)
        $vdir['physicalPath'] = $PhysicalPath
        $modified = $true
    }

    if( $modified )
    {
        Write-Verbose ('IIS://{0}: committing changes' -f $iisAppPath)
        $app.CommitChanges()
    }

    if( $PassThru )
    {
        return Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    }

}

