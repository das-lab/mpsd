


$global:GitPromptSettings = [PoshGitPromptSettings]::new()
$global:GitPromptValues = [PoshGitPromptValues]::new()


$s = $global:GitPromptSettings
if ($Host.UI.RawUI.BackgroundColor -eq [ConsoleColor]::DarkMagenta) {
    $s.LocalDefaultStatusSymbol.ForegroundColor = 'Green'
    $s.LocalWorkingStatusSymbol.ForegroundColor = 'Red'
    $s.BeforeIndex.ForegroundColor              = 'Green'
    $s.IndexColor.ForegroundColor               = 'Green'
    $s.WorkingColor.ForegroundColor             = 'Red'
}


function New-GitPromptSettings {
    [PoshGitPromptSettings]::new()
}


function Write-Prompt {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        
        
        
        
        [Parameter(Mandatory, Position=0)]
        $Object,

        
        [Parameter(ParameterSetName="Default")]
        $ForegroundColor = $null,

        
        [Parameter(ParameterSetName="Default")]
        $BackgroundColor = $null,

        
        [Parameter(ParameterSetName="CellColor")]
        [ValidateNotNull()]
        [PoshGitCellColor]
        $Color,

        
        
        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder
    )

    if (!$Object -or (($Object -is [PoshGitTextSpan]) -and !$Object.Text)) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    if ($PSCmdlet.ParameterSetName -eq "CellColor") {
        $bgColor = $Color.BackgroundColor
        $fgColor = $Color.ForegroundColor
    }
    else {
        $bgColor = $BackgroundColor
        $fgColor = $ForegroundColor
    }

    $s = $global:GitPromptSettings
    if ($s) {
        if ($null -eq $fgColor) {
            $fgColor = $s.DefaultColor.ForegroundColor
        }

        if ($null -eq $bgColor) {
            $bgColor = $s.DefaultColor.BackgroundColor
        }

        if ($s.AnsiConsole) {
            if ($Object -is [PoshGitTextSpan]) {
                $str = $Object.ToAnsiString()
            }
            else {
                
                $reset = [System.Collections.Generic.List[string]]::new()
                $e = [char]27 + "["

                $fg = $fgColor
                if (($null -ne $fg) -and !(Test-VirtualTerminalSequece $fg)) {
                    $fg = Get-ForegroundVirtualTerminalSequence $fg
                    $reset.Add('39')
                }

                $bg = $bgColor
                if (($null -ne $bg) -and !(Test-VirtualTerminalSequece $bg)) {
                    $bg = Get-BackgroundVirtualTerminalSequence $bg
                    $reset.Add('49')
                }

                $str = "${Object}"
                if (Test-VirtualTerminalSequece $str -Force) {
                    $reset.Clear()
                    $reset.Add('0')
                }

                $str = "${fg}${bg}" + $str
                if ($reset.Count -gt 0) {
                    $str += "${e}$($reset -join ';')m"
                }
            }

            return $(if ($StringBuilder) { $StringBuilder.Append($str) } else { $str })
        }
    }

    if ($Object -is [PoshGitTextSpan]) {
        $bgColor = $Object.BackgroundColor
        $fgColor = $Object.ForegroundColor
        $Object = $Object.Text
    }

    $writeHostParams = @{
        Object = $Object;
        NoNewLine = $true;
    }

    if ($bgColor -and ($bgColor -ge 0) -and ($bgColor -le 15)) {
        $writeHostParams.BackgroundColor = $bgColor
    }

    if ($fgColor -and ($fgColor -ge 0) -and ($fgColor -le 15)) {
        $writeHostParams.ForegroundColor = $fgColor
    }

    Write-Host @writeHostParams
    return $(if ($StringBuilder) { $StringBuilder } else { "" })
}


function Write-GitStatus {
    param(
        
        
        [Parameter(Position = 0)]
        $Status
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return
    }

    $sb = [System.Text.StringBuilder]::new(150)

    
    if (!$s.DefaultPromptWriteStatusFirst) {
        $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
    }

    $sb | Write-Prompt $s.BeforeStatus > $null
    $sb | Write-GitBranchName $Status -NoLeadingSpace > $null
    $sb | Write-GitBranchStatus $Status > $null

    if ($s.EnableFileStatus -and $Status.HasIndex) {
        $sb | Write-Prompt $s.BeforeIndex > $null
        $sb | Write-GitIndexStatus $Status > $null

        if ($Status.HasWorking) {
            $sb | Write-Prompt $s.DelimStatus > $null
        }
    }

    if ($s.EnableFileStatus -and $Status.HasWorking) {
        $sb | Write-GitWorkingDirStatus $Status > $null
    }

    $sb | Write-GitWorkingDirStatusSummary $Status > $null

    if ($s.EnableStashStatus -and ($Status.StashCount -gt 0)) {
        $sb | Write-GitStashCount $Status > $null
    }

    $sb | Write-Prompt $s.AfterStatus > $null

    
    if ($s.DefaultPromptWriteStatusFirst) {
        $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
    }

    if ($sb.Length -gt 0) {
        $sb.ToString()
    }
}


