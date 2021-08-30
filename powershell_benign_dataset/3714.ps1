


















$global:resourceType = "Microsoft.Devices/IotHubs"



function Test-AzureRmIotHubLifecycle
{
	$Location = Get-Location "Microsoft.Devices" "IotHub" 
	$IotHubName = getAssetName 
	$ResourceGroupName = getAssetName 
	$SubscriptionId = '91d12660-3dec-467a-be2a-213b5544ddc0'
	$Sku = "B1"
	$namespaceName = getAssetName 'eventHub'
	$eventHubName = getAssetName
	$authRuleName = getAssetName
	$Tag1Key = "key1"
	$Tag2Key = "key2"
	$Tag1Value = "value1"
	$Tag2Value = "value2"

	
	$allIotHubs = Get-AzIotHub

	Assert-True { $allIotHubs[0].Type -eq $global:resourceType }
	Assert-True { $allIotHubs.Count -gt 1 }

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	Write-Debug " Create new eventHub " 
    $result = New-AzEventHubNamespace -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName -Location $Location

	Wait-Seconds 15
    
	
	Assert-True {$result.ProvisioningState -eq "Succeeded"}

    Write-Debug " Create new eventHub "    
	$msgRetentionInDays = 3
	$partionCount = 2
    $result = New-AzEventHub -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName -EventHubName $eventHubName -MessageRetentionInDays $msgRetentionInDays -PartitionCount $partionCount

	
	$rights = "Listen","Send"
	$authRule = New-AzEventHubAuthorizationRule -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName  -EventHubName $eventHubName -AuthorizationRuleName $authRuleName -Rights $rights
	$keys = Get-AzEventHubKey -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName  -EventHubName $eventHubName -AuthorizationRuleName $authRuleName
	$ehConnectionString = $keys.PrimaryConnectionString

	
	$properties = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSIotHubInputProperties
	$routingProperties = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingProperties
	$routingEndpoints = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingEndpoints
	$routingEndpoints.EventHubs = New-Object 'System.Collections.Generic.List[Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingEventHubProperties]'
	$eventHubRouting = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingEventHubProperties
	$eventHubRouting.Name = "eh1"
	$eventHubRouting.ConnectionString = $ehConnectionString
	$routingEndpoints.EventHubs.Add($eventHubRouting)
	$routingProperties.Endpoints = $routingEndpoints

	$routeProp = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata
	$routeProp.Name = "route"
	$routeProp.Condition = "true"
	$routeProp.IsEnabled = 1
	$routeProp.EndpointNames = New-Object 'System.Collections.Generic.List[String]'
	$routeProp.EndpointNames.Add("eh1")
	$routeProp.Source = "DeviceMessages"
	$routingProperties.Routes = New-Object 'System.Collections.Generic.List[Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata]'
	$routingProperties.Routes.Add($routeProp)
	$properties.Routing = $routingProperties
	$newIothub1 = New-AzIotHub -Name $IotHubName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName $Sku -Units 1 -Properties $properties

	
	$allIotHubsInResourceGroup =  Get-AzIotHub -ResourceGroupName $ResourceGroupName 
	
	
	$iotHub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName 

	Assert-True { $allIotHubsInResourceGroup.Count -eq 1 }
	Assert-True { $iotHub.Name -eq $IotHubName }
	Assert-True { $iotHub.Resourcegroup -eq $ResourceGroupName }
	Assert-True { $iotHub.Subscriptionid -eq $SubscriptionId }
	Assert-True { $iotHub.Properties.Routing.Routes.Count -eq 1}
    Assert-True { $iotHub.Properties.Routing.Routes[0].Name -eq "route"}
    Assert-True { $iotHub.Properties.Routing.Endpoints.EventHubs[0].Name -eq "eh1"}

	
	$quotaMetrics = Get-AzIotHubQuotaMetric -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $quotaMetrics.Count -eq 2 }

	
	$registryStats = Get-AzIotHubRegistryStatistic -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $registryStats.TotalDeviceCount -eq 0 }
	Assert-True { $registryStats.EnabledDeviceCount -eq 0 }
	Assert-True { $registryStats.DisabledDeviceCount -eq 0 }

	
	$validSkus = Get-AzIotHubValidSku -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $validSkus.Count -gt 1 }

	
	$eventubConsumerGroup = Get-AzIotHubEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $eventubConsumerGroup.Count -eq 1 }

	
	$keys = Get-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	Assert-True { $keys.Count -eq 5 }

	
	$key = Get-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner
	Assert-True { $key.KeyName -eq "iothubowner" }

	
	$connectionstrings = Get-AzIotHubConnectionString -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $connectionstrings.Count -eq 5 }

	
	$connectionstring = Get-AzIotHubConnectionString -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner
	Assert-True { $key.KeyName -eq "iothubowner" }

	
	Add-AzIotHubEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -Name $IotHubName -EventHubConsumerGroupName cg1

	
	$eventubConsumerGroup = Get-AzIotHubEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	Assert-True { $eventubConsumerGroup.Count -eq 2 }

	
	Remove-AzIotHubEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -Name $IotHubName -EventHubConsumerGroupName cg1

	
	$eventubConsumerGroup = Get-AzIotHubEventHubConsumerGroup -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $eventubConsumerGroup.Count -eq 1 }

	
	Add-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner1 -Rights RegistryRead

	
	$keys = Get-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	Assert-True { $keys.Count -eq 6 }

	
	$newkey = Get-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner1
	
	
	$swappedKey = New-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner1 -RenewKey Swap
	Assert-True { $swappedKey.PrimaryKey -eq $newkey.SecondaryKey }
	Assert-True { $swappedKey.SecondaryKey -eq $newkey.PrimaryKey }

	
	$regeneratedKey = New-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner1 -RenewKey Primary
	Assert-True { $regeneratedKey.PrimaryKey -ne $swappedKey.PrimaryKey }

	
	Remove-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName -KeyName iothubowner1

	
	$keys = Get-AzIotHubKey -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	Assert-True { $keys.Count -eq 5 }

	
	$iothub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	$iothubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -SkuName S1 -Units 5
	Assert-True { $iothubUpdated.Sku.Capacity -eq 5 }

	
	$iothubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -EventHubRetentionTimeInDays 5
	Assert-True { $iothubUpdated.Properties.EventHubEndpoints.events.RetentionTimeInDays -eq 5 }

	
	$cloudToDevice = $iothubUpdated.Properties.CloudToDevice
	$cloudToDevice.MaxDeliveryCount = 25
	$iotHubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -CloudToDevice $cloudToDevice
	Assert-True { $iothubUpdated.Properties.CloudToDevice.MaxDeliveryCount -eq 25 }

	
	$routingProperties = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingProperties
	$routeProp = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata
	$routeProp.Name = "route1"
	$routeProp.Condition = "true"
	$routeProp.IsEnabled = 1
	$routeProp.EndpointNames = New-Object 'System.Collections.Generic.List[String]'
	$routeProp.EndpointNames.Add("events")
	$routeProp.Source = "DeviceMessages"
	$routingProperties.Routes = New-Object 'System.Collections.Generic.List[Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata]'
	$routingProperties.Routes.Add($routeProp)
	$iotHubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -RoutingProperties $routingProperties
    Assert-True { $iotHubUpdated.Properties.Routing.Routes.Count -eq 1}
    Assert-True { $iotHubUpdated.Properties.Routing.Routes[0].Name -eq "route1"}

	
	$routeProp1 = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata
	$routeProp1.Name = "route2"
	$routeProp1.Condition = "true"
	$routeProp1.IsEnabled = 1
	$routeProp1.EndpointNames = New-Object 'System.Collections.Generic.List[String]'
	$routeProp1.EndpointNames.Add("events")
	$routeProp1.Source = "DeviceMessages"

	$routeProp2 = New-Object Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata
	$routeProp2.Name = "route3"
	$routeProp2.Condition = "true"
	$routeProp2.IsEnabled = 1
	$routeProp2.EndpointNames = New-Object 'System.Collections.Generic.List[String]'
	$routeProp2.EndpointNames.Add("events")
	$routeProp2.Source = "DeviceMessages"

	$routes = New-Object 'System.Collections.Generic.List[Microsoft.Azure.Commands.Management.IotHub.Models.PSRouteMetadata]'
	$routes.Add($routeProp1)
	$routes.Add($routeProp2)
	$iotHubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -Routes $routes	
    Assert-True { $iotHubUpdated.Properties.Routing.Routes.Count -eq 2}
    Assert-True { $iotHubUpdated.Properties.Routing.Routes[0].Name -eq "route2"}
	Assert-True { $iotHubUpdated.Properties.Routing.FallbackRoute.IsEnabled -eq 0}

	$iothub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName 
	$iothub.Properties.Routing.FallbackRoute.IsEnabled = 1
	$iotHubUpdated = Set-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -FallbackRoute $iothub.Properties.Routing.FallbackRoute	
    Assert-True { $iotHubUpdated.Properties.Routing.FallbackRoute.IsEnabled -eq 1}

	
	$tags = @{}
	$tags.Add($Tag1Key, $Tag1Value)
	$updatedIotHub = Update-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -Tag $tags
	Assert-True { $updatedIotHub.Tags.Count -eq 1 }
	Assert-True { $updatedIotHub.Tags.Item($Tag1Key) -eq $Tag1Value }

	
	$tags.Clear()
	$tags.Add($Tag2Key, $Tag2Value)
	$updatedIotHub = Update-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -Tag $tags
	Assert-True { $updatedIotHub.Tags.Count -eq 2 }
	Assert-True { $updatedIotHub.Tags.Item($Tag1Key) -eq $Tag1Value }
	Assert-True { $updatedIotHub.Tags.Item($Tag2Key) -eq $Tag2Value }

	
	$tags.Clear()
	$tags.Add($Tag1Key, $Tag1Value)
	$updatedIotHub = Update-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName -Tag $tags -Reset
	Assert-True { $updatedIotHub.Tags.Count -eq 1 }
	Assert-True { $updatedIotHub.Tags.Item($Tag1Key) -eq $Tag1Value }

	
	$beforeMFIotHub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Invoke-AzIotHubManualFailover -ResourceGroupName $ResourceGroupName -Name $IotHubName
	$afterMFIotHub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $beforeMFIotHub.Properties.Locations[0].Location -eq $afterMFIotHub.Properties.Locations[1].Location}
	Assert-True { $beforeMFIotHub.Properties.Locations[1].Location -eq $afterMFIotHub.Properties.Locations[0].Location}

	
	Remove-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName
}

