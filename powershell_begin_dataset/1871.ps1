

Describe "Write-Debug tests" -Tags "CI" {
    It "Should not have added line breaks" {
        $text = "0123456789"
        while ($text.Length -lt [Console]::WindowWidth) {
            $text += $text
        }
        $origDebugPref = $DebugPreference
        $DebugPreference = "Continue"
        try {
            $out = Write-Debug $text 5>&1
            $out | Should -BeExactly $text
        }
        finally {
            $DebugPreference = $origDebugPref
        }
    }

    It "Should not prompt the user" {
        
        
        $p = [Diagnostics.Process]::new()
        $p.StartInfo.FileName = (Get-Process -Id $PID).Path
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Write-Debug -Message 'A debug message' -Debug"))
        $p.StartInfo.Arguments = "-EncodedCommand $encoded -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -OutputFormat text"
        $p.StartInfo.UseShellExecute = $false
        $p.StartInfo.RedirectStandardError = $true
        $p.Start() | Out-Null
        $out = $p.StandardError.ReadToEnd()
        $out | Should -BeNullOrEmpty
    }
}
