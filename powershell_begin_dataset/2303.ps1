


[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline,
				   ValueFromPipelineByPropertyName)]
		[ValidateScript({ Test-Connection $_ -Quiet -Count 1 })]
		[string[]]$Computername = 'localhost',
		[Parameter()]
		[ValidateRange(20, 120)]
		[int]$PasswordLength = 50,
		[Parameter(Mandatory)]
		[string]$PasswordFilePath,
		[Parameter()]
		[string]$EncryptionKey,
		[Parameter()]
		[switch]$EnableAccount
	)

begin {
	function Create-RandomPassword {
		
		Param (
			[Parameter(Mandatory = $true)]
			[ValidateRange(20, 120)]
			[Int]$PasswordLength
		)
		
		$Password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $PasswordLength / 4)
		
		
		if ($Password.Length -ne $PasswordLength) {
			throw new Exception("Password returned by GeneratePassword is not the same length as required. Required length: $($PasswordLength). Generated length: $($Password.Length)")
		}
		
		return $Password
	}
	
	function Set-Encryption ($UnencryptedPassword, $EncryptionKey) {
		try {
			$PasswordSecureString = ConvertTo-SecureString -AsPlainText -Force -String $UnencryptedPassword
			
			$Sha256 = new-object System.Security.Cryptography.SHA256CryptoServiceProvider
			$SecureString = $Sha256.ComputeHash([System.Text.UnicodeEncoding]::Unicode.GetBytes($EncryptionKey))
			
			ConvertFrom-SecureString -Key $SecureString -SecureString $PasswordSecureString
		} catch {
			Write-Error "Error creating encryption key" -ErrorAction Stop
			$_.Exception.Message
		}
	}
	
	function ConvertTo-CleartextPassword {
		
		Param (
			[Parameter(Mandatory)]
			[String]$EncryptedPassword,
			
			[Parameter(Mandatory)]
			[String]$EncryptionKey
		)
		
		$Sha256 = new-object System.Security.Cryptography.SHA256CryptoServiceProvider
		$SecureStringKey = $Sha256.ComputeHash([System.Text.UnicodeEncoding]::Unicode.GetBytes($EncryptionKey))
		
		[SecureString]$SecureStringPassword = ConvertTo-SecureString -String $EncryptedPassword -Key $SecureStringKey
		Write-Output ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecureStringPassword)))
	}
	
	
	Add-Type -AssemblyName "System.Web" -ErrorAction Stop
}

process {
	foreach ($Computer in $Computername) {
		try {
			$Properties = @{
				ComputerName = $Computer
				Username = ''
				Password = ''
				PasswordType = ''
				Result = ''
				EnabledAccount = ''
			}
			if (!(Test-Connection -ComputerName $Computer -Quiet -Count 1)) {
				Write-Warning "Computer '$Computer' is not online"
				$Properties.Result = 'Offline'
				[pscustomobject]$Properties | Export-Csv -Path $PasswordFilePath -Delimiter "`t" -Append -NoTypeInformation
			} else {
				$LocalUsers = Get-WmiObject -ComputerName $Computer -Class Win32_UserAccount -Filter "LocalAccount=true"
				Write-Verbose "Found $($LocalUsers.Count) local users on $Computer"
				foreach ($LocalUser in $LocalUsers) {
					Write-Verbose "--Checking username $($LocalUser.Name) for administrator account"
					$oUser = [ADSI]"WinNT://$Computer/$($LocalUser.Name), user"
					$Sid = $oUser.objectSid.ToString().Replace(' ', '')
					if ($Sid.StartsWith('1500000521') -and $Sid.EndsWith('4100')) {
						Write-Verbose "--Username $($LocalUser.Name)|SID '$Sid' is the local administrator account"
						$LocalAdministrator = $LocalUser
						break
					}
				}
				
				$Properties.UserName = $LocalAdministrator.Name
				Write-Verbose "Creating random password for $($LocalAdministrator.Name)"
				$Password = Create-RandomPassword -PasswordLength $PasswordLength
				if ($EncryptionKey) {
					$Properties.PasswordType = 'Encrypted'
					$Properties.Password = (Set-Encryption $Password $EncryptionKey)
				} else {
					$Properties.Password = $Password
					$Properties.PasswordType = 'Unencrypted'
				}
					
				$oUser.psbase.Invoke("SetPassword", $Password)
				$Properties.Result = 'Success'
				
				
				Write-Verbose "Checking to ensure local administrator '$($LocalAdministrator.Name)' is enabled"
				if ($LocalAdministrator.Disabled) {
					Write-Verbose "Local administrator '$($LocalAdministrator.Name)' is disabled.  Enabling..."
					$Properties.EnabledAccount = 'True'
					$LocalAdministrator.Disabled = $false
					$LocalAdministrator.Put() | Out-Null
				} else {
					$Properties.EnabledAccount = 'False'
					Write-Verbose "Local administrator '$($LocalAdministrator.Name)' is already enabled."
				}
				
				[pscustomobject]$Properties | Export-Csv -Path $PasswordFilePath -Delimiter "`t" -Append -NoTypeInformation
			}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}