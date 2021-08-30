



function Set-RsDataSourcePassword
{
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $Password,
        
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
            if ($PSCmdlet.ShouldProcess($item, "Overwrite the password"))
            {
                try
                {
                    $dataSourceContent = $Proxy.GetDataSourceContents($item)
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to retrieve Datasource content: $($_.Exception.Message)", $_.Exception))
                }
                $dataSourceContent.Password = $Password
                Write-Verbose "Setting password of datasource $item"
                try
                {
                    $Proxy.SetDataSourceContents($item, $dataSourceContent)
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to update Datasource content: $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}

