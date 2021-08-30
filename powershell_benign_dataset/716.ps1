


function New-RsRestFolder
{
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True)]
        [Alias('Name')]
        [string]
        $FolderName,

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
        $foldersUri = $ReportPortalUri + "api/$RestApiVersion/Folders"
    }
    Process
    {
        try
        {
            if ($RsFolder -eq '/')
            {
                $TargetFolderPath = "/$FolderName"
            }
            else
            {
                $TargetFolderPath = "$RsFolder/$FolderName"
            }
            Write-Verbose "Creating folder $TargetFolderPath..."

            $payload = @{
                "@odata.type" = "
                "Path" = $RsFolder;
                "Name" = $FolderName;
            }
            $payloadJson = ConvertTo-Json $payload

            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $foldersUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $foldersUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false
            }

            Write-Verbose "Folder $TargetFolderPath was created successfully!"
            return ConvertFrom-Json $response.Content
        }
        catch
        {
            throw (New-Object System.Exception("Failed to create folder '$FolderName' in '$RsFolder': $($_.Exception.Message)", $_.Exception))
        }
    }
}