









function Send-WakeOnLan
{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='MAC-Address of the remote computer which you want to wake up')]
        [ValidateScript({
            if($_ -match "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6}$")
            {
                return $true
            }
            else 
            {
                throw "Enter a valid MAC-Address (like 00:00:00:00:00:00)!" 
            }
        })]
        [String[]]$MACAddress,

        [Parameter(
            Position=1,
            HelpMessage='Port which is used to send the MagicPacket (Default=7)')]
        [ValidateRange(1,65535)]
        [Int32]$Port=7,

        [Parameter(
            Position=2,
            HelpMessage='Send MagicPacket over another Windows computer in a different subnet')]
        [String]$UseComputer,

        [Parameter(
            Position=3,
            HelpMessage='Credentials to authenticate agains a remote computer')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    Begin{
        
    }

    Process{
        [System.Management.Automation.ScriptBlock]$ScriptBlock = {
            param(
                $MACAddress,
                $Port
            )
            
            foreach($MAC in $MACAddress)
            {
                
                $MACAddr = $MAC.Replace(':','').Replace('-','')
                $MACAddrBytes = 0,2,4,6,8,10 | ForEach-Object { [System.Convert]::ToByte($MACAddr.Substring($_,2),16) }

                
                $MagicPacket = (,[byte]255 * 6) + ($MACAddrBytes * 16)
                
                
                try {
                    $UDPClient = New-Object System.Net.Sockets.UdpClient
                    $UDPClient.Connect(([System.Net.IPAddress]::Broadcast), $Port)
                    [void]$UDPClient.Send($MagicPacket, $MagicPacket.Length)    
                }
                catch {
                    Write-Error -Message "$($_.Exception.Message)" -Category ConnectionError
                }        
            }
        }

        $LocalAddress = @("127.0.0.1","localhost",".","$($env:COMPUTERNAME)")

        
        if([String]::IsNullOrEmpty($UseComputer) -or ($LocalAddress -contains $UseComputer))
        {
            Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $MACAddress, $Port
        }
        else 
        {
            if(-not(Test-Connection -ComputerName $UseComputer -Count 2 -Quiet))
            {
                Write-Error -Message "$UseComputer is not reachable!" -Category ConnectionError -ErrorAction Stop
            }

            try {
                if($PSBoundParameters['Credential'] -is [PSCredential])
                {
                    Invoke-Command -ComputerName $UseComputer -ScriptBlock $ScriptBlock -ArgumentList $MACAddress, $Port -Credential $Credential
                }
                else 
                {
                    Invoke-Command -ComputerName $UseComputer -ScriptBlock $ScriptBlock -ArgumentList $MACAddress, $Port
                }
            }   
            catch {
                throw  
            } 
        }    
    }

    End{

    }
}