function Test-AzureRmIotHubCertificateLifecycle
{
	$Location = Get-Location "Microsoft.Devices" "IotHub" 
	$IotHubName = getAssetName 
	$ResourceGroupName = getAssetName 
	$Sku = "S1"

	$TestOutputRoot = [System.AppDomain]::CurrentDomain.BaseDirectory;

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	
	$newIothub1 = New-AzIotHub -Name $IotHubName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName $Sku -Units 1 

	
	$iotHub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName 

	Assert-True { $iotHub.Name -eq $IotHubName }

	
	$certificatePath = "$TestOutputRoot\rootCertificate.cer"
	$verifyCertificatePath = "$TestOutputRoot\verifyCertificate.cer"
	$certificateSubject = "TestCertificate"
	$certificateType = "Microsoft.Devices/IotHubs/Certificates"
	$certificateName = "Certificate1"

	
	New-CARootCert $certificateSubject $certificatePath
	$newCertificate = Add-AzIotHubCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName -CertificateName $certificateName -Path $certificatePath
	Assert-True { $newCertificate.Properties.Subject -eq $certificateSubject }
	Assert-False { $newCertificate.Properties.IsVerified }
	Assert-True { $newCertificate.Type -eq $certificateType }
	Assert-True { $newCertificate.CertificateName -eq $certificateName }

	
	$certificates = Get-AzIotHubCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $certificates.Count -gt 0}

	
	$certificate = Get-AzIotHubCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName -CertificateName $certificateName
	Assert-True { $certificate.Properties.Subject -eq $certificateSubject }
	Assert-False { $certificate.Properties.IsVerified }
	Assert-True { $certificate.Type -eq $certificateType }
	Assert-True { $certificate.CertificateName -eq $certificateName }

	
	$certificateWithNonce = Get-AzIotHubCertificateVerificationCode -ResourceGroupName $ResourceGroupName -Name $IotHubName -CertificateName $certificateName -Etag $certificate.Etag
	Assert-True { $certificateWithNonce.Properties.Subject -eq $certificateSubject }
	Assert-NotNull { $certificateWithNonce.Properties.VerificationCode }

	
	New-CAVerificationCert $certificateWithNonce.Properties.VerificationCode $certificateSubject $verifyCertificatePath
	$verifiedCertificate = Set-AzIotHubVerifiedCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName -CertificateName $certificateName -Path $verifyCertificatePath  -Etag $certificateWithNonce.Etag
	Assert-True { $verifiedCertificate.Properties.Subject -eq $certificateSubject }
	Assert-True { $verifiedCertificate.Properties.IsVerified }
	Assert-True { $verifiedCertificate.Type -eq $certificateType }
	Assert-True { $verifiedCertificate.CertificateName -eq $certificateName }

	
	Remove-AzIotHubCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName -CertificateName $certificateName -Etag $verifiedCertificate.Etag

	
	$afterRemoveCertificates = Get-AzIotHubCertificate -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $afterRemoveCertificates.Count -eq 0}

	
	Remove-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName

	
	Remove-AzResourceGroup -Name $ResourceGroupName -force
}


