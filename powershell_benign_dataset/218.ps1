function Get-LocalUser
{



	PARAM
	(
		[Alias('cn')]
		[String[]]$ComputerName = $Env:COMPUTERNAME,

		[String]$AccountName,

		[System.Management.Automation.PsCredential]$Credential
	)

	$Splatting = @{
		Class = "Win32_UserAccount"
		Namespace = "root\cimv2"
		Filter = "LocalAccount='$True'"
	}

	
	If ($PSBoundParameters['Credential']) { $Splatting.Credential = $Credential }

	Foreach ($Computer in $ComputerName)
	{
		TRY
		{
			Write-Verbose -Message "[PROCESS] ComputerName: $Computer"
			Get-WmiObject @Splatting -ComputerName $Computer | Select-Object -Property Name, FullName, Caption, Disabled, Status, Lockout, PasswordChangeable, PasswordExpires, PasswordRequired, SID, SIDType, AccountType, Domain, Description
		}
		CATCH
		{
			Write-Warning -Message "[PROCESS] Issue connecting to $Computer"
		}
	}
}