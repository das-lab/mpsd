











$siteName = 'CarbonSetIisMimeMap'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisWebsite -Name $siteName -Binding 'http/*:48284:*' -Path $TestDir
}

function Stop-Test
{
    Remove-IisWebsite -Name $siteName
}

function Test-ShouldCreateNewMimeMapForServer
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'
    
    $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
    Assert-Null $mimeMap
    
    try
    {
        $result = Set-IisMimeMap -FileExtension $fileExtension -MimeType $mimeType
        Assert-Null $result 'objects returned from Set-IisMimeMap'
        
        $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
        Assert-NotNull $mimeMap
        Assert-Equal $mimeMap.FileExtension $fileExtension
        Assert-Equal $mimeMap.MimeType $mimeType
    }
    finally
    {
        $result = Remove-IisMimeMap -FileExtension $fileExtension
        Assert-Null $result 'objects returned from Remove-IisMimeMap'
    }
}

function Test-ShouldUpdateExistingMimeMapForServer
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'
    $mimeType2 = 'text/html'
    
    $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
    Assert-Null $mimeMap
    
    try
    {
        Set-IisMimeMap -FileExtension $fileExtension -MimeType $mimeType
        $result = Set-IisMimeMap -FileExtension $fileExtension -MimeType $mimeType2
        Assert-Null $result 'objects returned from Set-IisMimeMap'
        
        $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
        Assert-NotNull $mimeMap
        Assert-Equal $mimeMap.FileExtension $fileExtension
        Assert-Equal $mimeMap.MimeType $mimeType2
    }
    finally
    {
        Remove-IisMimeMap -FileExtension $fileExtension
    }
}

function Test-ShouldSupportWhatIf
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'

    try
    {    
        $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
        Assert-Null $mimeMap
        
        Set-IisMimeMap -FileExtension $fileExtension -MimeType $mimeType -WhatIf
        
        $mimeMap = Get-IisMimeMap -FileExtension $fileExtension
        Assert-Null $mimeMap
    }
    finally
    {
        Remove-IisMimeMap -FileExtension $fileExtension
    }    
}

function Test-ShouldAddMimeMapForSite
{
    Install-IisVirtualDirectory -SiteName $siteName -VirtualPath '/recurse' -PhysicalPath $PSScriptRoot

    Set-IisMimeMap -SiteName $siteName -FileExtension '.carbon' -MimeType 'carbon/test+site'
    Set-IisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon' -MimeType 'carbon/test+vdir'

    try
    {
        $mime = Get-IisMimeMap -SiteName $siteName -FileExtension '.carbon'
        Assert-NotNull $mime
        Assert-Equal 'carbon/test+site' $mime.MimeType

        Remove-IisMimeMap -SiteName $siteName -FileExtension '.carbon'
        $mime = Get-IisMimeMap -SiteName $siteName -FileExtension '.carbon'
        Assert-Null $mime

        $mime = Get-IisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        Assert-NotNull $mime
        Assert-Equal 'carbon/test+vdir' $mime.MimeType

        Remove-IisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        $mime = Get-IisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        Assert-Null $mime
    }
    finally
    {
        Remove-IisMimeMap -FileExtension '.carbon'
    }
}
