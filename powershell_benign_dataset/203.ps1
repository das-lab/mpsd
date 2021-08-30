
[CmdletBinding()]
PARAM (
    [Alias("ExpirationDays")]
    [Int]$Days = '10',

    [String]$SearchBase = "",

    [string]$EmailFrom = "ScriptServer@Contoso.com",

    [string]$EmailTo = "IT@Contoso.com",

    [String]$EmailSMTPServer = "smtp.contoso.com"
)
BEGIN
{
    

    
    [String]$EmailSubject = "PS Report-ActiveDirectory-Expiring Users (in the next $days days)"
    [String]$NoteLine = "Generated from $($env:Computername.ToUpper()) on $(Get-Date -format 'yyyy/MM/dd HH:mm:ss')"

    
    
    Function Send-Email
    {
    

        [CmdletBinding()]
        PARAM (
            [Parameter(Mandatory = $true)]
            [Alias('To')]
            [String]$EmailTo,

            [Parameter(Mandatory = $true)]
            [Alias('From')]
            [String]$EmailFrom,

            [String]$EmailCC,

            [String]$EmailBCC,

            [String]$Subject = "Email from PowerShell",

            [String]$Body = "Hello World",

            [Switch]$BodyIsHTML = $false,

            [ValidateSet("Default", "ASCII", "Unicode", "UTF7", "UTF8", "UTF32")]
            [System.Text.Encoding]$Encoding = "Default",

            [String]$Attachment,

            [Parameter(ParameterSetName = "Credential", Mandatory = $true)]
            [String]$Username,

            [Parameter(ParameterSetName = "Credential", Mandatory = $true)]
            [String]$Password,

            [Parameter(Mandatory = $true)]
            [ValidateScript({
                
                Test-Connection -ComputerName $_ -Count 1 -Quiet
            })]
            [string]$SMTPServer,

            [ValidateRange(1, 65535)]
            [int]$Port,

            [Switch]$EnableSSL
        )

        PROCESS
        {
            TRY
            {
                
                $SMTPMessage = New-Object System.Net.Mail.MailMessage
                $SMTPMessage.From = $EmailFrom
                $SMTPMessage.To = $EmailTo
                $SMTPMessage.Body = $Body
                $SMTPMessage.Subject = $Subject
                $SMTPMessage.CC = $EmailCC
                $SMTPMessage.Bcc = $EmailBCC
                $SMTPMessage.IsBodyHtml = $BodyIsHtml
                $SMTPMessage.BodyEncoding = $Encoding
                $SMTPMessage.SubjectEncoding = $Encoding

                
                IF ($PSBoundParameters['attachment'])
                {
                    $SMTPattachment = New-Object -TypeName System.Net.Mail.Attachment($attachment)
                    $SMTPMessage.Attachments.Add($STMPattachment)
                }

                
                $SMTPClient = New-Object Net.Mail.SmtpClient
                $SMTPClient.Host = $SmtpServer
                $SMTPClient.Port = $Port

                
                IF ($PSBoundParameters['EnableSSL'])
                {
                    $SMTPClient.EnableSsl = $true
                }

                
                IF (($PSBoundParameters['Username']) -and ($PSBoundParameters['Password']))
                {
                    
                    $Credentials = New-Object -TypeName System.Net.NetworkCredential
                    $Credentials.UserName = $username.Split("@")[0]
                    $Credentials.Password = $Password

                    
                    $SMTPClient.Credentials = $Credentials
                }

                
                $SMTPClient.Send($SMTPMessage)

            }
            CATCH
            {
                Write-Warning -message "[PROCESS] Something wrong happened"
                Write-Warning -Message $Error[0].Exception.Message
            }
        }
        END
        {
            
            Remove-Variable -Name SMTPClient
            Remove-Variable -Name Password
        }
    } 

}
PROCESS
{
    TRY
    {
        $Accounts = Search-ADAccount -AccountExpiring -SearchBase $SearchBase -TimeSpan "$($days).00:00:00" |
        Select-Object -Property AccountExpirationDate, Name, Samaccountname, @{ Label = "Manager"; E = { (Get-Aduser(Get-aduser $_ -property manager).manager).Name } }, DistinguishedName

        $Css = @"
<style>
table {
    font-family: verdana,arial,sans-serif;
    font-size:11px;
    color:
    border-width: 1px;
    border-color: 
    border-collapse: collapse;
}

th {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: 
    background-color: 
}

td {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: 
    background-color: 
}
</style>
"@

        $PreContent = "<Title>Active Directory - Expiring Users (next $days days)</Title>"
        $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"


        
        
        IF (-not ($accounts))
        {
            $body = "No user account expiring in the next $days days to report <br>$PostContent"
        }
        ELSE
        {
            $body = $Accounts |
            ConvertTo-Html -head $Css -PostContent $PostContent -PreContent $PreContent
        }

        
        Send-Email -SMTPServer $EmailSMTPServer -From $EmailFrom -To $Emailto -BodyIsHTML `
                   -Subject $EmailSubject -Body $body

    }
    CATCH
    {
        Write-Warning -Message "[PROCESS] Something happened"
        Write-Warning -Message $Error[0].Exception.Message
    }
}
END
{

}