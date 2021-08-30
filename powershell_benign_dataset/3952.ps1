














function Test-ListAzureFirewallFqdnTag
{
    
    $alwaysPresentTag = "WindowsUpdate"

    
    $availableFqdnTags = Get-AzFirewallFqdnTag

    
    
    Assert-True { $availableFqdnTags.Count -gt 0 }

    
    Assert-AreEqual 1 $availableFqdnTags.Where({$_.FqdnTagName -eq $alwaysPresentTag}).Count
}
