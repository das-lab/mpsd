











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Reset-HostsFile' {
    $customHostsFile = ''
    
    BeforeEach {
        $Global:Error.Clear()
        $customHostsFile = Join-Path $env:temp ([IO.Path]::GetRandomFileName())
        @"

















    
127.0.0.1       localhost
"@ | Out-File -FilePath $customHostsfile -Encoding OEM    
    }
    
    AfterEach {
        Remove-Item $customHostsFile
    }
    
    It 'should operate on hosts file by default' {
        $originalHostsfile = Read-File -Path (Get-PathToHostsFile)
    
        $firstEntry = '10.1.1.1     one.example.com'
        $commentLine = '
        $secondEntry = "10.1.1.2     two.example.com"
        @"
    
$firstEntry
$commentLine
$secondEntry
    
"@ | Write-File -Path (Get-PathToHostsFile) 
    
        try
        {
            Reset-HostsFile
            $hostsFile = Read-File -Path (Get-PathToHostsFile)
            $hostsFile | Where-Object { $_ -eq $firstEntry } | Should BeNullOrEmpty
            $hostsFile | Where-Object { $_ -eq $commentLine } | Should BeNullOrEmpty
            $hostsFile | Where-Object { $_ -eq $secondEntry } | Should BeNullOrEmpty
        }
        finally
        {
            if( $originalHostsfile )
            {
                Write-File -Path (Get-PathToHostsFile) -InputObject $originalHostsFile
            }
        }
    }
    
    It 'should remove custom hosts entry' {
        $commentLine = '
        $customEntry = "10.1.1.1     example.com"
    @"
    
$commentLine
$customEntry
    
"@ | Out-File -FilePath $customHostsFile -Encoding OEM -Append
        Reset-HostsFile -Path $customHostsFile
        $hostsFile = Get-Content -Path $customHostsFile
        $hostsFile | Where-Object { $_ -eq $commentLine } | Should BeNullOrEmpty
        $hostsFile | Where-Object { $_ -eq $customEntry } | Should BeNullOrEmpty
        $hostsFile | Where-Object { $_ -eq '127.0.0.1       localhost' } | Should Not BeNullOrEmpty
    }
    
    It 'should support should process' {
        $customEntry = '1.2.3.4       example.com'
        $customEntry | Set-Content -Path $customHostsFile
        Reset-HostsFile -WhatIf
        Get-Content -Path $customHostsFile | Where-Object { $_ -eq $customEntry } | Should Not BeNullOrEmpty
    }
    
    It 'should create file if it does not exist' {
        Remove-Item $customHostsFile
        
        Reset-HostsFile -Path $customHostsFile
    
        $hostsFile = Get-Content -Path $customHostsFile
        $hostsFile | Where-Object { $_ -eq '127.0.0.1       localhost' } | Should Not BeNullOrEmpty
    }
}
