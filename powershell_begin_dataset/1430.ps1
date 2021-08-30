
function New-CJunction
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Target
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( Test-Path -LiteralPath $Link -PathType Container )
    {
        Write-Error "'$Link' already exists."
    }
    else
    {
        Write-Verbose -Message "Creating junction $Link <=> $Target"
        [Carbon.IO.JunctionPoint]::Create( $Link, $Target, $false )
        if( Test-Path $Link -PathType Container ) 
        { 
            Get-Item $Link 
        } 
    }
}

