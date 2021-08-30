
$ConsoleColorToAnsi = @(
    30 
    34 
    32 
    36 
    31 
    35 
    33 
    37 
    90 
    94 
    92 
    96 
    91 
    95 
    93 
    97 
)
$AnsiDefaultColor = 39
$AnsiEscape = [char]27 + "["

[Reflection.Assembly]::LoadWithPartialName('System.Drawing') > $null
$ColorTranslatorType = 'System.Drawing.ColorTranslator' -as [Type]
$ColorType = 'System.Drawing.Color' -as [Type]

function EscapeAnsiString([string]$AnsiString) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $res = $AnsiString -replace "$([char]27)", '`e'
    }
    else {
        $res = $AnsiString -replace "$([char]27)", '$([char]27)'
    }

    $res
}

function Test-VirtualTerminalSequece([psobject[]]$Object, [switch]$Force) {
    foreach ($obj in $Object) {
        if (($Force -or $global:GitPromptSettings.AnsiConsole) -and ($obj -is [string])) {
            $obj.Contains($AnsiEscape)
        }
        else {
            $false
        }
    }
}

function Get-VirtualTerminalSequence ($color, [int]$offset = 0) {
    
    
    if ($null -eq $color) {
        return $null;
    }

    if ($color -is [byte]) {
        return "${AnsiEscape}$(38 + $offset);5;${color}m"
    }

    if ($color -is [int]) {
        $r = ($color -shr 16) -band 0xff
        $g = ($color -shr 8) -band 0xff
        $b = $color -band 0xff
        return "${AnsiEscape}$(38 + $offset);2;${r};${g};${b}m"
    }

    if ($color -is [String]) {
        try {
            if ($ColorTranslatorType) {
                $color = $ColorTranslatorType::FromHtml($color)
            }
        }
        catch {
            Write-Debug $_
        }

        
        if (($color -isnot $ColorType) -and ($null -ne ($consoleColor = $color -as [System.ConsoleColor]))) {
            $color = $consoleColor
        }
    }

    if ($ColorType -and ($color -is $ColorType)) {
        return "${AnsiEscape}$(38 + $offset);2;$($color.R);$($color.G);$($color.B)m"
    }

    if (($color -is [System.ConsoleColor]) -and ($color -ge 0) -and ($color -le 15)) {
        return "${AnsiEscape}$($ConsoleColorToAnsi[$color] + $offset)m"
    }

    return "${AnsiEscape}$($AnsiDefaultColor + $offset)m"
}

function Get-ForegroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color
}

function Get-BackgroundVirtualTerminalSequence($Color) {
    return Get-VirtualTerminalSequence $Color 10
}
