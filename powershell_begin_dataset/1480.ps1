
function Convert-RelatedLinkToHtml
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        
        $CommandHelp,

        [string]
        
        $ModuleName,

        [string[]]
        
        $Script
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

    }

    process
    {
        if( -not $ModuleName -and ($CommandHelp | Get-Member -Name 'ModuleName') -and $CommandHelp.ModuleName )
        {
            $ModuleName = $CommandHelp.ModuleName
        }

        $aboutTopics = @()
        if( $ModuleName )
        {
            $moduleBase = Get-Module -Name $ModuleName |  Select-Object -ExpandProperty 'ModuleBase'
            if( (Test-Path -Path (Join-Path -Path $moduleBase -ChildPath 'en-US') -PathType Container) )
            {
                $aboutTopics = $moduleBase | 
                                    Get-ChildItem -Filter 'en-US\about_*' | 
                                    Select-Object -ExpandProperty 'BaseName' | 
                                    ForEach-Object { $_ -replace '\.help$','' }
            }
            else
            {
                $aboutTopics = @()
            }
        }

        Invoke-Command -ScriptBlock {
                if( $CommandHelp | Get-Member -Name 'RelatedLinks' )
                {
                     return $CommandHelp.RelatedLinks |
                                Out-String -Width ([Int32]::MaxValue) |
                                ForEach-Object { $_ -split "`n" } |
                                ForEach-Object { $_.Trim() } |
                                Where-Object { $_ }
                }

                if( $CommandHelp -is [string] )
                {
                    return $CommandHelp
                }
            } |
            ForEach-Object {
                if( $_ -match '^https?\:\/\/' )
                {
                    return '<a href="{0}">{0}</a>' -f $_
                }

                if( $ModuleName -and (Get-Command -Name $_ -Module $ModuleName -ErrorAction Ignore) )
                {
                    $cmdName = $_
                    $alias = Get-Alias -Name $_ -ErrorAction Ignore | Where-Object { $_.ModuleName -eq $ModuleName }
                    if( $alias )
                    {
                        $cmdName = $alias.ReferencedCommand
                    }
                    return '<a href="{0}.html">{1}</a>' -f $cmdName,$_
                }

                $cmd = Get-Command -Name $_ -ErrorAction Ignore
                if( $cmd -and $cmd.HelpUri )
                {
                    return '<a href="{0}.html">{1}</a>' -f $cmd.HelpUri,$_
                }

                if( $aboutTopics -contains $_ -or $Script -contains $_ )
                {
                    return '<a href="{0}.html">{0}</a>' -f $_
                }

                return $_
            }
    }

    end
    {
    }
}