function Invoke-PasswordRoll {
	
	[CmdletBinding(DefaultParameterSetName = "Encryption")]
	Param (
		[Parameter(Mandatory = $true)]
		[String[]]
		$ComputerName,
		
		[Parameter(Mandatory = $true)]
		[String[]]
		$LocalAccounts,
		
		[Parameter(Mandatory = $true)]
		[String]
		$TsvFileName,
		
		[Parameter(ParameterSetName = "Encryption", Mandatory = $true)]
		[String]
		$EncryptionKey,
		
		[Parameter()]
		[ValidateRange(20, 120)]
		[Int]
		$PasswordLength = 20,
		
		[Parameter(ParameterSetName = "NoEncryption", Mandatory = $true)]
		[Switch]
		$NoEncryption
	)
	
	
	
	Add-Type -AssemblyName "System.Web" -ErrorAction Stop
	
	
	
	$RemoteRollScript = {
		Param (
			[Parameter(Mandatory = $true, Position = 1)]
			[String[]]
			$Passwords,
			
			[Parameter(Mandatory = $true, Position = 2)]
			[String[]]
			$LocalAccounts,
			
			
			[Parameter(Mandatory = $true, Position = 3)]
			[String]
			$TargettedServerName
		)
		
		$LocalUsers = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=true" | Foreach { $_.Name }
		
		
		foreach ($User in $LocalUsers) {
			if ($LocalAccounts -inotcontains $User) {
				Write-Warning "Server: '$($TargettedServerName)' has a local account '$($User)' whos password is NOT being changed by this script"
			}
		}
		
		
		$PasswordIndex = 0
		foreach ($LocalAdmin in $LocalAccounts) {
			$Password = $Passwords[$PasswordIndex]
			
			if ($LocalUsers -icontains $LocalAdmin) {
				try {
					$objUser = [ADSI]"WinNT://localhost/$($LocalAdmin), user"
					$objUser.psbase.Invoke("SetPassword", $Password)
					
					$Properties = @{
						TargettedServerName = $TargettedServerName
						Username = $LocalAdmin
						Password = $Password
						RealServerName = $env:computername
					}
					
					$ReturnData = New-Object PSObject -Property $Properties
					Write-Output $ReturnData
				} catch {
					Write-Error "Error changing password for user:$($LocalAdmin) on server:$($TargettedServerName)"
				}
			}
			
			$PasswordIndex++
		}
	}
	
	
	
	
	function Create-RandomPassword {
		Param (
			[Parameter(Mandatory = $true)]
			[ValidateRange(20, 120)]
			[Int]
			$PasswordLength
		)
		
		$Password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $PasswordLength / 4)
		
		
		if ($Password.Length -ne $PasswordLength) {
			throw new Exception("Password returned by GeneratePassword is not the same length as required. Required length: $($PasswordLength). Generated length: $($Password.Length)")
		}
		
		return $Password
	}
	
	
	
	if ($PsCmdlet.ParameterSetName -ieq "Encryption") {
		try {
			$Sha256 = new-object System.Security.Cryptography.SHA256CryptoServiceProvider
			$SecureStringKey = $Sha256.ComputeHash([System.Text.UnicodeEncoding]::Unicode.GetBytes($EncryptionKey))
		} catch {
			Write-Error "Error creating TSV encryption key" -ErrorAction Stop
		}
	}
	
	foreach ($Computer in $ComputerName) {
		
		$Passwords = @()
		for ($i = 0; $i -lt $LocalAccounts.Length; $i++) {
			$Passwords += Create-RandomPassword -PasswordLength $PasswordLength
		}
		
		Write-Output "Connecting to server '$($Computer)' to roll specified local admin passwords"
		$Result = Invoke-Command -ScriptBlock $RemoteRollScript -ArgumentList @($Passwords, $LocalAccounts, $Computer) -ComputerName $Computer
		
		if ($Result -ne $null) {
			if ($PsCmdlet.ParameterSetName -ieq "NoEncryption") {
				$Result | Select-Object Username, Password, TargettedServerName, RealServerName | Export-Csv -Append -Path $TsvFileName -NoTypeInformation
			} else {
				
				$Result = $Result | Select-Object Username, Password, TargettedServerName, RealServerName
				
				foreach ($Record in $Result) {
					$PasswordSecureString = ConvertTo-SecureString -AsPlainText -Force -String ($Record.Password)
					$Record | Add-Member -MemberType NoteProperty -Name EncryptedPassword -Value (ConvertFrom-SecureString -Key $SecureStringKey -SecureString $PasswordSecureString)
					$Record.PSObject.Properties.Remove("Password")
					$Record | Select-Object Username, EncryptedPassword, TargettedServerName, RealServerName | Export-Csv -Append -Path $TsvFileName -NoTypeInformation
				}
			}
		}
	}
}

function ConvertTo-CleartextPassword {
	
	Param (
		[Parameter(Mandatory = $true)]
		[String]
		$EncryptedPassword,
		
		[Parameter(Mandatory = $true)]
		[String]
		$EncryptionKey
	)
	
	$Sha256 = new-object System.Security.Cryptography.SHA256CryptoServiceProvider
	$SecureStringKey = $Sha256.ComputeHash([System.Text.UnicodeEncoding]::Unicode.GetBytes($EncryptionKey))
	
	[SecureString]$SecureStringPassword = ConvertTo-SecureString -String $EncryptedPassword -Key $SecureStringKey
	Write-Output ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecureStringPassword)))
}

Invoke-PasswordRoll -ComputerName a-w7x86-1 -LocalAccounts 'aidet' -NoEncryption -TsvFileName 'file.tsv'