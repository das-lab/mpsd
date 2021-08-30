









function Get-LastBootTime
{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            HelpMessage='ComputerName or IPv4-Address of the remote computer')]
        [String[]]$ComputerName=$env:COMPUTERNAME,

        [Parameter(
			Position=1,
			HelpMessage='Credentials to authenticate agains a remote computer')]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.CredentialAttribute()]
		$Credential
    )

    Begin{
        $LocalAddress = @("127.0.0.1","localhost",".","$($env:COMPUTERNAME)")

		[System.Management.Automation.ScriptBlock]$ScriptBlock = {
             $LastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property LastBootUpTime).LastBootUpTime
             
             return [DateTime]$LastBootTime 
        }
    }

    Process{
        foreach($ComputerName2 in $ComputerName)
        {
            if($LocalAddress -contains $ComputerName2)
            {			
                $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock
            }
            else
            {
                if(Test-Connection -ComputerName $ComputerName2 -Count 2 -Quiet)
                {
                    try {
                        if($PSBoundParameters.ContainsKey('Credential'))
                        {
                            $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName2 -Credential $Credential -ErrorAction Stop
                        }
                        else
                        {					    
                            $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName2 -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-Error -Message "$($_.Exception.Message)" -Category InvalidData

                        continue
                    }
                }
                else 
                {				
                    Write-Error -Message """$ComputerName2"" is not reachable via ICMP!" -Category ConnectionError

                    continue
                }
            }

            [pscustomobject] @{
                ComputerName = $ComputerName2
                LastBootTime = $LastBootTime
            }
        }
    }

    End{

    }
}