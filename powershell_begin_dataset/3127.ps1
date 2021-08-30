









function Get-WLANProfile
{
	[CmdletBinding()]
	param(
		[Parameter(
			Position=0,
			HelpMessage='Indicates that the password appears in plain text')]
		[Switch]$ShowPassword,
		
		[Parameter(
			Position=1,
			HelpMessage='Filter WLAN-Profiles by Name or SSID')]
		[String]$Search,

		[Parameter(
			Position=2,
			HelpMessage='Exact match, when filter WLAN-Profiles by Name or SSID')]
		[Switch]$ExactMatch
	)

	Begin{

	}

	Process{
		
		$Netsh_WLANProfiles = (netsh WLAN show profiles)

		
		$IsProfile = 0
		$WLAN_Names = @()
		
		
		foreach($Line in $Netsh_WLANProfiles)
		{
			if((($IsProfile -eq 2)) -and (-not([String]::IsNullOrEmpty($Line))))
			{
				$WLAN_Names += $Line.Split(':')[1].Trim()
			}
		
			if($Line.StartsWith("---"))
			{
				$IsProfile += 1
			}
		}

		
		foreach($WLAN_Name in $WLAN_Names)
		{
			$Netsh_WLANProfile = (netsh WLAN show profiles name="$WLAN_Name" key=clear)
		
			
			$InProfile = 0
			$IsConnectivity = 0
			$IsSecurity = 0
		
			foreach($Line in $Netsh_WLANProfile)
			{
				if((($InProfile -eq 2)) -and (-not([String]::IsNullOrEmpty($Line))))
				{			
					
					if($IsConnectivity -eq 1) 
					{ 
						$WLAN_SSID = $Line.Split(':')[1].Trim()
						$WLAN_SSID = $WLAN_SSID.Substring(1,$WLAN_SSID.Length -2)
					}

					$IsConnectivity += 1
				}

				if((($InProfile -eq 3)) -and (-not([String]::IsNullOrEmpty($Line))))
				{			
					if($IsSecurity -eq 0) 
					{
						$WLAN_Authentication = $Line.Split(':')[1].Trim()
					}
					elseif($IsSecurity -eq 3) 
					{
						$WLAN_Password_PlainText = $Line.Split(':')[1].Trim()
					}
				
					$IsSecurity += 1   
				}
		
				if($Line.StartsWith("---"))
				{
					$InProfile += 1
				}   
			}

			
			if($ShowPassword) 
			{
				$WLAN_Password = $WLAN_Password_PlainText
			}
			else
			{
				$WLAN_Password = ConvertTo-SecureString -String "$WLAN_Password_PlainText" -AsPlainText -Force
			}

			
			$WLAN_Profile = [pscustomobject] @{
				Name = $WLAN_Name
				SSID = $WLAN_SSID
				Authentication = $WLAN_Authentication
				Password = $WLAN_Password
			}

			
			if($PSBoundParameters.ContainsKey('Search'))
			{
				if((($WLAN_Profile.Name -like $Search) -or ($WLAN_Profile.SSID -like $Search)) -and (-not($ExactMatch) -or ($WLAN_Profile.Name -eq $Search) -or ($WLAN_Profile.SSID -eq $Search)))
				{
					$WLAN_Profile
				} 
			}
			else
			{
				$WLAN_Profile
			}        
		}
	}

	End{
		
	}
}