








$LogPath = "$PSScriptRoot\Log.txt"


[bool]$SendMailOnError = $true


$SmtpServer = ""
$MailFrom = ""
[String[]]$MailTo = @("","")
$MailSubject = "[Script Error] Title..."




$Error.Clear()


$Cred = Invoke-Expression -Command "$PSScriptRoot\Get-ManagedCredential.ps1 -FilePath $PSScriptRoot\cred.xml"


Start-Transcript -Path $LogPath -Append


Invoke-Expression -Command "$PSScriptRoot\MYSCRIPT.ps1 -Parameter1 ""Test1"" -Parameter2 ""Test2"" -Credential `$Cred -Verbose"

if($SendMailOnError -and $Error.Count -gt 0)
{
    
    Send-MailMessage -Subject $MailSubject -Body "$($Error | Out-String)" -SmtpServer $SmtpServer -From $MailFrom -To $MailTo 
}


Stop-Transcript