function Format-GitBranchName {
    param(
        
        
        [Parameter(Position=0)]
        [string]
        $BranchName
    )

    $s = $global:GitPromptSettings
    if (!$s -or !$BranchName) {
        return "$BranchName"
    }

    $res = $BranchName
    if (($s.BranchNameLimit -gt 0) -and ($BranchName.Length -gt $s.BranchNameLimit))
    {
        $res = "{0}{1}" -f $BranchName.Substring(0, $s.BranchNameLimit), $s.TruncatedBranchSuffix
    }

    $res
}


function Get-GitBranchStatusColor {
    param(
        
        
        [Parameter(Position = 0)]
        $Status
    )

    $s = $global:GitPromptSettings
    if (!$s) {
        return [PoshGitTextSpan]::new()
    }

    $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchColor)

    if (($Status.BehindBy -ge 1) -and ($Status.AheadBy -ge 1)) {
        
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchBehindAndAheadStatusSymbol)
    }
    elseif ($Status.BehindBy -ge 1) {
        
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchBehindStatusSymbol)
    }
    elseif ($Status.AheadBy -ge 1) {
        
        $branchStatusTextSpan = [PoshGitTextSpan]::new($s.BranchAheadStatusSymbol)
    }

    $branchStatusTextSpan.Text = ''
    $branchStatusTextSpan
}


function Write-GitBranchName {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    
    $branchNameTextSpan = Get-GitBranchStatusColor $Status
    $branchNameTextSpan.Text = Format-GitBranchName $Status.Branch
    if (!$NoLeadingSpace) {
        $branchNameTextSpan.Text = " " + $branchNameTextSpan.Text
    }

    if ($StringBuilder) {
        $StringBuilder | Write-Prompt $branchNameTextSpan > $null
    }
    else {
        $str = Write-Prompt $branchNameTextSpan
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}


function Write-GitBranchStatus {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $branchStatusTextSpan = Get-GitBranchStatusColor $Status

    if (!$Status.Upstream) {
        $branchStatusTextSpan.Text = $s.BranchUntrackedText
    }
    elseif ($Status.UpstreamGone -eq $true) {
        
        $branchStatusTextSpan.Text = $s.BranchGoneStatusSymbol.Text
    }
    elseif (($Status.BehindBy -eq 0) -and ($Status.AheadBy -eq 0)) {
        
        $branchStatusTextSpan.Text = $s.BranchIdenticalStatusSymbol.Text
    }
    elseif (($Status.BehindBy -ge 1) -and ($Status.AheadBy -ge 1)) {
        
        if ($s.BranchBehindAndAheadDisplay -eq "Full") {
            $branchStatusTextSpan.Text = ("{0}{1} {2}{3}" -f $s.BranchBehindStatusSymbol.Text, $Status.BehindBy, $s.BranchAheadStatusSymbol.Text, $status.AheadBy)
        }
        elseif ($s.BranchBehindAndAheadDisplay -eq "Compact") {
            $branchStatusTextSpan.Text = ("{0}{1}{2}" -f $Status.BehindBy, $s.BranchBehindAndAheadStatusSymbol.Text, $Status.AheadBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchBehindAndAheadStatusSymbol.Text
        }
    }
    elseif ($Status.BehindBy -ge 1) {
        
        if (($s.BranchBehindAndAheadDisplay -eq "Full") -Or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
            $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchBehindStatusSymbol.Text, $Status.BehindBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchBehindStatusSymbol.Text
        }
    }
    elseif ($Status.AheadBy -ge 1) {
        
        if (($s.BranchBehindAndAheadDisplay -eq "Full") -or ($s.BranchBehindAndAheadDisplay -eq "Compact")) {
            $branchStatusTextSpan.Text = ("{0}{1}" -f $s.BranchAheadStatusSymbol.Text, $Status.AheadBy)
        }
        else {
            $branchStatusTextSpan.Text = $s.BranchAheadStatusSymbol.Text
        }
    }
    else {
        
        $branchStatusTextSpan.Text = "?"
    }

    $str = ""
    if ($branchStatusTextSpan.Text) {
        $textSpan = [PoshGitTextSpan]::new($branchStatusTextSpan)
        if (!$NoLeadingSpace) {
            $textSpan.Text = " " + $branchStatusTextSpan.Text
        }

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $textSpan > $null
        }
        else {
            $str = Write-Prompt $textSpan
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}


function Write-GitIndexStatus {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.HasIndex) {
        if ($s.ShowStatusWhenZero -or $Status.Index.Added) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileAddedText)$($Status.Index.Added.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($s.ShowStatusWhenZero -or $status.Index.Modified) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileModifiedText)$($status.Index.Modified.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Index.Deleted) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileRemovedText)$($Status.Index.Deleted.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }

        if ($Status.Index.Unmerged) {
            $indexStatusText = " "
            if ($NoLeadingSpace) {
                $indexStatusText = ""
                $NoLeadingSpace = $false
            }

            $indexStatusText += "$($s.FileConflictedText)$($Status.Index.Unmerged.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $indexStatusText -Color $s.IndexColor > $null
            }
            else {
                $str += Write-Prompt $indexStatusText -Color $s.IndexColor
            }
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}


function Write-GitWorkingDirStatus {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.HasWorking) {
        if ($s.ShowStatusWhenZero -or $Status.Working.Added) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileAddedText)$($Status.Working.Added.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Working.Modified) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileModifiedText)$($Status.Working.Modified.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($s.ShowStatusWhenZero -or $Status.Working.Deleted) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileRemovedText)$($Status.Working.Deleted.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }

        if ($Status.Working.Unmerged) {
            $workingStatusText = " "
            if ($NoLeadingSpace) {
                $workingStatusText = ""
                $NoLeadingSpace = $false
            }

            $workingStatusText += "$($s.FileConflictedText)$($Status.Working.Unmerged.Count)"

            if ($StringBuilder) {
                $StringBuilder | Write-Prompt $workingStatusText -Color $s.WorkingColor > $null
            }
            else {
                $str += Write-Prompt $workingStatusText -Color $s.WorkingColor
            }
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}


