














function Test-AddEndpoint
{
	$endpointName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup
	$profileName = getAssetname

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

    TestSetup-AddEndpoint $endpointName $profile

	Assert-AreEqual 1 $profile.Endpoints.Count
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-DeleteEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

    TestSetup-AddEndpoint $endpointName $profile

	Remove-AzTrafficManagerEndpointConfig -EndpointName $endpointName -TrafficManagerProfile $profile

	Assert-AreEqual 0 $profile.Endpoints.Count
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EndpointCrud
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	

    $endpoint.EndpointStatus = "Disabled"

    $endpoint = Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Disabled" $endpoint.EndpointStatus
	

	$removed = Remove-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Force

    Assert-True { $removed }

    Assert-Throws { Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EndpointCrudGeo
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Geographic"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -GeoMapping "GEO-NA","GEO-SA"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	Assert-AreEqual "GEO-NA" $endpoint.GeoMapping[0];
	Assert-AreEqual "GEO-SA" $endpoint.GeoMapping[1];

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	Assert-AreEqual "GEO-NA" $endpoint.GeoMapping[0];
	Assert-AreEqual "GEO-SA" $endpoint.GeoMapping[1];

    $endpoint.GeoMapping.Add("GEO-AP");

    $endpoint = Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	Assert-AreEqual "GEO-NA" $endpoint.GeoMapping[0];
	Assert-AreEqual "GEO-SA" $endpoint.GeoMapping[1];
	Assert-AreEqual "GEO-AP" $endpoint.GeoMapping[2];

	$removed = Remove-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Force

    Assert-True { $removed }

    Assert-Throws { Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EndpointCrudPiping
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	Assert-NotNull $endpoint
	Assert-AreEqual $endpointName $endpoint.Name 
	Assert-AreEqual $profileName $endpoint.ProfileName 
	Assert-AreEqual $resourceGroup.ResourceGroupName $endpoint.ResourceGroupName 
	Assert-AreEqual "ExternalEndpoints" $endpoint.Type
	Assert-AreEqual "www.contoso.com" $endpoint.Target
	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	

    $removed = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" | Set-AzTrafficManagerEndpoint | Remove-AzTrafficManagerEndpoint -Force

    Assert-True { $removed }

    Assert-Throws { Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-CreateExistingEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

    Assert-Throws { New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName  -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-CreateExistingEndpointFromNonExistingProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

    try
	{
	Assert-Throws { New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-RemoveExistingEndpointFromNonExistingProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

    try
	{
	Assert-Throws { Remove-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-GetExistingEndpointFromNonExistingProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

    try
	{
	Assert-Throws { Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-RemoveNonExistingEndpointFromProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

    try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

    Assert-Throws { Remove-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EnableEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Disabled" -EndpointLocation "North Europe"

	Assert-AreEqual "Disabled" $endpoint.EndpointStatus

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-True { Enable-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-DisableEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	Assert-AreEqual "Enabled" $endpoint.EndpointStatus

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-True { Disable-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Force }

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual "Disabled" $endpoint.EndpointStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EnableEndpointUsingPiping
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Disabled" -EndpointLocation "North Europe"

	Assert-AreEqual "Disabled" $endpoint.EndpointStatus

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-True { Enable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint }

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EnableEndpointUsingPipingFromGetProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Disabled" -EndpointLocation "North Europe"

	Assert-AreEqual "Disabled" $endpoint.EndpointStatus

    $retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	
	Assert-True { Enable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $retrievedProfile.Endpoints[0] }

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-AreEqual "Enabled" $endpoint.EndpointStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-DisableEndpointUsingPiping
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	Assert-AreEqual "Enabled" $endpoint.EndpointStatus

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-True { Disable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint -Force }

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-NotNull $endpoint
	Assert-AreEqual "Disabled" $endpoint.EndpointStatus
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EnableNonExistingEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

	Assert-Throws { Enable-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-DisableNonExistingEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName

	Assert-Throws { Disable-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" }
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-EndpointTypeCaseInsensitive
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Priority"

	$type = "exTernalendpoInTS"
	$endpoint = New-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"
	$type = "ExTernalendpoInTS"
	Assert-True { Disable-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force }
	$type = "EXTernalendpoInTS"
	Assert-True { Enable-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName }
	$type = "EXTErnalendpoInTS"
    $endpoint = Get-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	$type = "EXTERnalendpoInTS"
	$endpoint | Set-AzTrafficManagerEndpoint
	$type = "EXTERNalendpoInTS"
	Remove-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-PipeEndpointFromGetEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Priority"

	$type = "EXternalendpointS"
	New-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"
	$endpoint = Get-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-True { Disable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint -Force }
	Assert-True { Enable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint }
    
	Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint
	Remove-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}



function Test-PipeEndpointFromGetProfile
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Priority"

	$type = "exterNAleNdpOints"
	New-AzTrafficManagerEndpoint -Type $type -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"
	$profile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	$endpoint = $profile.Endpoints[0]
	
	Assert-True { Disable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint -Force }
	Assert-True { Enable-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint }
    
	Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint
	Remove-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint -Force
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-AddAndRemoveCustomHeadersFromEndpoint
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Disabled" -EndpointLocation "West US"

    $retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	
    $retrievedEndpoint = $retrievedProfile.Endpoints[0]

	Assert-True { Add-AzTrafficManagerCustomHeaderToEndpoint -Name "foo" -Value "bar" -TrafficManagerEndpoint $retrievedEndpoint }

    Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $retrievedEndpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

	Assert-AreEqual "foo" $endpoint.CustomHeaders[0].Name
	Assert-AreEqual "bar" $endpoint.CustomHeaders[0].Value
	Assert-AreEqual 1 $endpoint.CustomHeaders.Count

	Assert-True { Remove-AzTrafficManagerCustomHeaderFromEndpoint -Name "foo" -TrafficManagerEndpoint $endpoint }

    Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

    Assert-AreEqual 0 $endpoint.CustomHeaders.Count

	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}


function Test-AddAndRemoveIpAddressRanges
{
	$endpointName = getAssetname
	$profileName = getAssetname
	$resourceGroup = TestSetup-CreateResourceGroup

	try
	{
	$profile = TestSetup-CreateProfile $profileName $resourceGroup.ResourceGroupName "Weighted"

	$endpoint = New-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Disabled" -EndpointLocation "West US"

    $retrievedProfile = Get-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
	
    $retrievedEndpoint = $retrievedProfile.Endpoints[0]

	Assert-True { Add-AzTrafficManagerIpAddressRange -TrafficManagerEndpoint $retrievedEndpoint -First "2.3.4.0" -Scope 24 }
	Assert-True { Add-AzTrafficManagerIpAddressRange -TrafficManagerEndpoint $retrievedEndpoint -First "5.6.0.0" -Last "5.6.255.255" }

    Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $retrievedEndpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

    Assert-AreEqual 2 $endpoint.SubnetMapping.Count
	Assert-AreEqual "2.3.4.0" $endpoint.SubnetMapping[0].First
	Assert-AreEqual 24 $endpoint.SubnetMapping[0].Scope
	Assert-AreEqual "5.6.0.0" $endpoint.SubnetMapping[1].First
	Assert-AreEqual "5.6.255.255" $endpoint.SubnetMapping[1].Last

	Assert-True { Remove-AzTrafficManagerIpAddressRange -First 2.3.4.0 -TrafficManagerEndpoint $endpoint }

    Set-AzTrafficManagerEndpoint -TrafficManagerEndpoint $endpoint

    $endpoint = Get-AzTrafficManagerEndpoint -Name $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Type "ExternalEndpoints"

    Assert-AreEqual 1 $endpoint.SubnetMapping.Count
	Assert-AreEqual "5.6.0.0" $endpoint.SubnetMapping[0].First
	Assert-AreEqual "5.6.255.255" $endpoint.SubnetMapping[0].Last
	}
    finally
    {
        
        TestCleanup-RemoveResourceGroup $resourceGroup.ResourceGroupName
    }
}