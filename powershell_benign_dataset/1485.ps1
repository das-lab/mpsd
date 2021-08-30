4
function Convert-AboutTopicToHtml
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        
        $InputObject,
        
        [string]
        
        $TopicName,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ModuleName,

        [string]
        
        $TopicHeading = 'TOPIC',

        [string]
        
        $ShortDescriptionHeading = 'SHORT DESCRIPTION',

        [string]
        
        $LongDescriptionHeading = 'LONG DESCRIPTION',

        [string]
        
        $SeeAlsoHeading = 'SEE ALSO',

        [hashtable]
        
        $HeadingMap = @{},

        [string[]]
        
        $Script
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        function Complete-Section
        {
            param(
                [string]
                $Heading,

                [Parameter(Mandatory=$true)]
                [AllowEmptyString()]
                [string]
                $Body
            )

            $Body = $Body.Trim()
            switch( $Heading )
            {
                $TopicHeading
                {
                    
                }

                $SeeAlsoHeading
                {
                    $lines = $Body -split ([Environment]::NewLine) | 
                                Convert-RelatedLinkToHtml -ModuleName $ModuleName -Script $Script | 
                                ForEach-Object { '<li>{0}</li>' -f $_ }
                    $Body = @'
    <ul>
        {0}
    </ul>
'@ -f ($lines -join [Environment]::NewLine)
                }
                default
                {
                    $Body = $Body | Edit-HelpText -ModuleName $ModuleName | Convert-MarkdownToHtml 
                }
            }

            $topic | Add-Member -Name $Heading -MemberType NoteProperty -Value $Body
        }

        if( $InputObject -is [IO.FileInfo] )
        {
            [string[]]$lines = $InputObject | Get-Content
            $TopicName = $InputObject.BaseName -replace '\.help$' -f ''
        }
        elseif( $InputObject -is [string] -and $InputObject -match '^about_' )
        {
            [string[]]$lines = Get-Help -Name $InputObject
            if( -not $lines )
            {
                Write-Error ('About topic ''{0}'' not found.' -f $InputObject)
                return
            }
            $TopicName = $InputObject
        }
        else
        {
            $lines = $InputObject -split ([Environment]::NewLine)
        }

        $topic = [pscustomobject]@{ }
        $currentHeader = $null
        $currentContent = $null
        $sectionOrder = New-Object 'Collections.Generic.List[string]'
        $lastLineIdx = $lines.Count - 1
        for( $idx = 0; $idx -lt $lines.Count; ++$idx )
        {
            $line = $lines[$idx]

            if( -not $line -or $line -match '^\s+' )
            {
                if( $line.StartsWith('    ') )
                {
                    $line = $line -replace '^    ',''
                }
                elseif( $line.StartsWith('  ') )
                {
                    $line = $line -replace '^  ',''
                }

                [void]$currentContent.AppendLine( $line )
                if( $idx -eq $lastLineIdx )
                {
                    Complete-Section -Heading $currentHeader -Body $currentContent.ToString()
                }

                continue

            }
            else
            {
                
                if( $currentHeader )
                {
                    Complete-Section -Heading $currentHeader -Body $currentContent.ToString()
                }

                $currentContent = New-Object 'Text.StringBuilder'
                $currentHeader =  [Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase( $line.ToLowerInvariant() )
                $sectionOrder.Add( $currentHeader )
            }
        }

        if( -not ($topic | Get-Member -Name $TopicHeading) )
        {
            Write-Warning ('Topic ''{0}'' doesn''t have a ''{1}'' heading. Defaulting to {0}. Use the `TopicHeading` parameter to set the topic''s topic heading.' -f $TopicName,$TopicHeading)
            Complete-Section -Heading 'TOPIC' -Body $TopicName
        }

        if( -not ($topic | Get-Member -Name $ShortDescriptionHeading) )
        {
            Write-Warning ('Topic ''{0}'' doesn''t have a ''{1}'' heading. Use the `ShortDescription` parameter to set the topic''s SHORT DESCRIPTION heading.' -f $TopicName,$ShortDescriptionHeading)
            Complete-Section -Heading 'SHORT DESCRIPTION' -Body ''
        }

        if( -not $HeadingMap.ContainsKey($LongDescriptionHeading) )
        {
            $HeadingMap[$LongDescriptionHeading] = 'Description'
        }

        $content = New-Object 'Text.StringBuilder'
        foreach( $section in $sectionOrder )
        {
            if( $section -eq $TopicHeading -or $section -eq $ShortDescriptionHeading )
            {
                continue
            }

            $heading = $section
            if( $HeadingMap.ContainsKey($section) )
            {
                $heading = $HeadingMap[$section]
            }
            [void]$content.AppendLine( ('<h2>{0}</h2>' -f $heading) )
            [void]$content.AppendLine( $topic.$Section )
        }

        @'
    <h1>{0}</h1>

    {1}

    {2}

'@ -f $topic.$TopicHeading,$topic.$ShortDescriptionHeading,$content

    }

    end
    {
    }
}