


function Backup-RsEncryptionKey
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $Password,
        
        [Parameter(Mandatory = $True)]
        [string]
        $KeyPath,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
    )
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Retrieve encryption key and create backup in $KeyPath"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
        
        Write-Verbose "Retrieving encryption key..."
        $encryptionKeyResult = $rsWmiObject.BackupEncryptionKey($Password)
        
        if ($encryptionKeyResult.HRESULT -eq 0)
        {
            Write-Verbose "Retrieving encryption key... Success!"
        }
        else
        {
            throw "Failed to create backup of the encryption key. Errors: $($encryptionKeyResult.ExtendedErrors)"
        }
        
        try
        {
            Write-Verbose "Writing key to file..."
            [System.IO.File]::WriteAllBytes($KeyPath, $encryptionKeyResult.KeyFile)
            Write-Verbose "Writing key to file... Success!"
        }
        catch
        {
            throw
        }
    }
}
