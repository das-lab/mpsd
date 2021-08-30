
function Edit-HelpText
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,VAlueFromPipeline=$true)]
        
        $InputObject,

        [string]
        
        $ModuleName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        $commands = Invoke-Command -ScriptBlock {
                                                    Get-Command -Module $ModuleName -CommandType Cmdlet
                                                    Get-Command -Module $ModuleName -CommandType Function
                                                    Get-Command -Module $ModuleName -CommandType Filter
                                                }
        $aliases = Get-Command -Module $ModuleName -CommandType Alias | Get-Alias
        $aboutTopicNames = Get-ChildItem -Path (Get-Module -Name $ModuleName).ModuleBase -Filter 'en-US\about_*' |
                                Select-Object -ExpandProperty 'BaseName' |
                                ForEach-Object { $_ -replace '\.help$','' }
    }

    process
    {
        $regex = $commands | Select-Object -ExpandProperty 'Name' | ForEach-Object { [regex]::Escape( $_ ) }
        $regex = $regex -join '|'
        $regex = '`({0})`' -f $regex
        $replacement = '[$1]($1.html)'

       $InputObject | 
            ForEach-Object { $_ -replace $regex,$replacement } |
            ForEach-Object {
                $text = $_
                foreach( $alias in $aliases )
                {
                    $text = $text -replace ('`({0})`' -f $alias.Name),('[$1]({0}.html)' -f $alias.Definition)
                }

                foreach( $aboutTopicName in $aboutTopicNames )
                {
                    $text = $text -replace ('`({0})`' -f $aboutTopicName),('[{0}]($1.html)' -f ($aboutTopicName -replace '_','\_'))
                }
                return $text
            }
    }

    end
    {
    }
}