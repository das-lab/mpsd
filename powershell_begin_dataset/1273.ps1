
function Resolve-CRelativePath
{
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]
        
        [Alias('FullName')]
        $Path,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromDirectory')]
        [string]
        
        $FromDirectory,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromFile')]
        [string]
        
        $FromFile
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        $relativePath = New-Object System.Text.StringBuilder 260
        switch( $pscmdlet.ParameterSetName )
        {
            'FromFile'
            {
                $fromAttr = [IO.FileAttributes]::Normal
                $fromPath = $FromFile
            }
            'FromDirectory'
            {
                $fromAttr = [IO.FileAttributes]::Directory
                $fromPath = $FromDirectory
            }
        }
        
        $toPath = $Path
        if( $Path | Get-Member -Name 'FullName' )
        {
            $toPath = $Path.FullName
        }
        
        $toAttr = [IO.FileAttributes]::Normal
        $converted = [Carbon.IO.Path]::PathRelativePathTo( $relativePath, $fromPath, $fromAttr, $toPath, $toAttr )
        $result = if( $converted ) { $relativePath.ToString() } else { $null }
        return $result
    }
}
