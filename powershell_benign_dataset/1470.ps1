
function Split-MarkdownTopic
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        
        $ConfigFileRoot,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        
        $TopicInfo
    )
    process
    {
        Set-StrictMode -Version Latest

        $path = $TopicInfo.Path
        if( -not (Test-Path -Path $path -PathType Leaf) )
        {
            Write-Error ('Markdown help topic <{0}> not found.' -f $path)
            return
        }

        $content = New-Object Collections.ArrayList
        $sectionName = $null
        $eof = [Guid]::NewGuid().ToString()
        $topic = New-Object PsObject -Property @{ Name = ''; Synopsis = ''; Description = ''; RelatedLinks = ''; FileName = $TopicInfo.FileName }
        $lineNum = 0
        Invoke-Command { Get-Content -Path $path ; $eof } | ForEach-Object {
            if( $_ -match '^
            {
                if( $sectionName -or $_ -eq $eof )
                {
                    $topic.$sectionName = $content -join "`n"
                    $topic.$sectionName = $topic.$sectionName.Trim()
                    if( $_ -eq $eof )
                    {
                        return
                    }
                    $content.Clear()
                }


                $sectionName = $matches[1]
                switch -Regex ($sectionName)
                {
                    'Topic|Name' 
                    {
                        $sectionName = 'Name'
                    }
                    'Short Description|Synopsis'
                    {
                        $sectionName = 'Synopsis'
                    }
                    'Long Description|Description'
                    {
                        $sectionName = 'Description'
                    }
                    'See Also|(Related )?Links?'
                    {
                        $sectionName = 'RelatedLinks'
                    }
                    default
                    {
                        Write-Error ('{0}: line {1}: Unknown top-level heading <{2}>.  Expected <Name>, <Synopsis>, <Description>, or <Link>. <Link> may be used multiple times.' -f $path,$lineNum,$_)
                    }
                }
            }
            else
            {
                if( -not $sectionName )
                {
                    Write-Error ('{0}: line {1}: Invalid Markdown help topic: the first line must be `
                    return
                }
                [void] $content.Add( $_ )
            }
            ++$lineNum
        }

        if( $TopicInfo | Get-Member Title )
        {
            $topic.Name = $TopicInfo.Title
        }
        return $topic
    }
}