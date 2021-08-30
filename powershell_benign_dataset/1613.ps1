



$file = "c:\temp\redditposh.csv"
$errorlog = "c:\temp\redditposherrors.txt"

if (!(Test-Path $file)) {
    'title,link,time' | Set-Content $file
}
$last = ipcsv $file

$to = 
$From = 'address@gmail.com'
$SMTPServer = 'smtp.gmail.com'
$SMTPPort = '587'
$pw = 'password' | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object pscredential $from, $pw

function sendcheck ($info) {
    if ($info.link -and @($last | ? link -eq $info.Link).Count -eq 0) {
        $info | epcsv $file -NoTypeInformation -Append

        $body = $info.title, $info.link -join "`n"

        $site = $info.link -replace 'https?://(?:www.)?([^/]+).*', '$1'
        Send-MailMessage -To $to -From $from -Subject $site -Body $body -SmtpServer $smtpserver -Port $SMTPPort -Credential $cred -usessl

        if ([bool]$error[0] -and $error[0].exception -notmatch 'module') {
            Get-Date | Add-Content $errorlog
            $error[0] | Add-Content $errorlog 
        }
    }
}


sendcheck (([xml](iwr reddit.com/r/powershell/new/.rss).content).feed.entry[0] | % {
    [pscustomobject]@{
        Title = $_.title
        Link = $_.link.href
        Time = Get-Date -f s
    }
})