function Get-CACertBySubjectName([string]$subjectName)
{
	$cnsubjectName = ("CN={0}" -f $subjectName)
    $certificates = gci -Recurse Cert:\LocalMachine\ |? { $_.gettype().name -eq "X509Certificate2" }
    $cert = $certificates |? { $_.subject -eq $cnsubjectName -and $_.PSParentPath -eq "Microsoft.PowerShell.Security\Certificate::LocalMachine\My" }
    if ($NULL -eq $cert)
    {
        throw ("Unable to find certificate with subjectName {0}" -f $subjectName)
    }

    write $cert[0]
}


function New-CASelfsignedCertificate([string]$subjectName, [object]$signingCert, [bool]$isASigner=$true)
{
	
	$selfSignedArgs = @{"-DnsName"=$subjectName; 
		                "-CertStoreLocation"="cert:\LocalMachine\My";
	                    "-NotAfter"=(get-date).AddDays(30); 
						}

	if ($isASigner -eq $true)
	{
		$selfSignedArgs += @{"-KeyUsage"="CertSign"; }
		$selfSignedArgs += @{"-TextExtension"= @(("2.5.29.19={text}ca=TRUE&pathlength=12")); }
	}
	else
	{
		$selfSignedArgs += @{"-TextExtension"= @("2.5.29.37={text}1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1", "2.5.29.19={text}ca=FALSE&pathlength=0")  }
	}

	if ($signingCert -ne $null)
	{
		$selfSignedArgs += @{"-Signer"=$signingCert }
	}

	if ($useEcc -eq $true)
	{
		$selfSignedArgs += @{"-KeyAlgorithm"="ECDSA_nistP256";
                      "-CurveExport"="CurveName" }
	}

	write (New-SelfSignedCertificate @selfSignedArgs)
}


function New-CARootCert([string]$subjectName, [string]$requestedFileName)
{
	$certificate = New-CASelfsignedCertificate $subjectName 
	Export-Certificate -cert $certificate -filePath $requestedFileName -Type Cert
	if (-not (Test-Path $requestedFileName))
    {
        throw ("Error: CERT file {0} doesn't exist" -f $requestedFileName)
    }
}


function New-CAVerificationCert([string]$requestedSubjectName, [string]$_rootCertSubject, [string]$verifyRequestedFileName)
{
    $rootCACert = Get-CACertBySubjectName $_rootCertSubject
	$verifyCert = New-CASelfsignedCertificate $requestedSubjectName $rootCACert $false
	Export-Certificate -cert $verifyCert -filePath $verifyRequestedFileName -Type Cert
    if (-not (Test-Path $verifyRequestedFileName))
    {
        throw ("Error: CERT file {0} doesn't exist" -f $verifyRequestedFileName)
    }

	
	Get-ChildItem ("Cert:\LocalMachine\My\{0}" -f $rootCACert.Thumbprint) | Remove-Item
	Get-ChildItem ("Cert:\LocalMachine\My\{0}" -f $verifyCert.Thumbprint) | Remove-Item
}