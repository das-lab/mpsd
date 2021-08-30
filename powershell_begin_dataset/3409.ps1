
















$rgname = "webappsslbindingrb"
$appname = "webappsslbindingtest"
$slot = "testslot"
$prodHostname = "www.webappsslbindingtests.com"
$slotHostname = "testslot.webappsslbindingtests.com"
$thumbprint = "40D6600B0B8740C41BA4B3D13B967DDEF6ED1918"


function Test-CreateNewWebAppSSLBinding
{
	try
	{
		
		$createResult = New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		Assert-AreEqual $prodHostname $createResult.Name

		
		$createResult = New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint
		Assert-AreEqual $slotHostname $createResult.Name
	}
    finally
    {
		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-GetNewWebAppSSLBinding
{
	try
	{
		
		$createWebAppResult = New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		$createWebAppSlotResult = New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint

		
		$getResult = Get-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname
		Assert-AreEqual 2 $getResult.Count
		$currentHostNames = $getResult | Select -expand Name
		Assert-True { $currentHostNames -contains $createWebAppResult.Name }
		$getResult = Get-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname
		Assert-AreEqual $getResult.Name $createWebAppResult.Name

		
		$getResult = Get-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot
		Assert-AreEqual 1 $getResult.Count
		$currentHostNames = $getResult | Select -expand Name
		Assert-True { $currentHostNames -contains $createWebAppSlotResult.Name }
		$getResult = Get-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname
		Assert-AreEqual $getResult.Name $createWebAppSlotResult.Name
	}
    finally
    {
		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-RemoveNewWebAppSSLBinding
{
	try
	{
		
		New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint
		New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Thumbprint $thumbprint

		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 

		
		$res = Get-AzureRMWebAppSSLBinding  -ResourceGroupName $rgname -WebAppName  $appname
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $prodHostname }

		$res = Get-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $slotHostName }
	}
    finally
    {
		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Force
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostname -Force 
    }
}


function Test-WebAppSSLBindingPipeSupport
{
	try
	{
		
		$webapp = Get-AzureRMWebApp  -ResourceGroupName $rgname -Name  $appname
		$webappslot = Get-AzureRMWebAppSlot  -ResourceGroupName $rgname -Name  $appname -Slot $slot

		
		$createResult = $webapp | New-AzureRMWebAppSSLBinding -Name $prodHostName -Thumbprint $thumbprint
		Assert-AreEqual $prodHostName $createResult.Name

		$createResult = $webappslot | New-AzureRMWebAppSSLBinding -Name $slotHostName -Thumbprint $thumbprint
		Assert-AreEqual $slotHostName $createResult.Name

		
		$getResult = $webapp |  Get-AzureRMWebAppSSLBinding
		Assert-AreEqual 2 $getResult.Count

		$getResult = $webappslot | Get-AzureRMWebAppSSLBinding
		Assert-AreEqual 1 $getResult.Count

		
		$webapp | Remove-AzureRMWebAppSSLBinding -Name $prodHostName -Force 
		$res = $webapp | Get-AzureRMWebAppSSLBinding
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $prodHostName }

		$webappslot | Remove-AzureRMWebAppSSLBinding -Name $slotHostName -Force 
		$res = $webappslot | Get-AzureRMWebAppSSLBinding
		$currentHostNames = $res | Select -expand Name
		Assert-False { $currentHostNames -contains $slotHostName }
	}
    finally
    {
		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostName -Force 
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Slot $slot -Name $slotHostName -Force 
    }
}


function Test-GetWebAppCertificate
{
	try
	{
		
		New-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostname -Thumbprint $thumbprint

		
		$certificates = Get-AzureRMWebAppCertificate
		$thumbprints = $certificates | Select -expand Thumbprint
		Assert-True { $thumbprints -contains $thumbprint }

		$certificate = Get-AzureRMWebAppCertificate -Thumbprint $thumbprint
		Assert-AreEqual $thumbprint $certificate.Thumbprint
	}
    finally
    {
		
		Remove-AzureRMWebAppSSLBinding -ResourceGroupName $rgname -WebAppName  $appname -Name $prodHostName -Force 
    }
}