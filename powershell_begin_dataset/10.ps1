


$Global:GitTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
    KnownAliases = @{
        '!f() { exec vsts code pr "$@"; }; f' = 'vsts.pr'
    }
}

$subcommands = @{
    bisect = "start bad good skip reset visualize replay log run"
    notes = 'add append copy edit get-ref list merge prune remove show'
    'vsts.pr' = 'create update show list complete abandon reactivate reviewers work-items set-vote policies'
    reflog = "show delete expire"
    remote = "
        add rename remove set-head set-branches
        get-url set-url show prune update
        "
    rerere = "clear forget diff remaining status gc"
    stash = 'push save list show apply clear drop pop create branch'
    submodule = "add status init deinit update summary foreach sync"
    svn = "
        init fetch clone rebase dcommit log find-rev
        set-tree commit-diff info create-ignore propget
        proplist show-ignore show-externals branch tag blame
        migrate mkdirs reset gc
        "
    tfs = "
        list-remote-branches clone quick-clone bootstrap init
        clone fetch pull quick-clone unshelve shelve-list labels
        rcheckin checkin checkintool shelve shelve-delete
        branch
        info cleanup cleanup-workspaces help verify autotag subtree reset-remote checkout
        "
    flow = "init feature release hotfix support help version"
    worktree = "add list lock move prune remove unlock"
}

$gitflowsubcommands = @{
    init = 'help'
    feature = 'list start finish publish track diff rebase checkout pull help delete'
    bugfix = 'list start finish publish track diff rebase checkout pull help delete'
    release = 'list start finish track publish help delete'
    hotfix = 'list start finish track publish help delete'
    support = 'list start help'
    config = 'list set base'
}

function script:gitCmdOperations($commands, $command, $filter) {
    $commands[$command].Trim() -split '\s+' | Where-Object { $_ -like "$filter*" }
}

$script:someCommands = @('add','am','annotate','archive','bisect','blame','branch','bundle','checkout','cherry',
                         'cherry-pick','citool','clean','clone','commit','config','describe','diff','difftool','fetch',
                         'format-patch','gc','grep','gui','help','init','instaweb','log','merge','mergetool','mv',
                         'notes','prune','pull','push','rebase','reflog','remote','rerere','reset','restore','revert','rm',
                         'shortlog','show','stash','status','submodule','svn','switch','tag','whatchanged', 'worktree')

if ((($PSVersionTable.PSVersion.Major -eq 5) -or $IsWindows) -and ($script:GitVersion -ge [System.Version]'2.16.2')) {
    $script:someCommands += 'update-git-for-windows'
}

$script:gitCommandsWithLongParams = $longGitParams.Keys -join '|'
$script:gitCommandsWithShortParams = $shortGitParams.Keys -join '|'
$script:gitCommandsWithParamValues = $gitParamValues.Keys -join '|'
$script:vstsCommandsWithShortParams = $shortVstsParams.Keys -join '|'
$script:vstsCommandsWithLongParams = $longVstsParams.Keys -join '|'

try {
    if ($null -ne (git help -a 2>&1 | Select-String flow)) {
        $script:someCommands += 'flow'
    }
}
catch {
    Write-Debug "Search for 'flow' in 'git help' output failed with error: $_"
}

