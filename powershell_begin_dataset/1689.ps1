

function Decode-Text {
    param (
        [string]$Text,
        [validateset('SecureString', 'SecureStringWithKey', 'Base64', 'ASCII')]
        [string]$Method = 'Base64'
    )

    process {
        if (!$Text) {
            $Text = $input
        }
    }

    end {
        switch ($method) {
            'SecureString' {
                (New-Object pscredential ' ', (ConvertTo-SecureString $text)).GetNetworkCredential().Password
                
                
            }

            'SecureStringWithKey' {
                (New-Object pscredential ' ', (ConvertTo-SecureString $text -Key (1..16))).GetNetworkCredential().Password
            }

            'Base64' {
                [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($text))
            }

            'ASCII' {
                $pwlength = $text.Length / 3 - 1
                -join(0..$pwlength | % {[char](32 + $text.Substring(($_*3), 3))})
            }
        }
    }
}
