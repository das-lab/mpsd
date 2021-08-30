














function Test-DnsAvailability
{
    
    $domainQualifiedName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/publicIPAddresses"
    $location = Get-ProviderLocation $resourceTypeParent

    
    $checkdnsavailability = Test-AzDnsAvailability -Location "westus" -DomainQualifiedName $domainQualifiedName
    Assert-AreEqual $checkdnsavailability true    
}