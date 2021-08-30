


function Set-RsEmailSettings
{
    
    
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [Microsoft.ReportingServicesTools.SmtpAuthentication]
        $Authentication = "Ntlm",
        
        [Parameter(Mandatory = $True)]
        [string]
        $SmtpServer,
        
        [Parameter(Mandatory = $True)]
        [string]
        $SenderAddress,
        
        [Alias('EmailCredentials')]
        [System.Management.Automation.PSCredential]
        $EmailCredential,
        
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
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    
    if (-not $PSBoundParameters.ContainsKey("Authentication"))
    {
        $CallName = (Get-PSCallStack)[0].InvocationInfo.InvocationName
        
        if ($CallName -eq "Set-RsEmailSettingsAsNoAuth")
        {
            $Authentication = "None"
        }
        if ($CallName -eq "Set-RsEmailSettingsAsBasicAuth")
        {
            $Authentication = "Basic"
        }
        if ($CallName -eq "Set-RsEmailSettingsAsNTLMAuth")
        {
            $Authentication = "Ntlm"
        }
    }
    
    
    if (($Authentication -like "Basic") -and (-not $EmailCredential))
    {
        throw (New-Object System.Management.Automation.PSArgumentException("Basic authentication requires passing credentials using the 'EmailCredential' parameter!"))
    }
    
    
    $UserName = ''
    $Password = ''
    
    if ($Authentication -like "Basic")
    {
        $UserName = $EmailCredential.UserName
        $Password = $EmailCredential.GetNetworkCredential().Password
    }
    
    
    try
    {
        $result = $rsWmiObject.SetAuthenticatedEmailConfiguration($true, $SmtpServer, $SenderAddress, $UserName, $Password, $Authentication.Value__, $true)
    }
    catch
    {
        throw (New-Object System.Exception("Failed to update email settings: $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to update email settings. Errocode: $($result.HRESULT)"
    }
}


New-Alias -Name "Set-RsEmailSettingsAsNTLMAuth" -Value Set-RsEmailSettings -Scope Global
New-Alias -Name "Set-RsEmailSettingsAsNoAuth" -Value Set-RsEmailSettings -Scope Global
New-Alias -Name "Set-RsEmailSettingsAsBasicAuth" -Value Set-RsEmailSettings -Scope Global
