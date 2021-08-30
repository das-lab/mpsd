

$global:gPsAutoTestADAppId = 'b8a1058e-25e8-4b08-b40b-d8d871dda591'
$global:gPsAutoTestSubscriptionName = 'Node CLI Test'
$global:gPsAutoTestSubscriptionId = '2c224e7e-3ef5-431d-a57b-e71f4662e3a6'

$global:gTenantId = '72f988bf-86f1-41af-91ab-2d7cd011db47'
$global:gLocalCertSubjectName = 'CN=PsAutoTestCert, OU=MicrosoftAzurePsTeam'
$global:gPfxLocalFileName = "PsAutoTestCert.pfx"
$global:gpubSettingLocalFileName = "NodeCLITest.publishsettings"

$global:gVaultName = 'KV-PsSdkAuto'
$global:gPsAutoResGrpName = 'AzurePsSdkAuto'

$global:gLocalCertStore = 'Cert:\CurrentUser\My'
$global:gCertPwd = ''
$global:gLoggedInCtx = $null
$global:localPfxDirPath = [Environment]::GetEnvironmentVariable("TEMP")


$global:kvSecKey_PsAutoTestCertNameKey = 'PsAutoTestCertName'
$global:gPsAutoTestADAppUsingSPNKey = 'PsAutoTestADAppUsingSPN'
$global:gkvSecKey_PubSettingFileNameKey = 'NodeCliTestPubSetFile'
$global:gKVKey_ADAppIdKey = "PsAutoTestAppUsingCertAppId"


Function Check-LoggedInContext()
{
    if($gLoggedInCtx -eq $null)
    {
        Write-Error "'$global:gPsAutoTestSubscriptionName' subscription does not exist in the list of available subscriptions. Make sure to have it to run the tests"
        Exit
    }
}

Function Get-AutomationTestCertificate()
{
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate])]
    Param ($cert)

    if($gLoggedInCtx -ne $null)
    {
        
        $downloadedCertPath = Download-TestCertificateFromKeyVault

        
        Install-TestCertificateOnMachine $downloadedCertPath

        
        $cert = Get-LocalCertificate
        if($cert -eq $null)
        {
            throw [System.ApplicationException] "Unable to retrieve Automation Test Certificate '$gLocalCertSubjectName'"
        }
    }
    return $cert
}

Function Get-LocalCertificate()
{
    
    $cert = Get-ChildItem $gLocalCertStore | Where-Object {$_.Subject -eq $Global:gLocalCertSubjectName}
    if($cert -eq $null)
    {
        Log-Info "Trying to find certificate in LocalMachine"
        $cert = Get-ChildItem 'Cert:\LocalMachine\My' | Where-Object {$_.Subject -eq $Global:gLocalCertSubjectName}
    }

    return $cert
}

Function Download-PublishSettingsFileFromKv([string] $localFilePathToDownload)
{
    $dirPath = [System.IO.Path]::GetDirectoryName($localFilePathToDownload)
    $pubFileSecContents = Get-AzureKeyVaultSecret -VaultName $global:gVaultName -Name $global:gkvSecKey_PubSettingFileNameKey
    Log-Info "Ready to download Publishsettings file to '$localFilePathToDownload' from Azure KeyVault"
    
    if([System.IO.Directory]::Exists($dirPath) -eq $true)
    {
        [System.IO.File]::WriteAllText($localFilePathToDownload, $pubFileSecContents.SecretValueText)
    }
    else
    {
        throw [System.IO.DirectoryNotFoundException] "$dirPath does not exists"
    }
    
    Log-Info "Successfully downloaded Publishsettings file to '$localFilePathToDownload'"
}

Function Install-TestCertificateOnMachine([string] $localCertPath)
{
    
    if([System.IO.File]::Exists($localCertPath) -ne $true)
    {
        $localCertPath = Download-TestCertificateFromKeyVault
    }

    $pwd = Get-LocalCertificatePassword
    $secCertPwd = ConvertTo-SecureString -String $pwd -AsPlainText -Force

    Log-Info "Ready to install certificate to '$global:gLocalCertStore'"
    Import-PfxCertificate -FilePath $localCertPath -CertStoreLocation $gLocalCertStore -Password $secCertPwd

    $installedCert = Get-LocalCertificate
    if($installedCert -eq $null)
    {
        throw [System.ApplicationException] "Unable to retrieve installed certificate for running automation test"
    }
    else
    {
        Log-Info "Successfully installed certificate to '$global:gLocalCertStore'"
    }
}