filter quoteStringWithSpecialChars {
    if ($_ -and ($_ -match '\s+|
        $str = $_ -replace "'", "''"
        "'$str'"
    }
    else {
        $_
    }
}

function script:gitCommands($filter, $includeAliases) {
    $cmdList = @()
    if (-not $global:GitTabSettings.AllCommands) {
        $cmdList += $someCommands -like "$filter*"
    }
    else {
        $cmdList += git help --all |
            Where-Object { $_ -match '^  \S.*' } |
            ForEach-Object { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            Where-Object { $_ -like "$filter*" }
    }

    if ($includeAliases) {
        $cmdList += gitAliases $filter
    }

    $cmdList | Sort-Object
}

function script:gitRemotes($filter) {
    git remote |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitBranches($filter, $includeHEAD = $false, $prefix = '') {
    if ($filter -match "^(?<from>\S*\.{2,3})(?<to>.*)") {
        $prefix += $matches['from']
        $filter = $matches['to']
    }

    $branches = @(git branch --no-color | ForEach-Object { if (($_ -notmatch "^\* \(HEAD detached .+\)$") -and ($_ -match "^\*?\s*(?<ref>.*)")) { $matches['ref'] } }) +
                @(git branch --no-color -r | ForEach-Object { if ($_ -match "^  (?<ref>\S+)(?: -> .+)?") { $matches['ref'] } }) +
                @(if ($includeHEAD) { 'HEAD','FETCH_HEAD','ORIG_HEAD','MERGE_HEAD' })

    $branches |
        Where-Object { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        ForEach-Object { $prefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitRemoteUniqueBranches($filter) {
    git branch --no-color -r |
        ForEach-Object { if ($_ -match "^  (?<remote>[^/]+)/(?<branch>\S+)(?! -> .+)?$") { $matches['branch'] } } |
        Group-Object -NoElement |
        Where-Object { $_.Count -eq 1 } |
        Select-Object -ExpandProperty Name |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitTags($filter, $prefix = '') {
    git tag |
        Where-Object { $_ -like "$filter*" } |
        ForEach-Object { $prefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitFeatures($filter, $command) {
    $featurePrefix = git config --local --get "gitflow.prefix.$command"
    $branches = @(git branch --no-color | ForEach-Object { if ($_ -match "^\*?\s*$featurePrefix(?<ref>.*)") { $matches['ref'] } })
    $branches |
        Where-Object { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        ForEach-Object { $prefix + $_ } |
        quoteStringWithSpecialChars
}

function script:gitRemoteBranches($remote, $ref, $filter, $prefix = '') {
    git branch --no-color -r |
        Where-Object { $_ -like "  $remote/$filter*" } |
        ForEach-Object { $prefix + $ref + ($_ -replace "  $remote/","") } |
        quoteStringWithSpecialChars
}

function script:gitStashes($filter) {
    (git stash list) -replace ':.*','' |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitTfsShelvesets($filter) {
    (git tfs shelve-list) |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitFiles($filter, $files) {
    $files | Sort-Object |
        Where-Object { $_ -like "$filter*" } |
        quoteStringWithSpecialChars
}

function script:gitIndex($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Index
}

function script:gitAddFiles($GitStatus, $filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Added))
}

function script:gitCheckoutFiles($GitStatus, $filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Deleted))
}

function script:gitDeleted($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Working.Deleted
}

function script:gitDiffFiles($GitStatus, $filter, $staged) {
    if ($staged) {
        gitFiles $filter $GitStatus.Index.Modified
    }
    else {
        gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Index.Modified))
    }
}

function script:gitMergeFiles($GitStatus, $filter) {
    gitFiles $filter $GitStatus.Working.Unmerged
}

function script:gitRestoreFiles($GitStatus, $filter, $staged) {
    if ($staged) {
        gitFiles $filter (@($GitStatus.Index.Added) + @($GitStatus.Index.Modified) + @($GitStatus.Index.Deleted))
    }
    else {
        gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Deleted))
    }
}

function script:gitAliases($filter) {
    git config --get-regexp ^alias\. | ForEach-Object{
        if ($_ -match "^alias\.(?<alias>\S+) .*") {
            $alias = $Matches['alias']
            if ($alias -like "$filter*") {
                $alias
            }
        }
    } | Sort-Object -Unique
}

function script:expandGitAlias($cmd, $rest) {
    $alias = git config "alias.$cmd"

    if ($alias) {
        $known = $Global:GitTabSettings.KnownAliases[$alias]
        if ($known) {
            return "git $known$rest"
        }

        return "git $alias$rest"
    }
    else {
        return "git $cmd$rest"
    }
}

function script:expandLongParams($hash, $cmd, $filter) {
    $hash[$cmd].Trim() -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("--", $_) }
}

function script:expandShortParams($hash, $cmd, $filter) {
    $hash[$cmd].Trim() -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("-", $_) }
}

function script:expandParamValues($cmd, $param, $filter) {
    $paramValues = $gitParamValues[$cmd][$param]

    $completions = if ($paramValues -is [scriptblock]) {
        & $paramValues $filter | Where-Object { $_ -like "$filter*" }
    }
    else {
        $paramValues.Trim() -split ' ' | Where-Object { $_ -like "$filter*" } | Sort-Object
    }

    $completions | ForEach-Object { -join ("--", $param, "=", $_) }
}

function Expand-GitCommand($Command) {
    $res = Invoke-Utf8ConsoleCommand { GitTabExpansionInternal $Command $Global:GitStatus }
    $res
}

function GitTabExpansionInternal($lastBlock, $GitStatus = $null) {
    $ignoreGitParams = '(?<params>\s+-(?:[aA-zZ0-9]+|-[aA-zZ0-9][aA-zZ0-9-]*)(?:=\S+)?)*'

    if ($lastBlock -match "^$(Get-AliasPattern git) (?<cmd>\S+)(?<args> .*)$") {
        $lastBlock = expandGitAlias $Matches['cmd'] $Matches['args']
    }

    
    if ($lastBlock -match "^$(Get-AliasPattern tgit) (?<cmd>\S*)$") {
        
        return $Global:TortoiseGitSettings.TortoiseGitCommands.Keys.GetEnumerator() | Sort-Object | Where-Object { $_ -like "$($matches['cmd'])*" }
    }

    
    if ($lastBlock -match "^$(Get-AliasPattern gitk).* (?<ref>\S*)$") {
        return gitBranches $matches['ref'] $true
    }

    switch -regex ($lastBlock -replace "^$(Get-AliasPattern git) ","") {

        
        "^(?<cmd>$($subcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $subcommands $matches['cmd'] $matches['op']
        }

        
        "^flow (?<cmd>$($gitflowsubcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $gitflowsubcommands $matches['cmd'] $matches['op']
        }

        
        "^flow (?<command>\S*)\s+(?<op>\S*)\s+(?<name>\S*)$" {
            gitFeatures $matches['name'] $matches['command']
        }

        
        "^remote.* (?:rename|rm|set-head|set-branches|set-url|show|prune).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        
        "^stash (?:show|apply|drop|pop|branch).* (?<stash>\S*)$" {
            gitStashes $matches['stash']
        }

        
        "^bisect (?:bad|good|reset|skip).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        
        "^tfs +unshelve.* (?<shelveset>\S*)$" {
            gitTfsShelvesets $matches['shelveset']
        }

        
        
        "^branch.* (?<branch>\S*)$" {
            gitBranches $matches['branch']
        }

        
        "^(?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $TRUE
        }

        
        "^help (?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $FALSE
        }

        
        
        "^push${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<force>\+?)(?<ref>[^\s\:]*\:)(?<branch>\S*)$" {
            gitRemoteBranches $matches['remote'] $matches['ref'] $matches['branch'] -prefix $matches['force']
        }

        
        
        
        "^(?:push|pull)${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<force>\+?)(?<ref>[^\s\:]*)$" {
            gitBranches $matches['ref'] -prefix $matches['force']
            gitTags $matches['ref'] -prefix $matches['force']
        }

        
        
        
        "^(?:push|pull|fetch)${ignoreGitParams}\s+(?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        
        
        "^reset.* HEAD(?:\s+--)? (?<path>\S*)$" {
            gitIndex $GitStatus $matches['path']
        }

        
        "^commit.*-C\s+(?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        
        "^add.* (?<files>\S*)$" {
            gitAddFiles $GitStatus $matches['files']
        }

        
        "^checkout.* -- (?<files>\S*)$" {
            gitCheckoutFiles $GitStatus $matches['files']
        }

        
        "^restore.* (?-i)-s\s*(?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
            gitTags $matches['ref']
            break
        }

        
        "^restore(?:.* (?<staged>(?:(?-i)-S|--staged))|.*) (?<files>\S*)$" {
            gitRestoreFiles $GitStatus $matches['files'] $matches['staged']
        }

        
        "^rm.* (?<index>\S*)$" {
            gitDeleted $GitStatus $matches['index']
        }

        
        "^(?:diff|difftool)(?:.* (?<staged>(?:--cached|--staged))|.*) (?<files>\S*)$" {
            gitDiffFiles $GitStatus $matches['files'] $matches['staged']
        }

        
        "^(?:merge|mergetool).* (?<files>\S*)$" {
            gitMergeFiles $GitStatus $matches['files']
        }

        
        "^(?:checkout|switch).* (?<ref>\S*)$" {
            & {
                gitBranches $matches['ref'] $true
                gitRemoteUniqueBranches $matches['ref']
                gitTags $matches['ref']
                
            } | Select-Object -Unique
        }

        
        "^worktree add.* (?<files>\S+) (?<ref>\S*)$" {
            gitBranches $matches['ref']
        }

        
        "^(?:cherry|cherry-pick|diff|difftool|log|merge|rebase|reflog\s+show|reset|revert|show).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
            gitTags $matches['ref']
        }

        
        "^(?<cmd>$gitCommandsWithParamValues).* --(?<param>[^=]+)=(?<value>\S*)$" {
            expandParamValues $matches['cmd'] $matches['param'] $matches['value']
        }

        
        "^(?<cmd>$gitCommandsWithLongParams).* --(?<param>\S*)$" {
            expandLongParams $longGitParams $matches['cmd'] $matches['param']
        }

        
        "^(?<cmd>$gitCommandsWithShortParams).* -(?<shortparam>\S*)$" {
            expandShortParams $shortGitParams $matches['cmd'] $matches['shortparam']
        }

        
        "vsts\.pr\s+(?<op>\S*)$" {
            gitCmdOperations $subcommands 'vsts.pr' $matches['op']
        }

        
        "vsts\.pr\s+(?<cmd>$vstsCommandsWithLongParams).*--(?<param>\S*)$"
        {
            expandLongParams $longVstsParams $matches['cmd'] $matches['param']
        }

        
        "vsts\.pr\s+(?<cmd>$vstsCommandsWithShortParams).*-(?<shortparam>\S*)$"
        {
            expandShortParams $shortVstsParams $matches['cmd'] $matches['shortparam']
        }
    }
}

