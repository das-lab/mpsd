function Decrypt-RDCMan ($FilePath) {

    if (!$FilePath) {
        [xml]$config = Get-Content "$env:LOCALAPPDATA\microsoft\remote desktop connection manager\rdcman.settings"
        $Xml = Select-Xml -Xml $config -XPath "//FilesToOpen/*"
        $Xml | select-object -ExpandProperty "Node"| % {Write-Output "Decrypting file: " $_.InnerText; Decrypt-RDCMan $_.InnerText}
    } else {
    [xml]$Types = Get-Content $FilePath

    $Xml = Select-Xml -Xml $Types -XPath "//logonCredentials"

    
    $Xml | select-object -ExpandProperty "Node" | % { $pass = Decrypt-DPAPI $_.Password; $_.Domain + "\" + $_.Username + " - " + $Pass + " - " + "Hash:" + $_.Password + "`n" } 

    
    $Xml | select-object -ExpandProperty "Node" | % { $pass = Decrypt-DPAPI $_.Password."
    }
}

function Decrypt-DPAPI ($EncryptedString) {
    
    Add-Type -assembly System.Security
    $encoding= [System.Text.Encoding]::ASCII
    $uencoding = [System.Text.Encoding]::UNICODE

    
    try {
    	$encryptedBytes = [System.Convert]::FromBase64String($encryptedstring)
        $bytes1 = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        [System.Text.Encoding]::Convert([System.Text.Encoding]::UNICODE, $encoding, $bytes1) | % { $myStr1 += [char]$_}
        echo $myStr1
    } 
    catch {
        
        try {
            $encryptedBytes = [System.Convert]::FromBase64String($encryptedstring)
            $bytes1 = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
            [System.Text.Encoding]::Convert([System.Text.Encoding]::UNICODE, $encoding, $bytes1) | % { $myStr1 += [char]$_}
            echo $myStr1
        }
	    catch {
            echo "Could not decrypt password"
        }
    }
}


