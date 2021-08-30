
function New-CTempDirectory
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([IO.DirectoryInfo])]
    param(
        [string]
        
        $Prefix
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $tempDir = [IO.Path]::GetRandomFileName()
    if( $Prefix )
    {
        $Prefix = Split-Path -Leaf -Path $Prefix
        $tempDir = '{0}{1}' -f $Prefix,$tempDir
    }

    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' -Verbose:$VerbosePreference
}

Set-Alias -Name 'New-TempDir' -Value 'New-CTempDirectory'
