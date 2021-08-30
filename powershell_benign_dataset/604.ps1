

function Send-PPErrorReport{



	param(
		[Parameter(Mandatory=$true)]
		[String]
		$FileName,

        [Parameter(Mandatory=$true)]
		[String]
		$ScriptName,
		
		[switch]
		$ClearErrorVariable  
	)

	
	
	
	
	if($Error){ 	
		
		$Error
		
		
		$Body = ""

		
		$Error | foreach{$Body += $_.ToString() + $_.InvocationInfo.PositionMessage + "`n`n"}

		
		$Mail = Get-PPConfiguration $PSconfigs.Mail.Filter | %{$_.Content.Mail | where{$_.Name -eq $PSconfigs.Mail.ErrorClass}} | select -first 1

		
		Send-MailMessage -To $Mail.ReplyToAddress -From $Mail.FromAddress -Subject ($env:COMPUTERNAME + " " + $ScriptName + " 

		
		if($ClearErrorVariable){$error.clear()}
	}
}

