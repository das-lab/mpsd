
















$rgname = "lketmtestantps10"
$appname = "lketmtestantps10"
$slot = "testslot"
$prodHostname = "www.adorenow.net"
$slotHostname = "testslot.adorenow.net"
$thumbprint = "F75A7A8C033FBEA02A1578812DB289277E23EAB1"


function Test-CreateNewWebAppSSLBinding
{
	try
	{
		
		
		$createResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		Assert-AreEqual $prodHostname $createResult.Name

		
		$createResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint
		Assert-AreEqual $slotHostname $createResult.Name
	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-GetNewWebAppSSLBinding
{
	try
	{
		
		$createWebAppResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		$createWebAppSlotResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint

		
		$getResult = Get-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname
    Assert-AreEqual 1 $getResult.Count
		$currentHostNames = $getResult | Select -expand Name
		Assert-True { $currentHostNames -contains $createWebAppResult.Name }
		$getResult = Get-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname
		Assert-AreEqual $getResult.Name $createWebAppResult.Name

		
		$getResult = Get-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot
    Assert-AreEqual 1 $getResult.Count
		$currentHostNames = $getResult | Select -expand Name
		Assert-True { $currentHostNames -contains $createWebAppSlotResult.Name }
		$getResult = Get-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname
		Assert-AreEqual $getResult.Name $createWebAppSlotResult.Name
	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-RemoveNewWebAppSSLBinding
{
	try
	{
		
		New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint

		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 

		
		$res = Get-AzWebAppSSLBinding  -ResourceGroupName $rgname -WebAppName  $appname
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $prodHostname }

		$res = Get-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $slotHostName }
	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-WebAppSSLBindingPipeSupport
{
	try
	{
		
		$webapp = Get-AzWebApp  -ResourceGroupName $rgname -Name  $appname
		$webappslot = Get-AzWebAppSlot  -ResourceGroupName $rgname -Name  $appname -Slot $slot

		
		$createResult = $webapp | New-AzWebAppSSLBinding -Name $prodHostName -Thumbprint $thumbprint
		Assert-AreEqual $prodHostName $createResult.Name

		$createResult = $webappslot | New-AzWebAppSSLBinding -Name $slotHostName -Thumbprint $thumbprint
		Assert-AreEqual $slotHostName $createResult.Name

		
		$getResult = $webapp |  Get-AzWebAppSSLBinding
		Assert-AreEqual 1 $getResult.Count

		$getResult = $webappslot | Get-AzWebAppSSLBinding
		Assert-AreEqual 1 $getResult.Count

		
		$webapp | Remove-AzWebAppSSLBinding -Name $prodHostName -Force 
		$res = $webapp | Get-AzWebAppSSLBinding
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $prodHostName }

		$webappslot | Remove-AzWebAppSSLBinding -Name $slotHostName -Force 
		$res = $webappslot | Get-AzWebAppSSLBinding
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $slotHostName }
	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostName -Force 
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostName -Force 
    }
}


function Test-GetWebAppCertificate
{
	try
	{
		
		New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint

		
		$certificates = Get-AzWebAppCertificate
		$thumbprints = $certificates | Select -expand Thumbprint
		Assert-True { $thumbprints -contains $thumbprint }

		$certificate = Get-AzWebAppCertificate -Thumbprint $thumbprint
		Assert-AreEqual $thumbprint $certificate.Thumbprint
	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostName -Force 
    }
}


function Test-TagsNotRemovedByCreateNewWebAppSSLBinding
{
	try
	{
		
		$getWebAppResult = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		Assert-notNull $getWebAppResult.Tags
		$tagsApp = $getWebAppResult.Tags

		
		$createBindingResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		Assert-AreEqual $prodHostname $createBindingResult.Name
		
		
		$getResult = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		Assert-notNull $getResult.Tags
		foreach($key in $tagsApp.Keys)
		{
			Assert-AreEqual $tagsApp[$key] $getResult.Tags[$key]
		}

		
		$getSlotResult = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot
		Assert-notNull $getSlotResult.Tags
		$tagsSlot = $getSlotResult.Tags

		
		$createSlotBindingResult = New-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint
		Assert-AreEqual $slotHostname $createSlotBindingResult.Name

		
		$getSlotResult2 = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot
		Assert-notNull $getSlotResult2.Tags
		foreach($key in $tagsSlot.Keys)
		{
			Assert-AreEqual $tagsSlot[$key] $getSlotResult2.Tags[$key]
		}

	}
    finally
    {
		
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}