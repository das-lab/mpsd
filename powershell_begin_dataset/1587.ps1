
if (gcm Get-Clipboard -ea 0) {
    return
}






function Get-Clipboard {
    Add-Type -AssemblyName System.Windows.Forms

    $(if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'STA') {
        Write-Verbose 'STA mode: Using [Windows.Forms.Clipboard] directly.'
        
        [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::UnicodeText)
    } else {
        Write-Verbose 'MTA mode: Using a [System.Windows.Forms.TextBox] instance for clipboard access.'
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Multiline = $true
        $tb.Paste()
        $tb.Text
    }).Split("`n") | % {$_.Trim()}
}




