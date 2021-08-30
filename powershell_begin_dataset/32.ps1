




function Get-AuthToken {



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }




    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

$resourceAppIdURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$Tenant"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    
    

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        

        if($authResult.AccessToken){

        

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}
 


function CloneObject($object){

	$stream = New-Object IO.MemoryStream;
	$formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter;
	$formatter.Serialize($stream, $object);
	$stream.Position = 0;
	$formatter.Deserialize($stream);
}



function WriteHeaders($authToken){

	foreach ($header in $authToken.GetEnumerator())
	{
		if ($header.Name.ToLower() -eq "authorization")
		{
			continue;
		}

		Write-Host -ForegroundColor Gray "$($header.Name): $($header.Value)";
	}
}



function MakeGetRequest($collectionPath){

	$uri = "$baseUrl$collectionPath";
	$request = "GET $uri";
	
	if ($logRequestUris) { Write-Host $request; }
	if ($logHeaders) { WriteHeaders $authToken; }

	try
	{
		$response = Invoke-RestMethod $uri -Method Get -Headers $authToken;
		$response;
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}
}



function MakePatchRequest($collectionPath, $body){

	MakeRequest "PATCH" $collectionPath $body;

}



function MakePostRequest($collectionPath, $body){

	MakeRequest "POST" $collectionPath $body;

}



function MakeRequest($verb, $collectionPath, $body){

	$uri = "$baseUrl$collectionPath";
	$request = "$verb $uri";
	
	$clonedHeaders = CloneObject $authToken;
	$clonedHeaders["content-length"] = $body.Length;
	$clonedHeaders["content-type"] = "application/json";

	if ($logRequestUris) { Write-Host $request; }
	if ($logHeaders) { WriteHeaders $clonedHeaders; }
	if ($logContent) { Write-Host -ForegroundColor Gray $body; }

	try
	{
		$response = Invoke-RestMethod $uri -Method $verb -Headers $clonedHeaders -Body $body;
		$response;
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}
}



function UploadAzureStorageChunk($sasUri, $id, $body){

	$uri = "$sasUri&comp=block&blockid=$id";
	$request = "PUT $uri";

	$iso = [System.Text.Encoding]::GetEncoding("iso-8859-1");
	$encodedBody = $iso.GetString($body);
	$headers = @{
		"x-ms-blob-type" = "BlockBlob"
	};

	if ($logRequestUris) { Write-Host $request; }
	if ($logHeaders) { WriteHeaders $headers; }

	try
	{
		$response = Invoke-WebRequest $uri -Method Put -Headers $headers -Body $encodedBody;
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}

}



function FinalizeAzureStorageUpload($sasUri, $ids){

	$uri = "$sasUri&comp=blocklist";
	$request = "PUT $uri";

	$xml = '<?xml version="1.0" encoding="utf-8"?><BlockList>';
	foreach ($id in $ids)
	{
		$xml += "<Latest>$id</Latest>";
	}
	$xml += '</BlockList>';

	if ($logRequestUris) { Write-Host $request; }
	if ($logContent) { Write-Host -ForegroundColor Gray $xml; }

	try
	{
		Invoke-RestMethod $uri -Method Put -Body $xml;
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}
}



