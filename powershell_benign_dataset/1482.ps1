













function Publish-NuGetPackage
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $NuspecPath,

        [Parameter(Mandatory=$true)]
        [string]
        
        $NuspecBasePath,

        [string[]]
        
        $Repository = @( 'nuget.org' ),

        [string]
        
        $PackageName,

        [object]
        
        
        
        
        
        $ApiKey
    )

    Set-StrictMode -Version 'Latest'

    $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath '..\bin\NuGet.exe' -Resolve
    if( -not $nugetPath )
    {
        return
    }

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    if( -not $PackageName )
    {
        $PackageName = $manifest.Name
    }

    Push-Location -Path $NuSpecBasePath
    try
    {

        $nupkgPath = Join-Path -Path (Get-Location) -ChildPath ('{0}.{1}.nupkg' -f $PackageName,$manifest.Version)
        if( (Test-Path -Path $nupkgPath -PathType Leaf) )
        {
            Remove-Item -Path $nupkgPath
        }

        foreach( $repoName in $Repository )
        {
            $serverUrl = 'https://{0}' -f $repoName
            $packageUrl = '{0}/api/v2/package/{1}/{2}' -f $serverUrl,$PackageName,$manifest.Version
            try
            {
                $resp = Invoke-WebRequest -Uri $packageUrl -ErrorAction Ignore
                $publish = ($resp.StatusCode -ne 200)
            }
            catch
            {
                $publish = $true
            }

            if( -not $publish )
            {
                Write-Warning ('NuGet package {0} {1} already published to {2}.' -f $PackageName,$manifest.Version,$repoName)
                continue
            }

            if( -not (Test-Path -Path $nupkgPath -PathType Leaf) )
            {
                & $nugetPath pack $NuspecPath -BasePath '.' -NoPackageAnalysis
                if( -not (Test-Path -Path $nupkgPath -PathType Leaf) )
                {
                    Write-Error ('NuGet package ''{0}'' not found.' -f $nupkgPath)
                    return
                }
            }

            $repoApiKey = $null
            if( $ApiKey -is [string] )
            {
                $repoApiKey = $ApiKey
            }
            elseif( $ApiKey -is [hashtable] -and $ApiKey.Contains($repoName) )
            {
                $repoApiKey = $ApiKey[$repoName]
            }
            elseif( $ApiKey )
            {
                Write-Error ('ApiKey parmaeter must be a [string] or a [hashtable], but is a [{0}].' -f $ApiKey.GetType())
                return
            }

            if( -not $repoApiKey )
            {
                $repoApiKey = Read-Host -Prompt ('Please enter your {0} API key' -f $repoName)
                if( -not $repoApiKey )
                {
                    Write-Error -Message ('The {0} API key is required. Package not published to {1}.' -f $repoName)
                    continue
                }
            }

            & $nugetPath push $nupkgPath -ApiKey $repoApiKey -Source $serverUrl

            $resp = Invoke-WebRequest -Uri $packageUrl
            $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $packageUrl }}
        }
    }
    finally
    {
        Pop-Location
    }
}