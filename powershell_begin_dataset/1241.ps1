












[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string[]]
    
    $Path,
    
    [string]
    $Filter,

    [string[]]
    $Include,

    [string[]]
    $Exclude,

    [Switch]
    $Recurse
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-Carbon.ps1' -Resolve) -Force

$commands = Get-Command -Module 'Carbon' | Where-Object { $_.CommandType -ne 'Alias' }
$commandNames = $commands | ForEach-Object { '{0}-{1}' -f $_.Verb,($_.Noun -replace '^C','') }
$regex = '\b({0})\b' -f ($commandNames -join '|')

$getChildItemParams = @{
                            Path = $Path;
                            Filter = $Filter;
                            Include = $Include;
                            Exclude = $Exclude;
                            Recurse = $Recurse;
                        }

foreach( $filePath in (Get-ChildItem @getChildItemParams -File) )
{
    $content = [IO.File]::ReadAllText($filePath.FullName)
    $changed = $false
    while( $content -match $regex )
    {
        $oldCommandName = $Matches[1]
        $newCommandName = $oldCommandName -replace '-','-C'
        
        [pscustomobject]@{
                            Path = $filePath;
                            OldName = $oldCommandName;
                            NewName = $newCommandName
                        }
        
        $content = $content -replace ('\b({0})\b' -f $oldCommandName),$newCommandName
        $changed = $true
    }

    if( $changed -and $PSCmdlet.ShouldProcess($filePath.FullName,'update') )
    {
        [IO.File]::WriteAllText($filePath.FullName,$content)
    }
}