Function Download-TestCertificateFromKeyVault()
{

    Check-LoggedInContext
    $kvCertSecret = Get-AzureKeyVaultSecret -VaultName $global:gVaultName -Name $global:kvSecKey_PsAutoTestCertNameKey

    
    
    
    
    
    
    
    
    if($kvCertSecret -ne $null)
    {
        $kvSecretBytes = [System.Convert]::FromBase64String($kvCertSecret.SecretValueText)
        $certCollection2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
        $certCollection2.Import($kvSecretBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        
        
        $pwd = Get-LocalCertificatePassword
        $certPwdProtectedInBytes = $certCollection2.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $pwd)
        $pfxLocalFilePath = [System.IO.Path]::Combine($global:localPfxDirPath, $global:gPfxLocalFileName)
        [System.IO.File]::WriteAllBytes($pfxLocalFilePath, $certPwdProtectedInBytes)

        
        
        
        
        
        

        Log-Info "Successfully downloaded certificate at '$pfxLocalFilePath'"
    }

    return $pfxLocalFilePath
}

Function Get-LocalCertificatePassword()
{
    if([string]::IsNullOrEmpty($global:gCertPwd) -eq $true)
    {
        $global:gCertPwd = Read-Host "Please enter certificate password that is ready to be installed on your machine"        
    }

    return $global:gCertPwd
}

Function Login-AzureRMWithCertificate([bool]$runOnCIMachine=$false)
{
    $appId = $global:gPsAutoTestADAppId
    
    $localCert = Get-LocalCertificate
    if($localCert -eq $null)
    {
        If($runOnCIMachine -eq $false)
        {
            $global:ErrorActionPreference = "SilentlyContinue" 
            
            Login-InteractivelyAndSelectTestSubscription
            $localCert = Get-AutomationTestCertificate
            
        }
        else
        {
            throw [System.ApplicationException] "Local Certificate missing on machine and 'runOnCIMachine' is passed as $runOnCIMachine"
        }
    }
    
    $thumbprint = $localCert.Thumbprint
    
    $thumbStr = [System.Convert]::ToString($thumbprint.ToString())
        
    
    $gLoggedInCtx = Connect-AzureRmAccount -ServicePrincipal -CertificateThumbprint $thumbStr -ApplicationId $appId -TenantId $global:gTenantId    
    $global:ErrorActionPreference = "Stop" 
}

Function Login-AzureWithCertificate()
{
    $fullPath = [System.IO.Path]::Combine($PSScriptRoot, $global:gpubSettingLocalFileName)

    if([System.IO.File]::Exists($fullPath) -ne $true)
    {
        Download-PublishSettingsFileFromKv $fullPath        
    }

    Import-AzurePublishSettingsFile -PublishSettingsFile $fullPath
}

Function Login-InteractivelyAndSelectTestSubscription()
{
    Log-Info "Login interactively....."
    $global:gLoggedInCtx = Connect-AzureRmAccount

    Check-LoggedInContext
    Log-Info "Selecting '$global:gPsAutoTestSubscriptionId' subscription"
    $global:gLoggedInCtx = Select-AzureRmSubscription -SubscriptionId $global:gPsAutoTestSubscriptionId

    return $global:gLoggedInCtx
}

Function Login-Azure([bool]$deleteLocalCertificate=$false, [bool]$runOnCIMachine=$false)
{
    try
    {
        Remove-AllSubscriptions

        if($deleteLocalCertificate -eq $true)
        {
            Delete-LocalCertificate
        }

        Login-AzureRMWithCertificate $runOnCIMachine
        Select-AzureRmSubscription -SubscriptionId $global:gPsAutoTestSubscriptionId -TenantId $global:gTenantId

        Login-AzureWithCertificate
        Select-AzureSubscription -SubscriptionId $global:gPsAutoTestSubscriptionId -Current
    }
    finally
    {
        Delete-DownloadedCertAndPubSetting
    }
}

Function Log-Info([string] $info)
{
    $info = [string]::Format("[INFO]: {0}", $info)
    Write-Host $info -ForegroundColor Yellow
}

Function Log-Error([string] $errorInfo)
{
    $errorInfo = [string]::Format("[INFO]: {0}", $errorInfo)
    Write-Error -Message $errorInfo
}

Function Delete-LocalCertificate()
{
    $cert = Get-LocalCertificate
    if($cert -ne $null)
    {
        $certPath = $cert.PSPath
        Log-Info "Deleting local certificate $certPath"
        Remove-Item $cert.PSPath
    }
}

Function Delete-DownloadedCertAndPubSetting
{
    $pfxFilePath = [System.IO.Path]::Combine($global:localPfxDirPath,$global:gPfxLocalFileName)
    if([System.IO.File]::Exists($pfxFilePath) -eq $true)
    {
        
        Remove-Item $pfxFilePath
    }

    $pubSettingFile = [System.IO.Path]::Combine($PSScriptRoot,$global:gpubSettingLocalFileName)
    if([System.IO.File]::Exists($pubSettingFile) -eq $true)
    {
        
        Remove-Item $pubSettingFile
    }
}