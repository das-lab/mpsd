









function Get-WindowsProductKey
{
	[CmdletBinding()]
	param(
		[Parameter(
			Position=0,
			HelpMessage='ComputerName or IPv4-Address of the remote computer')]
		[String[]]$ComputerName = $env:COMPUTERNAME,

		[Parameter(
			Position=1,
			HelpMessage='Credentials to authenticate agains a remote computer')]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.CredentialAttribute()]
		$Credential
	)

	Begin{
		$LocalAddress = @("127.0.0.1","localhost",".","$($env:COMPUTERNAME)")

		[System.Management.Automation.ScriptBlock]$Scriptblock = {
			$ProductKeyValue = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").digitalproductid[0x34..0x42]
			$Wmi_Win32OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, CSDVersion, Version, OSArchitecture, BuildNumber, SerialNumber

			[pscustomobject] @{
				ProductKeyValue = $ProductKeyValue
				Wmi_Win32OperatingSystem = $Wmi_Win32OperatingSystem				
			}
		}
	}

	Process{   
		foreach($ComputerName2 in $ComputerName) 
		{              
			$Chars="BCDFGHJKMPQRTVWXY2346789" 

			
			if($LocalAddress -contains $ComputerName2)
			{
				$ComputerName2 = $env:COMPUTERNAME
 
				$Scriptblock_Result = Invoke-Command -ScriptBlock $Scriptblock
			}
			else
			{
				if(-not(Test-Connection -ComputerName $ComputerName2 -Count 2 -Quiet))
				{
					Write-Error -Message "$ComputerName2 is not reachable via ICMP!" -Category ConnectionError
					continue
				}

				try {
					if($PSBoundParameters['Credential'] -is [System.Management.Automation.PSCredential])
					{
						$Scriptblock_Result = Invoke-Command -ScriptBlock $Scriptblock -ComputerName $ComputerName2 -Credential $Credential -ErrorAction Stop
					}
					else
					{					    
						$Scriptblock_Result = Invoke-Command -ScriptBlock $Scriptblock -ComputerName $ComputerName2 -ErrorAction Stop
					}
				}
				catch {
					Write-Error -Message "$($_.Exception.Message)" -Category ConnectionError
					continue	
				}
			}
		
			$ProductKey = ""

			for($i = 24; $i -ge 0; $i--) 
			{ 
				$r = 0 

				for($j = 14; $j -ge 0; $j--) 
				{ 
					$r = ($r * 256) -bxor $Scriptblock_Result.ProductKeyValue[$j] 
					$Scriptblock_Result.ProductKeyValue[$j] = [math]::Floor([double]($r/24)) 
					$r = $r % 24 
				}
	
				$ProductKey = $Chars[$r] + $ProductKey 

				if (($i % 5) -eq 0 -and $i -ne 0) 
				{ 
					$ProductKey = "-" + $ProductKey 
				} 
			} 

			[pscustomobject] @{
				ComputerName = $ComputerName2
				Caption = $Scriptblock_Result.Wmi_Win32OperatingSystem.Caption
				CSDVersion = $Scriptblock_Result.Wmi_Win32OperatingSystem.CSDVersion
				WindowsVersion = $Scriptblock_Result.Wmi_Win32OperatingSystem.Version
				OSArchitecture = $Scriptblock_Result.Wmi_Win32OperatingSystem.OSArchitecture
				BuildNumber = $Scriptblock_Result.Wmi_Win32OperatingSystem.BuildNumber
				SerialNumber = $Scriptblock_Result.Wmi_Win32OperatingSystem.SerialNumber
				ProductKey = $ProductKey
			}     
		}   
	}

	End{
		
	}
}