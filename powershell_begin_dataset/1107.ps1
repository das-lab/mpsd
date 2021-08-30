











$Port = 9878
$SiteName = 'TestApplication'
$AppName = 'App'
$WebConfig = Join-Path $TestDir web.config
$AppPoolName = 'TestApplication'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-IisWebsite -Name $SiteName
    Install-IisAppPool -Name $AppPoolName
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( TEst-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function Stop-Test
{
    Uninstall-IisWebsite -Name $SiteName
}

function Invoke-InstallApplication($Path = $TestDir)
{
    $result = Install-IISApplication -SiteName $SiteName -Name $AppName -Path $Path -AppPoolName $AppPoolName -PassThru
    Assert-NoError
    Assert-NotNull $result
    Assert-Is $result ([Microsoft.Web.Administration.Application])
    Assert-FileDoesNotExist $WebConfig
}

function Test-ShouldNotReturnAnything($Path = $TestDir)
{
    $result = Install-IISApplication -SiteName $SiteName -Name $AppName -Path $Path 
    Assert-NoError
    Assert-Null $result
    $result = Install-IISApplication -SiteName $SiteName -Name $AppName -Path $env:TEMP
    Assert-NoError
    Assert-Null $result
}

function Test-ShouldCreateApplication
{
    Invoke-InstallApplication
    Assert-ApplicationRunning
    $app = Get-IisApplication -SiteName $SiteName -VirtualPath $AppName
    Assert-NotNull $app
    Assert-Equal $AppPoolName $app.ApplicationPoolName
}

function Test-ShouldResolveApplicationPhysicalPath
{
    Invoke-InstallApplication -Path "$TestDir\..\..\Test\IIS"
    $physicalPath = Get-IisApplication -SiteName $SiteName -Name $AppName | 
                        Select-Object -ExpandProperty PhysicalPath
    Assert-Like $TestDir $physicalPath
}

function Test-ShouldChangePathOfExistingApplication
{
    Invoke-InstallApplication -Path "$TestDir\..\.."
    $app = Get-IisApplication -SiteName $SiteName -Name $AppName
    Assert-NotNull $app
    Assert-Equal ([IO.Path]::GetFullPath( "$TestDir\..\.." )) $app.PhysicalPath

    Invoke-InstallApplication -Path $TestDir
    $app = Get-IisApplication -SiteName $SiteName -Name $AppName
    Assert-NotNull $app
    Assert-Equal $TestDir $app.PhysicalPath
}

function Test-ShouldUpdatePath
{
    Invoke-InstallApplication -Path $env:SystemRoot
    Invoke-InstallApplication
    Assert-ApplicationRunning
    $result = Install-IisApplication -SiteName $SiteName -VirtualPath $AppName -PhysicalPath $TestDir -AppPoolName $AppPoolName
    Assert-Null $result
}

function Test-ShouldUpdateApplicationPool
{
    $result = Install-IISApplication -SiteName $SiteName -Name $AppName -Path $TestDir -PassThru
    Assert-NoError
    Assert-NotNull $result
    Assert-Equal 'DefaultAppPool' $result.ApplicationPoolName
    Assert-ApplicationRunning

    $result = Install-IisApplication -SiteName $SiteName -Name $AppName -PhysicalPath $TestDir -AppPoolName $AppPoolName -PassThru
    Assert-NoError
    Assert-NotNull $result
    Assert-Equal $AppPoolName $result.ApplicationPoolName

    $result = Install-IisApplication -SiteName $SiteName -Name $AppName -PhysicalPath $TestDir -AppPoolName $AppPoolName -PassThru
    Assert-NoError
    Assert-NotNull $result

    $result = Install-IisApplication -SiteName $SiteName -Name $AppName -PhysicalPath $TestDir -PassThru
    Assert-NoError
    Assert-NotNull $result
    Assert-Equal $AppPoolName $result.ApplicationPoolName
}

function Test-ShouldCreateApplicationDirectory
{
    $appDir = Join-Path $TestDir ApplicationDirectory
    if( Test-Path $appDir -PathType Container )
    {
        Remove-Item $appDir -Force
    }

    try
    {
        $result = Invoke-InstallApplication -Path $appDir
        Assert-Null $result
        Assert-DirectoryExists $appDir
    }
    finally
    {
        if( Test-Path $appDir -PathType Container )
        {
            Remove-Item $appDir -Force
        }
    }
}

function Assert-ApplicationRunning($appName)
{
    $html = Read-Url "http://localhost:$Port/$appName/NewWebsite.html"
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new application.'   
}

function Read-Url($Url)
{
    $browser = New-Object Net.WebClient
    $numTries = 0
    $maxTries = 5
    do
    {
        try
        {
            return $browser.downloadString( $Url )
        }
        catch
        {
            Write-Verbose "Error downloading '$Url': $_"
            $numTries++
            Start-Sleep -Milliseconds 100
        }
    }
    while( $numTries -lt $maxTries )
}

