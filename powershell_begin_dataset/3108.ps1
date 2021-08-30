









function Get-ConsoleColor
{
    [CmdletBinding()]
    param(
        
    )

    Begin{

    }

    Process{
        $Colors = [Enum]::GetValues([ConsoleColor])

        foreach($Color in $Colors)
        {
            [pscustomobject] @{
                ConsoleColor = $Color
            }
        }
    }

    End{

    }
}