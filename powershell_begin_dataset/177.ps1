function Send-Email
{


	[CmdletBinding(DefaultParameterSetName = 'Main')]
	param
	(
		[Parameter(ParameterSetName = 'Main',
				   Mandatory = $true)]
		[Alias('EmailTo')]
		[String[]]$To,

		[Parameter(ParameterSetName = 'Main',
				   Mandatory = $true)]
		[Alias('EmailFrom', 'FromAddress')]
		[String]$From,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[string]$FromDisplayName,

		[Parameter(ParameterSetName = 'Main')]
		[Alias('EmailCC')]
		[String]$CC,

		[Parameter(ParameterSetName = 'Main')]
		[Alias('EmailBCC')]
		[System.String]$BCC,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[Alias('ReplyTo')]
		[System.string[]]$ReplyToList,

		[Parameter(ParameterSetName = 'Main')]
		[System.String]$Subject = "Email from PowerShell",

		[Parameter(ParameterSetName = 'Main')]
		[System.String]$Body = "Hello World",

		[Parameter(ParameterSetName = 'Main')]
		[Switch]$BodyIsHTML = $false,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[System.Net.Mail.MailPriority]$Priority = "Normal",

		[Parameter(ParameterSetName = 'Main')]
		[ValidateSet("Default", "ASCII", "Unicode", "UTF7", "UTF8", "UTF32")]
		[System.String]$Encoding = "Default",

		[Parameter(ParameterSetName = 'Main')]
		[System.String]$Attachment,

		[Parameter(ParameterSetName = 'Main')]
		[System.Net.NetworkCredential]$Credential,

		[Parameter(ParameterSetName = 'Main',
				   Mandatory = $true)]
		[ValidateScript({
			
			Test-Connection -ComputerName $_ -Count 1 -Quiet
		})]
		[Alias("Server")]
		[string]$SMTPServer,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateRange(1, 65535)]
		[Alias("SMTPServerPort")]
		[int]$Port = 25,

		[Parameter(ParameterSetName = 'Main')]
		[Switch]$EnableSSL,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[Alias('EmailSender', 'Sender')]
		[string]$SenderAddress,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[System.String]$SenderDisplayName,

		[Parameter(ParameterSetName = 'Main')]
		[ValidateNotNullOrEmpty()]
		[Alias('DeliveryOptions')]
		[System.Net.Mail.DeliveryNotificationOptions]$DeliveryNotificationOptions
	)

	

	PROCESS
	{
		TRY
		{
			
			$SMTPMessage = New-Object -TypeName System.Net.Mail.MailMessage
			$SMTPMessage.From = $From
			FOREACH ($ToAddress in $To) { $SMTPMessage.To.add($ToAddress) }
			$SMTPMessage.Body = $Body
			$SMTPMessage.IsBodyHtml = $BodyIsHTML
			$SMTPMessage.Subject = $Subject
			$SMTPMessage.BodyEncoding = $([System.Text.Encoding]::$Encoding)
			$SMTPMessage.SubjectEncoding = $([System.Text.Encoding]::$Encoding)
			$SMTPMessage.Priority = $Priority
			$SMTPMessage.Sender = $SenderAddress

			
			IF ($PSBoundParameters['SenderDisplayName'])
			{
				$SMTPMessage.Sender.DisplayName = $SenderDisplayName
			}

			
			IF ($PSBoundParameters['FromDisplayName'])
			{
				$SMTPMessage.From.DisplayName = $FromDisplayName
			}

			
			IF ($PSBoundParameters['CC'])
			{
				$SMTPMessage.CC.Add($CC)
			}

			
			IF ($PSBoundParameters['BCC'])
			{
				$SMTPMessage.BCC.Add($BCC)
			}

			
			IF ($PSBoundParameters['ReplyToList'])
			{
				foreach ($ReplyTo in $ReplyToList)
				{
					$SMTPMessage.ReplyToList.Add($ReplyTo)
				}
			}

			
			IF ($PSBoundParameters['attachment'])
			{
				$SMTPattachment = New-Object -TypeName System.Net.Mail.Attachment($attachment)
				$SMTPMessage.Attachments.Add($STMPattachment)
			}

			
			IF ($PSBoundParameters['DeliveryNotificationOptions'])
			{
				$SMTPMessage.DeliveryNotificationOptions = $DeliveryNotificationOptions
			}

			
			$SMTPClient = New-Object -TypeName Net.Mail.SmtpClient
			$SMTPClient.Host = $SmtpServer
			$SMTPClient.Port = $Port

			
			IF ($PSBoundParameters['EnableSSL'])
			{
				$SMTPClient.EnableSsl = $true
			}

			
			
			IF ($PSBoundParameters['Credential'])
			{
				

				
				$SMTPClient.Credentials = $Credential
			}
			IF (-not $PSBoundParameters['Credential'])
			{
				
				$SMTPClient.UseDefaultCredentials = $true
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
		
		Remove-Variable -Name SMTPClient -ErrorAction SilentlyContinue
		Remove-Variable -Name Password -ErrorAction SilentlyContinue
	}
} 