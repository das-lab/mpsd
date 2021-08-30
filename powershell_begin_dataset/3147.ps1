$From = ""
$To = ""
$MailServer = ""

function SendMailMessage
{
    param(
        [String]$Subject,
        [String]$Body
    )

    Send-MailMessage -SmtpServer $MailServer -From $From -To $To -Subject $Subject -Body $Body
}

