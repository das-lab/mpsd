
































param(
        [Parameter(Mandatory)]
        [string]$LastReleaseTag,

        [Parameter(Mandatory)]
        [string]$Token,

        [Parameter(Mandatory)]
        [string]$NewReleaseTag,

        [Parameter()]
        [switch]$HasCherryPick
    )



$Script:powershell_team = @(
    "Robert Holt"
    "Tyler Leonhardt"
)

$Script:powershell_team_emails = @(
    "tylerl0706@gmail.com"
    "rjmholt_msft@outlook.com"
)


$Script:community_login_map = @{}

class CommitNode {
    [string] $Hash
    [string[]] $Parents
    [string] $AuthorName
    [string] $AuthorGitHubLogin
    [string] $AuthorEmail
    [string] $Subject
    [string] $Body
    [string] $PullRequest
    [string] $ChangeLogMessage
    [bool] $IsBreakingChange

    CommitNode($hash, $parents, $name, $email, $subject, $body) {
        $this.Hash = $hash
        $this.Parents = $parents
        $this.AuthorName = $name
        $this.AuthorEmail = $email
        $this.Subject = $subject
        $this.Body = $body
        $this.IsBreakingChange = $body -match "\[breaking change\]"

        if ($subject -match "\(
            $this.PullRequest = $Matches[1]
        }
    }
}

















function Get-ChildMergeCommit
{
    [CmdletBinding(DefaultParameterSetName="TagName")]
    param(
        [Parameter(Mandatory, ParameterSetName="TagName")]
        [string]$LastReleaseTag,

        [Parameter(Mandatory, ParameterSetName="CommitHash")]
        [string]$CommitHash
    )

    $tag_hash = $CommitHash
    if ($PSCmdlet.ParameterSetName -eq "TagName") { $tag_hash = git rev-parse "$LastReleaseTag^0" }

    
    $merge_commits_not_in_release_branch = git --no-pager log "$tag_hash..HEAD" --format='%H||%P'
    
    $child_merge_commit = $merge_commits_not_in_release_branch | Select-String -SimpleMatch $tag_hash
    return $child_merge_commit.Line
}
















function New-CommitNode
{
    param(
        [Parameter(ValueFromPipeline)]
        [ValidatePattern("^.+\|.+\|.+\|.+\|.+$")]
        [string]$CommitMetadata
    )

    Process {
        $hash, $parents, $name, $email, $subject = $CommitMetadata.Split("||")
        $body = (git --no-pager show $hash -s --format=%b) -join "`n"
        return [CommitNode]::new($hash, $parents, $name, $email, $subject, $body)
    }
}

