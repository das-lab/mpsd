













function New-TempDirectory
{
    
    param(
        [Parameter(Position=0)]
        [string]
        
        $Prefix
    )
    
    Set-StrictMode -Version 'Latest'

    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    if( $Prefix )
    {
        $Prefix = Split-Path -Leaf -Path $Prefix
        $newTmpDirName = '{0}-{1}' -f $Prefix,$newTmpDirName
    }
    
    New-Item (Join-Path -Path $env:TEMP -ChildPath $newTmpDirName) -Type Directory
}


Set-Alias -Name 'New-TempDir' -Value 'New-TempDirectory'

