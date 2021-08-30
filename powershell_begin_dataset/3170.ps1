Function Get-WinEventData {
    
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0 )]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $Event,

        [string]$Prefix = 'e_'
    )

    Process
    {
        
        foreach($entry in $event)
        {
            
            $XML = [xml]$entry.ToXml()

            
            $XMLData = $null
            if( $XMLData = @( $XML.Event.EventData.Data ) )
            {
                For( $i=0; $i -lt $XMLData.count; $i++ )
                {
                    
                    $Entry = Add-Member -InputObject $entry -MemberType NoteProperty -Name "$Prefix$($XMLData[$i].name)" -Value $XMLData[$i].'
                }
            }
            $Entry
        }
    }
}