if ($PSVersionTable.PSVersion.Major -ge 6) {
    Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName git,tgit,gitk -Native -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        Expand-GitCommand $commandAst.Extent.Text
    }
}
else {
    $PowerTab_RegisterTabExpansion = if (Get-Module -Name powertab) { Get-Command Register-TabExpansion -Module powertab -ErrorAction SilentlyContinue }
    if ($PowerTab_RegisterTabExpansion) {
        & $PowerTab_RegisterTabExpansion "git.exe" -Type Command {
            param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)  

            $line = $Context.Line
            $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
            $TabExpansionHasOutput.Value = $true
            Expand-GitCommand $lastBlock
        }
        return
    }

    if (Test-Path Function:\TabExpansion) {
        Rename-Item Function:\TabExpansion TabExpansionBackup
    }

    function TabExpansion($line, $lastWord) {
        $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

        switch -regex ($lastBlock) {
            
            "^$(Get-AliasPattern git) (.*)" { Expand-GitCommand $lastBlock }
            "^$(Get-AliasPattern tgit) (.*)" { Expand-GitCommand $lastBlock }
            "^$(Get-AliasPattern gitk) (.*)" { Expand-GitCommand $lastBlock }

            
            default {
                if (Test-Path Function:\TabExpansionBackup) {
                    TabExpansionBackup $line $lastWord
                }
            }
        }
    }
}


Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName Remove-GitBranch -ParameterName Name -ScriptBlock {
    param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
    gitBranches $WordToComplete $true
}
