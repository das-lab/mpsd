
function Clear-CMofAuthoringMetadata
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $tempDir = New-CTempDirectory -Prefix ('Carbon+ClearMofAuthoringMetadata+') -WhatIf:$false

    foreach( $item in (Get-ChildItem -Path $Path -Filter '*.mof') )
    {
        Write-Verbose ('Clearing authoring metadata from ''{0}''.' -f $item.FullName)
        $tempItem = Copy-Item -Path $item.FullName -Destination $tempDir -PassThru -WhatIf:$false
        $inComment = $false
        $inAuthoringComment = $false
        $inConfigBlock = $false;
        Get-Content -Path $tempItem |
            Where-Object {
                $line = $_

                if( $line -like '/`**' )
                {
                    if( $line -like '*`*/' )
                    {
                        return $true
                    }
                    $inComment = $true
                    return $true
                }

                if( $inComment )
                {
                    if( $line -like '*`*/' )
                    {
                        $inComment = $false
                        $inAuthoringComment = $false
                        return $true
                    }

                    if( $line -like '@TargetNode=*' )
                    {
                        $inAuthoringComment = $true
                        return $true
                    }

                    if( $inAuthoringComment )
                    {
                        return ( $line -notmatch '^@(GeneratedBy|Generation(Host|Date))' )
                    }

                    return $true
                }

                if( $line -eq 'instance of OMI_ConfigurationDocument' )
                {
                    $inConfigBlock = $true
                    return $true
                }

                if( $inConfigBlock )
                {
                    if( $line -like '};' )
                    {
                        $inConfigBlock = $false;
                        return $true
                    }

                    return ($line -notmatch '(Author|(Generation(Date|Host)))=');
                }

                return $true

            } | 
            Set-Content -Path $item.FullName
    }
}