function Write-GitWorkingDirStatusSummary {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        
        [Parameter()]
        [switch]
        $NoLeadingSpace
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    
    $localStatusSymbol = $s.LocalDefaultStatusSymbol

    if ($Status.HasWorking) {
        
        $localStatusSymbol = $s.LocalWorkingStatusSymbol
    }
    elseif ($Status.HasIndex) {
        
        $localStatusSymbol = $s.LocalStagedStatusSymbol
    }

    if ($localStatusSymbol.Text) {
        $textSpan = [PoshGitTextSpan]::new($localStatusSymbol)
        if (!$NoLeadingSpace) {
            $textSpan.Text = " " + $localStatusSymbol.Text
        }

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $textSpan > $null
        }
        else {
            $str += Write-Prompt $textSpan
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}


function Write-GitStashCount {
    param(
        
        
        [Parameter(Position = 0)]
        $Status,

        
        [Parameter(ValueFromPipeline = $true)]
        [System.Text.StringBuilder]
        $StringBuilder
    )

    $s = $global:GitPromptSettings
    if (!$Status -or !$s) {
        return $(if ($StringBuilder) { $StringBuilder } else { "" })
    }

    $str = ""

    if ($Status.StashCount -gt 0) {
        $stashText = "$($Status.StashCount)"

        if ($StringBuilder) {
            $StringBuilder | Write-Prompt $s.BeforeStash > $null
            $StringBuilder | Write-Prompt $stashText -Color $s.StashColor > $null
            $StringBuilder | Write-Prompt $s.AfterStash > $null
        }
        else {
            $str += Write-Prompt $s.BeforeStash
            $str += Write-Prompt $stashText -Color $s.StashColor
            $str += Write-Prompt $s.AfterStash
        }
    }

    return $(if ($StringBuilder) { $StringBuilder } else { $str })
}

if (!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $global:VcsPromptStatuses = @()
}


function Global:Write-VcsStatus {
    Set-ConsoleMode -ANSI

    $OFS = ""
    $sb = [System.Text.StringBuilder]::new(256)

    foreach ($promptStatus in $global:VcsPromptStatuses) {
        [void]$sb.Append("$(& $promptStatus)")
    }

    if ($sb.Length -gt 0) {
        $sb.ToString()
    }
}


$PoshGitVcsPrompt = {
    try {
        $global:GitStatus = Get-GitStatus
        Write-GitStatus $GitStatus
    }
    catch {
        $s = $global:GitPromptSettings
        if ($s) {
            $errorText = "PoshGitVcsPrompt error: $_"
            $sb = [System.Text.StringBuilder]::new()

            
            if (!$s.DefaultPromptWriteStatusFirst) {
                $sb | Write-Prompt $s.PathStatusSeparator.Expand() > $null
            }
            $sb | Write-Prompt $s.BeforeStatus > $null

            $sb | Write-Prompt $errorText -Color $s.ErrorColor > $null
            if ($s.Debug) {
                if (!$s.AnsiConsole) { Write-Host }
                Write-Verbose "PoshGitVcsPrompt error details: $($_ | Format-List * -Force | Out-String)" -Verbose
            }
            $sb | Write-Prompt $s.AfterStatus > $null

            if ($sb.Length -gt 0) {
                $sb.ToString()
            }
        }
    }
}

$global:VcsPromptStatuses += $PoshGitVcsPrompt
