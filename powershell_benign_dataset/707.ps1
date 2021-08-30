


function Remove-RsRestFolder
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

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
        $foldersUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')"
    }
    Process
    {
        if ($RsFolder -eq '/')
        {
            throw "Root folder cannot be deleted!"
        }

        if ($PSCmdlet.ShouldProcess($RsFolder, "Delete the folder"))
        {
            try
            {
                Write-Verbose "Deleting folder $RsFolder..."
                $foldersUri = [String]::Format($foldersUri, $RsFolder)

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -Credential $Credential -UseBasicParsing -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -UseBasicParsing -Verbose:$false | Out-Null
                }

                Write-Verbose "Folder $RsFolder was deleted successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to delete folder '$RsFolder': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}