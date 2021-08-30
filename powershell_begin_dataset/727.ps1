



function Set-RsDataSetReference
{
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetName,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSetPath,
        
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
        foreach ($item in $Path)
        {
            
            if ($PSCmdlet.ShouldProcess($item, "Set datasource's DataSet $DataSetName to $DataSetPath"))
            {
                Write-Verbose "Processing: $item"
                
                try
                {
                    $dataSets = $Proxy.GetItemReferences($item, "DataSet")
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to retrieve item references from Report Server for '$item': $($_.Exception.Message)", $_.Exception))
                }
                $dataSetReference = $dataSets | Where-Object { $_.Name -eq $DataSetName } | Select-Object -First 1
                
                if (-not $dataSetReference)
                {
                    throw "$item does not contain a dataSet reference with name $DataSetName"
                }
                
                $proxyNamespace = $dataSetReference.GetType().Namespace
                $dataSetReference = New-Object "$($proxyNamespace).ItemReference"
                $dataSetReference.Name = $DataSetName
                $dataSetReference.Reference = $DataSetPath
                
                Write-Verbose "Set dataSet reference '$DataSetName' of item $item to $DataSetPath"
                $Proxy.SetItemReferences($item, @($dataSetReference))
            }
            
        }
    }
}

New-Alias -Name Set-RsDataSet -Value Set-RsDataSetReference -Scope Global