function UploadFileToAzureStorage($sasUri, $filepath){

	
    $chunkSizeInBytes = 1024 * 1024;

	
	
    
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($filepath);
	$chunks = [Math]::Ceiling($bytes.Length / $chunkSizeInBytes);

	
	$ids = @();
    $cc = 1

	for ($chunk = 0; $chunk -lt $chunks; $chunk++)
	{
        $id = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($chunk.ToString("0000")));
		$ids += $id;

		$start = $chunk * $chunkSizeInBytes;
		$end = [Math]::Min($start + $chunkSizeInBytes - 1, $bytes.Length - 1);
		$body = $bytes[$start..$end];

        Write-Progress -Activity "Uploading File to Azure Storage" -status "Uploading chunk $cc of $chunks" `
        -percentComplete ($cc / $chunks*100)
        $cc++

        $uploadResponse = UploadAzureStorageChunk $sasUri $id $body;


	}

    Write-Progress -Completed -Activity "Uploading File to Azure Storage"

    Write-Host

	
	$uploadResponse = FinalizeAzureStorageUpload $sasUri $ids;
}



function GenerateKey{

	try
	{
		$aes = [System.Security.Cryptography.Aes]::Create();
        $aesProvider = New-Object System.Security.Cryptography.AesCryptoServiceProvider;
        $aesProvider.GenerateKey();
        $aesProvider.Key;
	}
	finally
	{
		if ($aesProvider -ne $null) { $aesProvider.Dispose(); }
		if ($aes -ne $null) { $aes.Dispose(); }
	}
}



function GenerateIV{

	try
	{
		$aes = [System.Security.Cryptography.Aes]::Create();
        $aes.IV;
	}
	finally
	{
		if ($aes -ne $null) { $aes.Dispose(); }
	}
}



function EncryptFileWithIV($sourceFile, $targetFile, $encryptionKey, $hmacKey, $initializationVector){

	$bufferBlockSize = 1024 * 4;
	$computedMac = $null;

	try
	{
		$aes = [System.Security.Cryptography.Aes]::Create();
		$hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256;
		$hmacSha256.Key = $hmacKey;
		$hmacLength = $hmacSha256.HashSize / 8;

		$buffer = New-Object byte[] $bufferBlockSize;
		$bytesRead = 0;

		$targetStream = [System.IO.File]::Open($targetFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read);
		$targetStream.Write($buffer, 0, $hmacLength + $initializationVector.Length);

		try
		{
			$encryptor = $aes.CreateEncryptor($encryptionKey, $initializationVector);
			$sourceStream = [System.IO.File]::Open($sourceFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read);
			$cryptoStream = New-Object System.Security.Cryptography.CryptoStream -ArgumentList @($targetStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write);

			$targetStream = $null;
			while (($bytesRead = $sourceStream.Read($buffer, 0, $bufferBlockSize)) -gt 0)
			{
				$cryptoStream.Write($buffer, 0, $bytesRead);
				$cryptoStream.Flush();
			}
			$cryptoStream.FlushFinalBlock();
		}
		finally
		{
			if ($cryptoStream -ne $null) { $cryptoStream.Dispose(); }
			if ($sourceStream -ne $null) { $sourceStream.Dispose(); }
			if ($encryptor -ne $null) { $encryptor.Dispose(); }	
		}

		try
		{
			$finalStream = [System.IO.File]::Open($targetFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)

			$finalStream.Seek($hmacLength, [System.IO.SeekOrigin]::Begin) > $null;
			$finalStream.Write($initializationVector, 0, $initializationVector.Length);
			$finalStream.Seek($hmacLength, [System.IO.SeekOrigin]::Begin) > $null;

			$hmac = $hmacSha256.ComputeHash($finalStream);
			$computedMac = $hmac;

			$finalStream.Seek(0, [System.IO.SeekOrigin]::Begin) > $null;
			$finalStream.Write($hmac, 0, $hmac.Length);
		}
		finally
		{
			if ($finalStream -ne $null) { $finalStream.Dispose(); }
		}
	}
	finally
	{
		if ($targetStream -ne $null) { $targetStream.Dispose(); }
        if ($aes -ne $null) { $aes.Dispose(); }
	}

	$computedMac;
}



function EncryptFile($sourceFile, $targetFile){

	$encryptionKey = GenerateKey;
	$hmacKey = GenerateKey;
	$initializationVector = GenerateIV;

	
	$mac = EncryptFileWithIV $sourceFile $targetFile $encryptionKey $hmacKey $initializationVector;

	
	$fileDigest = (Get-FileHash $sourceFile -Algorithm SHA256).Hash;
	$fileDigestBytes = New-Object byte[] ($fileDigest.Length / 2);
    for ($i = 0; $i -lt $fileDigest.Length; $i += 2)
	{
        $fileDigestBytes[$i / 2] = [System.Convert]::ToByte($fileDigest.Substring($i, 2), 16);
    }
	
	
	$encryptionInfo = @{};
	$encryptionInfo.encryptionKey = [System.Convert]::ToBase64String($encryptionKey);
	$encryptionInfo.macKey = [System.Convert]::ToBase64String($hmacKey);
	$encryptionInfo.initializationVector = [System.Convert]::ToBase64String($initializationVector);
	$encryptionInfo.mac = [System.Convert]::ToBase64String($mac);
	$encryptionInfo.profileIdentifier = "ProfileVersion1";
	$encryptionInfo.fileDigest = [System.Convert]::ToBase64String($fileDigestBytes);
	$encryptionInfo.fileDigestAlgorithm = "SHA256";

	$fileEncryptionInfo = @{};
	$fileEncryptionInfo.fileEncryptionInfo = $encryptionInfo;

	$fileEncryptionInfo;

}



function WaitForFileProcessing($fileUri, $stage){

	$attempts= 60;
	$waitTimeInSeconds = 1;

	$successState = "$($stage)Success";
	$pendingState = "$($stage)Pending";
	$failedState = "$($stage)Failed";
	$timedOutState = "$($stage)TimedOut";

	$file = $null;
	while ($attempts -gt 0)
	{
		$file = MakeGetRequest $fileUri;

		if ($file.uploadState -eq $successState)
		{
			break;
		}
		elseif ($file.uploadState -ne $pendingState)
		{
			throw "File upload state is not success: $($file.uploadState)";
		}

		Start-Sleep $waitTimeInSeconds;
		$attempts--;
	}

	if ($file -eq $null)
	{
		throw "File request did not complete in the allotted time.";
	}

	$file;

}



function GetAndroidAppBody($displayName, $publisher, $description, $filename, $identityName, $identityVersion, $versionName, $minimumSupportedOperatingSystem){

	$body = @{ "@odata.type" = "
	$body.categories = @();
	$body.displayName = $displayName;
	$body.publisher = $publisher;
	$body.description = $description;
	$body.fileName = $filename;
	$body.identityName = $identityName;
	$body.identityVersion = $identityVersion;
	
    if ($minimumSupportedOperatingSystem -eq $null){

		$body.minimumSupportedOperatingSystem = @{ "v4_4" = $true };
	
    }
	
    else {

		$body.minimumSupportedOperatingSystem = $minimumSupportedOperatingSystem;
	
    }

	$body.informationUrl = $null;
	$body.isFeatured = $false;
	$body.privacyInformationUrl = $null;
	$body.developer = "";
	$body.notes = "";
	$body.owner = "";
    $body.versionCode = $identityVersion;
    $body.versionName = $versionName;

	$body;
}



function GetiOSAppBody($displayName, $publisher, $description, $filename, $bundleId, $identityVersion, $versionNumber, $expirationDateTime){

	$body = @{ "@odata.type" = "
    $body.applicableDeviceType = @{ "iPad" = $true; "iPhoneAndIPod" = $true }
	$body.categories = @();
	$body.displayName = $displayName;
	$body.publisher = $publisher;
	$body.description = $description;
	$body.fileName = $filename;
	$body.bundleId = $bundleId;
	$body.identityVersion = $identityVersion;
	if ($minimumSupportedOperatingSystem -eq $null)
	{
		$body.minimumSupportedOperatingSystem = @{ "v9_0" = $true };
	}
	else
	{
		$body.minimumSupportedOperatingSystem = $minimumSupportedOperatingSystem;
	}

	$body.informationUrl = $null;
	$body.isFeatured = $false;
	$body.privacyInformationUrl = $null;
	$body.developer = "";
	$body.notes = "";
	$body.owner = "";
    $body.expirationDateTime = $expirationDateTime;
    $body.versionNumber = $versionNumber;

	$body;
}



function GetMSIAppBody($displayName, $publisher, $description, $filename, $identityVersion, $ProductCode){

	$body = @{ "@odata.type" = "
	$body.displayName = $displayName;
	$body.publisher = $publisher;
	$body.description = $description;
	$body.fileName = $filename;
	$body.identityVersion = $identityVersion;
	$body.informationUrl = $null;
	$body.isFeatured = $false;
	$body.privacyInformationUrl = $null;
	$body.developer = ""; 
	$body.notes = "";
	$body.owner = "";
    $body.productCode = "$ProductCode";
    $body.productVersion = "$identityVersion";

	$body;
}



function GetAppFileBody($name, $size, $sizeEncrypted, $manifest){

	$body = @{ "@odata.type" = "
	$body.name = $name;
	$body.size = $size;
	$body.sizeEncrypted = $sizeEncrypted;
	$body.manifest = $manifest;

	$body;
}



function GetAppCommitBody($contentVersionId, $LobType){

	$body = @{ "@odata.type" = "
	$body.committedContentVersion = $contentVersionId;

	$body;

}



Function Get-MSIFileInformation(){



param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$Path,
 
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion")]
    [string]$Property
)
Process {

    try {
        
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
        $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
        $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
        $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
        $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
        
        $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
        $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
        $MSIDatabase = $null
        $View = $null
 
        
        return $Value
    }

    catch {

        Write-Warning -Message $_.Exception.Message;
        break;
    
    }

}

    End {
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
        [System.GC]::Collect()
    }

}



Function Test-SourceFile(){

param
(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $SourceFile
)

    try {

            if(!(test-path "$SourceFile")){

            Write-Host "Source File '$sourceFile' doesn't exist..." -ForegroundColor Red
            throw

            }

        }

    catch {

		Write-Host -ForegroundColor Red $_.Exception.Message;
        Write-Host
		break;

    }

}



Function Get-ApkInformation {



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $sourceFile,
    [Parameter(Mandatory=$true)]
    $AndroidSDK
)

    if(!(test-path $AndroidSDK)){

    Write-Host
    Write-Host "Android SDK isn't installed..." -ForegroundColor Red
    Write-Host "Please install Android Studio and install the SDK from https://developer.android.com/studio/index.html"
    Write-Host
    break

    }

    if(((gci $AndroidSDK | select name).Name).count -gt 1){

    $BuildTools = ((gci $AndroidSDK | select name).Name | sort -Descending)[0]

    }

    else {

    $BuildTools = ((gci $AndroidSDK | select name).Name)

    }

$aaptPath = "$AndroidSDK\$BuildTools"

[ScriptBlock]$command = {

    cmd.exe /c "$aaptPath\aapt.exe" dump badging "$sourceFile"

}

$aaptRun = Invoke-Command -ScriptBlock $command

$AndroidPackage = $aaptRun | ? { ($_).startswith("package") }

$PackageInfo = $AndroidPackage.split(" ")

$PackageInfo[1].Split("'")[1]
$PackageInfo[2].Split("'")[1]
$PackageInfo[3].Split("'")[1]

if ($logContent) { Write-Host -ForegroundColor Gray $PackageInfo[1].Split("'")[1]; }
if ($logContent) { Write-Host -ForegroundColor Gray $PackageInfo[2].Split("'")[1]; }
if ($logContent) { Write-Host -ForegroundColor Gray $PackageInfo[3].Split("'")[1]; }

}



function Upload-AndroidLob(){



[cmdletbinding()]

param
(
    [parameter(Mandatory=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,

    [parameter(Mandatory=$false)]
    [string]$displayName,

    [parameter(Mandatory=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$publisher,

    [parameter(Mandatory=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]$description,

    [parameter(Mandatory=$false)]
    [string]$identityName,

    [parameter(Mandatory=$false)]
    [string]$identityVersion,

    [parameter(Mandatory=$false)]
    [string]$versionName

)

	try
	{
		
        $LOBType = "microsoft.graph.androidLOBApp"

        Write-Host "Testing if SourceFile '$SourceFile' Path is valid..." -ForegroundColor Yellow
        Test-SourceFile "$SourceFile"

            if(!$identityName){

            Write-Host
            Write-Host "Opening APK file to get identityName to pass to the service..." -ForegroundColor Yellow

            $APKInformation = Get-ApkInformation -AndroidSDK $AndroidSDKLocation -sourceFile "$SourceFile"

            $identityName = $APKInformation[0]

            }

            if(!$identityVersion){

            Write-Host
            Write-Host "Opening APK file to get identityVersion to pass to the service..." -ForegroundColor Yellow

            $APKInformation = Get-ApkInformation -AndroidSDK $AndroidSDKLocation -sourceFile "$SourceFile"

            $identityVersion = $APKInformation[1]

            }

            if(!$versionName){

            Write-Host
            Write-Host "Opening APK file to get versionName to pass to the service..." -ForegroundColor Yellow

            $APKInformation = Get-ApkInformation -AndroidSDK $AndroidSDKLocation -sourceFile "$SourceFile"

            $versionName = $APKInformation[2]

            }


        
        $tempFile = [System.IO.Path]::GetDirectoryName("$SourceFile") + "\" + [System.IO.Path]::GetFileNameWithoutExtension("$SourceFile") + "_temp.bin"

        
        $filename = [System.IO.Path]::GetFileName("$SourceFile")

            if(!($displayName)){

            $displayName = $filename

            }

        
        Write-Host
        Write-Host "Creating JSON data to pass to the service..." -ForegroundColor Yellow
		$mobileAppBody = GetAndroidAppBody "$displayName" "$Publisher" "$Description" "$filename" "$identityName" "$identityVersion" "$versionName";
		
        Write-Host
        Write-Host "Creating application in Intune..." -ForegroundColor Yellow
        $mobileApp = MakePostRequest "mobileApps" ($mobileAppBody | ConvertTo-Json);

		
        Write-Host
        Write-Host "Creating Content Version in the service for the application..." -ForegroundColor Yellow
		$appId = $mobileApp.id;
		$contentVersionUri = "mobileApps/$appId/$LOBType/contentVersions";
		$contentVersion = MakePostRequest $contentVersionUri "{}";

        
        Write-Host
        Write-Host "Ecrypting the file '$SourceFile'..." -ForegroundColor Yellow
        $encryptionInfo = EncryptFile "$sourceFile" "$tempFile";
        $Size = (Get-Item "$sourceFile").Length
        $EncrySize = (Get-Item "$tempFile").Length

        Write-Host
        Write-Host "Creating the manifest file used to install the application on the device..." -ForegroundColor Yellow

        [xml]$manifestXML = '<?xml version="1.0" encoding="utf-8"?><AndroidManifestProperties xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Package>com.leadapps.android.radio.ncp</Package><PackageVersionCode>10</PackageVersionCode><PackageVersionName>1.0.5.4</PackageVersionName><ApplicationName>A_Online_Radio_1.0.5.4.apk</ApplicationName><MinSdkVersion>3</MinSdkVersion><AWTVersion></AWTVersion></AndroidManifestProperties>'

        $manifestXML.AndroidManifestProperties.Package = "$identityName" 
        $manifestXML.AndroidManifestProperties.PackageVersionCode = "$identityVersion" 
        $manifestXML.AndroidManifestProperties.PackageVersionName = "$identityVersion" 
        $manifestXML.AndroidManifestProperties.ApplicationName = "$filename" 

        $manifestXML_Output = $manifestXML.OuterXml.ToString()

        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($manifestXML_Output)
        $EncodedText =[Convert]::ToBase64String($Bytes)

		
        Write-Host
        Write-Host "Creating a new file entry in Azure for the upload..." -ForegroundColor Yellow
		$contentVersionId = $contentVersion.id;
		$fileBody = GetAppFileBody "$filename" $Size $EncrySize "$EncodedText";
		$filesUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files";
		$file = MakePostRequest $filesUri ($fileBody | ConvertTo-Json);
	
		
        Write-Host
        Write-Host "Waiting for the file entry URI to be created..." -ForegroundColor Yellow
		$fileId = $file.id;
		$fileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId";
		$file = WaitForFileProcessing $fileUri "AzureStorageUriRequest";

        
        Write-Host
        Write-Host "Uploading file to Azure Storage URI..." -ForegroundColor Yellow
		
        $sasUri = $file.azureStorageUri;
		UploadFileToAzureStorage $file.azureStorageUri $tempFile;

		
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitFileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/commit";
		MakePostRequest $commitFileUri ($encryptionInfo | ConvertTo-Json);

		
        Write-Host
        Write-Host "Waiting for the service to process the commit file request..." -ForegroundColor Yellow
		$file = WaitForFileProcessing $fileUri "CommitFile";

		
        Write-Host
        Write-Host "Committing the application to the Intune Service..." -ForegroundColor Yellow
		$commitAppUri = "mobileApps/$appId";
		$commitAppBody = GetAppCommitBody $contentVersionId $LOBType;
		MakePatchRequest $commitAppUri ($commitAppBody | ConvertTo-Json);

        Write-Host "Removing Temporary file '$tempFile'..." -f Gray
        Remove-Item -Path "$tempFile" -Force
        Write-Host

        Write-Host "Sleeping for $sleep seconds to allow patch completion..." -f Magenta
        Start-Sleep $sleep
        Write-Host

	}
	catch
	{
		Write-Host "";
		Write-Host -ForegroundColor Red "Aborting with exception: $($_.Exception.ToString())";
	}
}



function Upload-iOSLob(){



[cmdletbinding()]

param
(
    [parameter(Mandatory=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,

    [parameter(Mandatory=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$displayName,

    [parameter(Mandatory=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]$publisher,

    [parameter(Mandatory=$true,Position=4)]
    [ValidateNotNullOrEmpty()]
    [string]$description,

    [parameter(Mandatory=$true,Position=5)]
    [ValidateNotNullOrEmpty()]
    [string]$bundleId,

    [parameter(Mandatory=$true,Position=6)]
    [ValidateNotNullOrEmpty()]
    [string]$identityVersion,

    [parameter(Mandatory=$true,Position=7)]
    [ValidateNotNullOrEmpty()]
    [string]$versionNumber,

    [parameter(Mandatory=$true,Position=8)]
    [ValidateNotNullOrEmpty()]
    [string]$expirationDateTime
)

	try
	{
		
        $LOBType = "microsoft.graph.iosLOBApp"

        Write-Host "Testing if SourceFile '$SourceFile' Path is valid..." -ForegroundColor Yellow
        Test-SourceFile "$SourceFile"

        
        [datetimeoffset]$Expiration = $expirationDateTime

        $Date = get-date

            if($Expiration -lt $Date){

                Write-Error "$SourceFile has expired Follow the guidelines provided by Apple to extend the expiration date, then try adding the app again"
                throw

            }

        
        $tempFile = [System.IO.Path]::GetDirectoryName("$SourceFile") + "\" + [System.IO.Path]::GetFileNameWithoutExtension("$SourceFile") + "_temp.bin"
        
        
        $filename = [System.IO.Path]::GetFileName("$SourceFile")

        
        Write-Host
        Write-Host "Creating JSON data to pass to the service..." -ForegroundColor Yellow
		$mobileAppBody = GetiOSAppBody "$displayName" "$Publisher" "$Description" "$filename" "$bundleId" "$identityVersion" "$versionNumber" "$expirationDateTime";

        Write-Host
        Write-Host "Creating application in Intune..." -ForegroundColor Yellow

		$mobileApp = MakePostRequest "mobileApps" ($mobileAppBody | ConvertTo-Json);

		
        Write-Host
        Write-Host "Creating Content Version in the service for the application..." -ForegroundColor Yellow
		$appId = $mobileApp.id;
		$contentVersionUri = "mobileApps/$appId/$LOBType/contentVersions";
		$contentVersion = MakePostRequest $contentVersionUri "{}";

        
        Write-Host
        Write-Host "Ecrypting the file '$SourceFile'..." -ForegroundColor Yellow
        $encryptionInfo = EncryptFile $sourceFile $tempFile;
        $Size = (Get-Item "$sourceFile").Length
        $EncrySize = (Get-Item "$tempFile").Length

        Write-Host
        Write-Host "Creating the manifest file used to install the application on the device..." -ForegroundColor Yellow

        [string]$manifestXML = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>items</key><array><dict><key>assets</key><array><dict><key>kind</key><string>software-package</string><key>url</key><string>{UrlPlaceHolder}</string></dict></array><key>metadata</key><dict><key>AppRestrictionPolicyTemplate</key> <string>http://management.microsoft.com/PolicyTemplates/AppRestrictions/iOS/v1</string><key>AppRestrictionTechnology</key><string>Windows Intune Application Restrictions Technology for iOS</string><key>IntuneMAMVersion</key><string></string><key>CFBundleSupportedPlatforms</key><array><string>iPhoneOS</string></array><key>MinimumOSVersion</key><string>9.0</string><key>bundle-identifier</key><string>bundleid</string><key>bundle-version</key><string>bundleversion</string><key>kind</key><string>software</string><key>subtitle</key><string>LaunchMeSubtitle</string><key>title</key><string>bundletitle</string></dict></dict></array></dict></plist>'

        $manifestXML = $manifestXML.replace("bundleid","$bundleId")
        $manifestXML = $manifestXML.replace("bundleversion","$identityVersion")
        $manifestXML = $manifestXML.replace("bundletitle","$displayName")

        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($manifestXML)
        $EncodedText =[Convert]::ToBase64String($Bytes)

		
        Write-Host
        Write-Host "Creating a new file entry in Azure for the upload..." -ForegroundColor Yellow
		$contentVersionId = $contentVersion.id;
		$fileBody = GetAppFileBody "$filename" $Size $EncrySize "$EncodedText";
		$filesUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files";
		$file = MakePostRequest $filesUri ($fileBody | ConvertTo-Json);
	
		
        Write-Host
        Write-Host "Waiting for the file entry URI to be created..." -ForegroundColor Yellow
		$fileId = $file.id;
		$fileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId";
		$file = WaitForFileProcessing $fileUri "AzureStorageUriRequest";

        
        Write-Host
        Write-Host "Uploading file to Azure Storage..." -f Yellow

		$sasUri = $file.azureStorageUri;
		UploadFileToAzureStorage $file.azureStorageUri $tempFile;

		
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitFileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/commit";
		MakePostRequest $commitFileUri ($encryptionInfo | ConvertTo-Json);

		
        Write-Host
        Write-Host "Waiting for the service to process the commit file request..." -ForegroundColor Yellow
		$file = WaitForFileProcessing $fileUri "CommitFile";

		
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitAppUri = "mobileApps/$appId";
		$commitAppBody = GetAppCommitBody $contentVersionId $LOBType;
		MakePatchRequest $commitAppUri ($commitAppBody | ConvertTo-Json);

        Write-Host "Removing Temporary file '$tempFile'..." -f Gray
        Remove-Item -Path "$tempFile" -Force
        Write-Host

        Write-Host "Sleeping for $sleep seconds to allow patch completion..." -f Magenta
        Start-Sleep $sleep
        Write-Host

	}
	catch
	{
		Write-Host "";
		Write-Host -ForegroundColor Red "Aborting with exception: $($_.Exception.ToString())";
	}
}



function Upload-MSILob(){



[cmdletbinding()]

param
(
    [parameter(Mandatory=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,

    [parameter(Mandatory=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$publisher,

    [parameter(Mandatory=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]$description
)

	try	{

        $LOBType = "microsoft.graph.windowsMobileMSI"

        Write-Host "Testing if SourceFile '$SourceFile' Path is valid..." -ForegroundColor Yellow
        Test-SourceFile "$SourceFile"

        $MSIPath = "$SourceFile"

        
        $tempFile = [System.IO.Path]::GetDirectoryName("$SourceFile") + "\" + [System.IO.Path]::GetFileNameWithoutExtension("$SourceFile") + "_temp.bin"

        Write-Host
        Write-Host "Creating JSON data to pass to the service..." -ForegroundColor Yellow

        $FileName = [System.IO.Path]::GetFileName("$MSIPath")

        $PN = (Get-MSIFileInformation -Path "$MSIPath" -Property ProductName | Out-String).trimend()
        $PC = (Get-MSIFileInformation -Path "$MSIPath" -Property ProductCode | Out-String).trimend()
        $PV = (Get-MSIFileInformation -Path "$MSIPath" -Property ProductVersion | Out-String).trimend()
        $PL = (Get-MSIFileInformation -Path "$MSIPath" -Property ProductLanguage | Out-String).trimend()

		
		$mobileAppBody = GetMSIAppBody -displayName "$PN" -publisher "$publisher" -description "$description" -filename "$FileName" -identityVersion "$PV" -ProductCode "$PC"
        
        Write-Host
        Write-Host "Creating application in Intune..." -ForegroundColor Yellow
		$mobileApp = MakePostRequest "mobileApps" ($mobileAppBody | ConvertTo-Json);

		
        Write-Host
        Write-Host "Creating Content Version in the service for the application..." -ForegroundColor Yellow
		$appId = $mobileApp.id;
		$contentVersionUri = "mobileApps/$appId/$LOBType/contentVersions";
		$contentVersion = MakePostRequest $contentVersionUri "{}";

        
        Write-Host
        Write-Host "Ecrypting the file '$SourceFile'..." -ForegroundColor Yellow
        $encryptionInfo = EncryptFile $sourceFile $tempFile;
        $Size = (Get-Item "$sourceFile").Length
        $EncrySize = (Get-Item "$tempFile").Length

        Write-Host
        Write-Host "Creating the manifest file used to install the application on the device..." -ForegroundColor Yellow

        [xml]$manifestXML = '<MobileMsiData MsiExecutionContext="Any" MsiRequiresReboot="false" MsiUpgradeCode="" MsiIsMachineInstall="true" MsiIsUserInstall="false" MsiIncludesServices="false" MsiContainsSystemRegistryKeys="false" MsiContainsSystemFolders="false"></MobileMsiData>'

        $manifestXML.MobileMsiData.MsiUpgradeCode = "$PC"

        $manifestXML_Output = $manifestXML.OuterXml.ToString()

        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($manifestXML_Output)
        $EncodedText =[Convert]::ToBase64String($Bytes)

		
        Write-Host
        Write-Host "Creating a new file entry in Azure for the upload..." -ForegroundColor Yellow
		$contentVersionId = $contentVersion.id;
		$fileBody = GetAppFileBody "$FileName" $Size $EncrySize "$EncodedText";
		$filesUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files";
		$file = MakePostRequest $filesUri ($fileBody | ConvertTo-Json);
	
		
        Write-Host
        Write-Host "Waiting for the file entry URI to be created..." -ForegroundColor Yellow
		$fileId = $file.id;
		$fileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId";
		$file = WaitForFileProcessing $fileUri "AzureStorageUriRequest";

		
        Write-Host
        Write-Host "Uploading file to Azure Storage..." -f Yellow

		$sasUri = $file.azureStorageUri;
		UploadFileToAzureStorage $file.azureStorageUri $tempFile;

		
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitFileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/commit";
		MakePostRequest $commitFileUri ($encryptionInfo | ConvertTo-Json);

		
        Write-Host
        Write-Host "Waiting for the service to process the commit file request..." -ForegroundColor Yellow
		$file = WaitForFileProcessing $fileUri "CommitFile";

		
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitAppUri = "mobileApps/$appId";
		$commitAppBody = GetAppCommitBody $contentVersionId $LOBType;
		MakePatchRequest $commitAppUri ($commitAppBody | ConvertTo-Json);

        Write-Host "Removing Temporary file '$tempFile'..." -f Gray
        Remove-Item -Path "$tempFile" -Force
        Write-Host

        Write-Host "Sleeping for $sleep seconds to allow patch completion..." -f Magenta
        Start-Sleep $sleep
        Write-Host

	}
	
    catch {

		Write-Host "";
		Write-Host -ForegroundColor Red "Aborting with exception: $($_.Exception.ToString())";
	
    }

}





write-host


if($global:authToken){

    
    $DateTime = (Get-Date).ToUniversalTime()

    
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}



else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }


$global:authToken = Get-AuthToken -User $User

}







$AndroidSDKLocation = "C:\AndroidSDK\build-tools"

$baseUrl = "https://graph.microsoft.com/beta/deviceAppManagement/"

$logRequestUris = $true;
$logHeaders = $false;
$logContent = $true;

$sleep = 30













