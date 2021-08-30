


function Remove-RsRestCatalogItem
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
    }
    Process
    {
        if ($RsItem -eq '/')
        {
            throw "Root folder cannot be deleted!"
        }

        if ($PSCmdlet.ShouldProcess($RsItem, "Delete the item"))
        {
            try
            {
                Write-Verbose "Deleting item $RsItem..."
                $catalogItemsUri = [String]::Format($catalogItemsUri, $RsItem)
    
                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Delete -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
                }
    
                Write-Verbose "Catalog item $RsItem was deleted successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to delete catalog item '$RsItem': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}