function Get-PRNumberFromCommitSubject
{
    param(
        [string]$CommitSubject
    )

    if (-not $CommitSubject)
    {
        return $null
    }

    if (-not ($CommitSubject -match '(.*)\(
    {
        return $null
    }

    return @{
        Message = $Matches[1]
        PR = $Matches[2]
    }
}

function New-ChangeLogEntry
{
    param(
        [ValidateNotNullOrEmpty()][string]$RepositoryName,
        [ValidateNotNullOrEmpty()][string]$CommitMessage,
        [int]$PRNumber,
        [string]$UserToThank,
        [switch]$IsBreakingChange
    )

    $repoUrl = "https://github.com/PowerShell/$RepositoryName"

    $entry = if ($PRNumber)
    {
        "- [$RepositoryName 
    }
    else
    {
        "- [$RepositoryName]($repoUrl) -"
    }

    $entry += "`n  "

    if ($IsBreakingChange)
    {
        $entry += "[Breaking Change] "
    }

    $entry += $CommitMessage

    if ($UserToThank)
    {
        $entry += " (Thanks @$UserToThank!)"
    }

    return $entry
}




















function Get-ChangeLog
{
    param(
        [Parameter(Mandatory)]
        [string]$LastReleaseTag,

        [Parameter(Mandatory)]
        [string]$Token,

        [Parameter(Mandatory)]
        [string]$RepoUri,

        [Parameter(Mandatory)]
        [string]$RepoName,

        [Parameter()]
        [switch]$HasCherryPick
    )

    $tag_hash = git rev-parse "$LastReleaseTag^0"
    $format = '%H||%P||%aN||%aE||%s'
    $header = @{"Authorization"="token $Token"}

    
    $child_merge_commit = Get-ChildMergeCommit -CommitHash $tag_hash
    $commit_hash, $parent_hashes = $child_merge_commit.Split("||")
    
    $other_parent_hash = ($parent_hashes.Trim() -replace $tag_hash).Trim()

    if ($HasCherryPick) {
        
        
        
        
        
        
        
        

        
        $new_commits_from_other_parent = git --no-pager log --first-parent --cherry-pick --right-only "$tag_hash...$other_parent_hash" --format=$format | New-CommitNode
        
        $new_commits_from_last_release = git --no-pager log --first-parent --cherry-pick --left-only "$tag_hash...$other_parent_hash" --format=$format | New-CommitNode
        
        $duplicate_commits = Compare-Object $new_commits_from_last_release $new_commits_from_other_parent -Property PullRequest -ExcludeDifferent -IncludeEqual -PassThru
        if ($duplicate_commits) {
            $duplicate_pr_numbers = @($duplicate_commits | ForEach-Object -MemberName PullRequest)
            $new_commits_from_other_parent = $new_commits_from_other_parent | Where-Object PullRequest -NotIn $duplicate_pr_numbers
        }

        
        $new_commits_after_merge_commit = @(git --no-pager log --first-parent "$commit_hash..HEAD" --format=$format | New-CommitNode)
        $new_commits = $new_commits_after_merge_commit + $new_commits_from_other_parent
    } else {
        
        

        
        
        

        
        
        
        $new_commits_after_last_release  = @(git --no-pager log --first-parent "$commit_hash..HEAD" --format=$format | New-CommitNode)
        
        $new_commits = $new_commits_during_last_release + $new_commits_after_last_release
    }

    $new_commits = $new_commits | Where-Object { -not $_.Subject.StartsWith('[Ignore]', [System.StringComparison]::OrdinalIgnoreCase) }

    foreach ($commit in $new_commits) {
        $messageParts = Get-PRNumberFromCommitSubject $commit.Subject
        if ($messageParts) {
            $message = $messageParts.Message
            $prNumber = $messageParts.PR
        } else {
            $message = $commit.Subject
        }

        $userToThank = $null
        if (-not ($commit.AuthorEmail.EndsWith("@microsoft.com") -or ($powershell_team -contains $commit.AuthorName) -or ($powershell_team_emails -contains $commit.AuthorEmail))) {
            if ($Script:community_login_map.ContainsKey($commit.AuthorEmail)) {
                $commit.AuthorGitHubLogin = $Script:community_login_map[$commit.AuthorEmail]
            } else {
                $uri = "$RepoUri/commits/$($commit.Hash)"
                $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $header -ErrorAction SilentlyContinue
                if($response) {
                    $content = ConvertFrom-Json -InputObject $response.Content
                    $commit.AuthorGitHubLogin = $content.author.login
                    $Script:community_login_map[$commit.AuthorEmail] = $commit.AuthorGitHubLogin
                }
            }
            $userToThank = $commit.AuthorGitHubLogin
        }

        $commit.ChangeLogMessage = New-ChangeLogEntry -RepositoryName $RepoName -CommitMessage $message -PRNumber $prNumber -UserToThank $userToThank -IsBreakingChange:$commit.IsBreakingChange
    }

    $new_commits | Sort-Object -Descending -Property IsBreakingChange | ForEach-Object -MemberName ChangeLogMessage
}
























function Get-PowerShellExtensionChangeLog {
    param(
        [Parameter(Mandatory)]
        [string]$LastReleaseTag,

        [Parameter(Mandatory)]
        [string]$Token,

        [Parameter(Mandatory)]
        [string]$NewReleaseTag,

        [Parameter()]
        [switch]$HasCherryPick
    )

    $vscodePowerShell = Get-ChangeLog -LastReleaseTag $LastReleaseTag -Token $Token -HasCherryPick:$HasCherryPick.IsPresent -RepoUri 'https://api.github.com/repos/PowerShell/vscode-powershell' -RepoName 'vscode-PowerShell'
    Push-Location (Join-Path $PSScriptRoot .. .. PowerShellEditorServices)
    $pses = Get-ChangeLog -LastReleaseTag $LastReleaseTag -Token $Token -HasCherryPick:$HasCherryPick.IsPresent -RepoUri 'https://api.github.com/repos/PowerShell/PowerShellEditorServices' -RepoName 'PowerShellEditorServices'
    Pop-Location

    return @"




$($vscodePowerShell -join "`n")



$($pses -join "`n")

"@
}

Get-PowerShellExtensionChangeLog -LastReleaseTag $LastReleaseTag -Token $Token -NewReleaseTag $NewReleaseTag -HasCherryPick:$HasCherryPick.IsPresent
