











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetAllMimeTypes
{
    $mimeMap = Get-IisMimeMap
    Assert-NotNull $mimeMap
    Assert-True ($mimeMap.Length -gt 0)
    
    $mimeMap | ForEach-Object {
        Assert-True ($_.FileExtension -like '.*') ('invalid file extension ''{0}''' -f $_.FileExtension)
        Assert-True ($_.MimeType -like '*/*') 'invalid mime type'
    }
}

function Test-ShouldGetWildcardFileExtension
{
    $mimeMap = Get-IisMimeMap -FileExtension '.htm*'
    Assert-NotNull $mimeMap
    Assert-Equal 2 $mimeMap.Length
    Assert-Equal '.htm' $mimeMap[0].FileExtension
    Assert-Equal 'text/html' $mimeMap[0].MimeType
    Assert-Equal '.html' $mimeMap[1].FileExtension
    Assert-Equal 'text/html' $mimeMap[1].MimeType
}


function Test-ShouldGetWildcardMimeType
{
    $mimeMap = Get-IisMimeMap -MimeType 'text/*'
    Assert-NotNull $mimeMap
    Assert-True ($mimeMap.Length -gt 1)
    $mimeMap | ForEach-Object {
        Assert-True ($_.MimeType -like 'text/*')
    }
}

