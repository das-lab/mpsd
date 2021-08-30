













[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    
    $GitHubAuthToken,

    [Parameter(Mandatory=$true)]
    [string]
    
    $GitHubUsername,

    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketExportJsonPath,

    [int]
    $Count = 1
)


Set-StrictMode -Version 'Latest'

$credential = '{0}:{1}' -f $GitHubUsername,$GitHubAuthToken

$authHeaderValue = 'Basic {0}' -f [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes($credential) )
$headers = @{ 
                'Authorization' = $authHeaderValue;
                'Accept' = 'application/vnd.github.v3+json';
            }

$issuesUri = 'https://api.github.com/repos/pshdo/Carbon/issues'
$githubIssues = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $issuesUri -Headers $headers

$issueData = Get-Content -Path $BitbucketExportJsonPath -Raw | ConvertFrom-Json 

$issueData.issues |
    Where-Object { $_.status -eq 'open' -or $_.status -eq 'new' } |
    Select-Object -First $Count |
    ForEach-Object {
        $bbIssue = $_
        
        $issueTag = 'bb-issue-{0}' -f $bbIssue.id
        $githubIssue = $githubIssues | Where-Object { ($_.body -match '\b{0}\b' -f [regex]::Escape($issueTag)) }
        if( -not $githubIssue )
        {
            $bbIssueUri = 'https://bitbucket.org/splatteredbits/carbon/issues/{0}' -f $bbIssue.id
            $author = ''
            $authorMention = ''
            $createdOn = [datetime]$bbIssue.created_on
            $issueImportTitle = 'Imported from [Bitbucket issue 
            if( $bbIssue.reporter -ne $GitHubUsername )
            {
                $author = ' by [{0}](https://bitbucket.org/{0})' -f $bbIssue.reporter
                $authorMention = " / @$($bbIssue.reporter)"
            }
            $body = @"

-----
$($bbIssue.content)


"@
            $githubIssueJson = [pscustomobject]@{
                                                    title = $_.title;
                                                    body = $body;
                                                    labels = @( $_.priority, $_.kind, 'from-bitbucket' );
                                                } | ConvertTo-Json -Depth 100
            $githubIssue = Invoke-RestMethod -Method Post -Uri $issuesUri -Headers $headers -Body $githubIssueJson -UseBasicParsing
        }

        $githubComments = Invoke-RestMethod -Method Get -Uri $githubIssue.comments_url -Headers $headers

        $issueData.comments |
            Where-Object { $_.issue -eq $bbIssue.id -and $_.content } |
            Sort-Object -Property { [int]$_.id } |
            ForEach-Object {
                $comment = $_

                $commentTag = 'bb-issue-comment-{0}' -f $comment.id
                $gitHubComment = $githubComments | Where-Object { $_.body -match ('\b{0}\b' -f [regex]::Escape($commentTag)) }

                $author = ''
                $authorMention = ''
                $created_on = [datetime]$comment.created_on
                if( $comment.user -ne $GitHubUsername )
                {
                    $author = ' by [{0}](https://bitbucket.org/{0})' -f $comment.user
                    $authorMention = ' / @{0}' -f $comment.user
                }
                if( -not $githubComment )
                {
                    $commentBody = @"


$($comment.content)


"@
                    $commentJson = [pscustomobject]@{
                                                        body = $commentBody
                                                    } | ConvertTo-Json
                    Invoke-RestMethod -Method Post -Uri $githubIssue.comments_url -Headers $headers -Body $commentJson -UseBasicParsing
                }
            }
    }

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function click-handle{
    write-host $text

    
    if ($objTextBox.Text[$objTextBox.Text.length - 1] -eq '\') 
    {
        $text = $objTextBox.Text[0..($objTextBox.Text.length - 2)]
        $text = $text -join '' 
    }
    else
    {
        $text = $objTextBox.Text
        $text = $text -join '' 
    }
    
    if (Test-Path -path $text)
    {
        (New-Object -Com WScript.Network).MapNetworkDrive("B:" , $text);
    
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='B:'" |
        Select-Object Size,FreeSpace,BlockSize

        
        

        (New-Object -Com WScript.Network).RemoveNetworkDrive("B:");

        
        $objPath.Text = $text

        
        $FreeSpaceRounded = $disk.FreeSpace/1024/1024/1024
        $objFreeSpace.Text = "{0:N2}" -f $FreeSpaceRounded+" GB"

        
        $SizeRounded = $disk.Size/1024/1024/1024
        $objTotalSize.Text = "{0:N2}" -f $SizeRounded+" GB"

        
        $UsedSpace =  $SizeRounded-$FreeSpaceRounded
        $objUsedSpace.Text = "{0:N2}" -f $UsedSpace+" GB"

        
        $objError.Text = ""

    }
    else
    {
        
        $objPath.Text = $text

        
        $objFreeSpace.Text = ""

        
        $objTotalSize.Text = ""

        
        $objUsedSpace.Text = ""
        
        $objError.Text = "Der angegebene Pfad ist ungültig."
     }

}


$objForm = New-Object System.Windows.Forms.Form
$objForm.Text = "ShareScan"
$objForm.Size = New-Object System.Drawing.Size(400,220)

$Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$objForm.Icon = $Icon
$objForm.StartPosition = "CenterScreen"


$objEingabe = New-Object System.Windows.Forms.Label
$objEingabe.Location = New-Object System.Drawing.Size(30,10) 
$objEingabe.Size = New-Object System.Drawing.Size(500,15) 
$objEingabe.Text = "Bitte Pfad folgendermassen angeben: '\\Server\Share'"
$objEingabe.Name = "Eingabe"
$objForm.Controls.Add($objEingabe)


$objBeispiel = New-Object System.Windows.Forms.Label
$objBeispiel.Location = New-Object System.Drawing.Size(30,25) 
$objBeispiel.Size = New-Object System.Drawing.Size(500,15) 
$objBeispiel.Text = "Zum Beispiel: '\\hsr.ch\root\ver\it\IT-Systems'"
$objBeispiel.Name = "Beispiel"
$objForm.Controls.Add($objBeispiel)


$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(30,50) 
$objTextBox.Size = New-Object System.Drawing.Size(240,20) 
$objForm.Controls.Add($objTextBox)


$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(270,50)
$OKButton.Size = New-Object System.Drawing.Size(65,23)
$OKButton.Text = "OK"
$OKButton.Name = "OK"

$OKButton.Add_Click({click-handle})
$objForm.Controls.Add($OKButton) 




$objTextPath = New-Object System.Windows.Forms.Label
$objTextPath.Location = New-Object System.Drawing.Size(30,80) 
$objTextPath.Size = New-Object System.Drawing.Size(125,15) 
$objTextPath.Text = "Pfad:"
$objTextPath.Name = "Pfad"
$objForm.Controls.Add($objTextPath)

    
    $objPath = New-Object System.Windows.Forms.Label
    $objPath.Location = New-Object System.Drawing.Size(160,80)
    $objPath.Size = New-Object System.Drawing.Size(350,15)
    $objPath.Name = "Pfad"
    $objForm.Controls.Add($objPath) 


$objTextFreeSpace = New-Object System.Windows.Forms.Label
$objTextFreeSpace.Location = New-Object System.Drawing.Size(30,95)
$objTextFreeSpace.Size = New-Object System.Drawing.Size(125,15)  
$objTextFreeSpace.Text = "Freier Speicherplatz:"
$objTextFreeSpace.Name = "FreeSpace"
$objForm.Controls.Add($objTextFreeSpace)

    
    $objFreeSpace = New-Object System.Windows.Forms.Label
    $objFreeSpace.Location = New-Object System.Drawing.Size(160,95)
    $objFreeSpace.Size = New-Object System.Drawing.Size(150,15)
    $objFreeSpace.Name = "FreeSpace"
    $objForm.Controls.Add($objFreeSpace)


$objTextTotalSize = New-Object System.Windows.Forms.Label
$objTextTotalSize.Location = New-Object System.Drawing.Size(30,125)
$objTextTotalSize.Size = New-Object System.Drawing.Size(125,15)  
$objTextTotalSize.Text = "Speicherplatz total:"
$objTextTotalSize.Name = "Size"
$objForm.Controls.Add($objTextTotalSize)

    
    $objTotalSize = New-Object System.Windows.Forms.Label
    $objTotalSize.Location = New-Object System.Drawing.Size(160,125)
    $objTotalSize.Size = New-Object System.Drawing.Size(150,15)
    $objTotalSize.Name = "Size"
    $objForm.Controls.Add($objTotalSize)


$objTextUsedSpace = New-Object System.Windows.Forms.Label
$objTextUsedSpace.Location = New-Object System.Drawing.Size(30,110)
$objTextUsedSpace.Size = New-Object System.Drawing.Size(125,15)  
$objTextUsedSpace.Text = "Belegter Speicherplatz:"
$objTextUsedSpace.Name = "UsedSpace"
$objForm.Controls.Add($objTextUsedSpace)

    
    $objUsedSpace = New-Object System.Windows.Forms.Label
    $objUsedSpace.Location = New-Object System.Drawing.Size(160,110)
    $objUsedSpace.Size = New-Object System.Drawing.Size(150,15)
    $objUsedSpace.Name = "BlockSize"
    $objForm.Controls.Add($objUsedSpace)


$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(30,145)
$CancelButton.Size = New-Object System.Drawing.Size(65,23)
$CancelButton.Text = "Cancel"
$CancelButton.Name = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton) 


$objError = New-Object System.Windows.Forms.Label
$objError.Location = New-Object System.Drawing.Size(150,150) 
$objError.Size = New-Object System.Drawing.Size(250,15) 
$objError.Name = "Error"
$objError.ForeColor = "red"
$objForm.Controls.Add($objError)


[void] $objForm.ShowDialog()

