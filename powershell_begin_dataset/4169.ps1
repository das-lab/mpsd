 cls  

 
 Set-Variable -Name a -Scope Global -Force  
 Set-Variable -Name Output -Scope Global -Force  

 Function AddRemovePrograms($KeyName, $DisplayName, $Version){  
      
      Set-Variable -Name AddRemKey -Value "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Scope Local -Force  

      New-Item -Path $AddRemKey -Name $KeyName –Force  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayName -Value $DisplayName -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayVersion -Value $Version -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name UninstallString -Value " " -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name Publisher -Value "Gresham, Smith and Partners" -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayIcon -Value "c:\windows\GSPBox_Icon.bmp" -PropertyType String  

      
      Remove-Variable -Name AddRemKey -Scope Local -Force  
 }  
 Invoke-Command {dism.exe /online /disable-feature /featurename:MediaCenter /norestart}  
 $a = Invoke-Command {dism.exe /online /get-featureinfo /featurename:MediaCenter}  
 $Output = $a | Select-String "State : Disabled"  
 Write-Host $Output  
 If ($Output -like "State : Disabled"){  
      AddRemovePrograms "MediaCenter" "MediaCenter" "Disabled"  
 }  

 
 Remove-Variable -Name a -Scope Global -Force  
 Remove-Variable -Name Output -Scope Global -Force  