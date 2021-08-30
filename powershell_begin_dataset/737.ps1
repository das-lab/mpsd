



function Get-RsItemReference
{
    
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        
        foreach ($Item in $Path)
        {
            $itemType = $Proxy.GetItemType($Item)
            
            switch ($itemType)
            {
                "Report"
                {
                    return ($Proxy.GetItemReferences($Item, "DataSet") + $Proxy.GetItemReferences($Item, "DataSource")) | Add-Member -Name "ItemType" -Value $itemType -MemberType NoteProperty -PassThru
                }
                "DataSet"
                {
                    return $Proxy.GetItemReferences($Item, "DataSource") | Add-Member -Name "ItemType" -Value $itemType -MemberType NoteProperty -PassThru
                }
                "Unknown"
                {
                    throw "Cannot find item with path $Item"
                }
                default
                {
                    throw "ItemType '$itemType' is not supported by this method."
                }
            }
        }
        
    }
}
New-Alias -Name "Get-RsItemReferences" -Value Get-RsItemReference -Scope Global
