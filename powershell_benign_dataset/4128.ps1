 
 
 
 
 
 

 Clear-Host  

 Function RenameWindow ($Title) {  

      
      Set-Variable -Name a -Scope Local -Force  

      $a = (Get-Host).UI.RawUI  
      $a.WindowTitle = $Title  

      
      Remove-Variable -Name a -Scope Local -Force 
 
 }  

 Function GetProductName($Description) {
  
      
      Set-Variable -Name AppLocal -Scope Local -Force  
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Desc -Scope Local -Force  
      Set-Variable -Name IDLocal -Scope Local -Force  
      Set-Variable -Name IDNumber -Scope Local -Force  
      Set-Variable -Name Uninstaller -Scope Local -Force
  
      
      $Description = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Desc = wmic product where $Description get Description  
      $Uninstaller = wmic product where $Description get IdentifyingNumber  
      $Desc | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "Description")-and($_ -ne "")){  
               $AppName += $_  
             }  
      }  
      $Uninstaller | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "IdentifyingNumber")-and($_ -ne "")){  
               $IDNumber += $_  
             }  
      }  
      $AppLocal = New-Object System.Object  
      $AppLocal | Add-Member -type NoteProperty -name Application -value $AppName  
      If ($AppName -ne $null) {  
           $AppLocal | Add-Member -type NoteProperty -name GUID -value $IDNumber  
      } else {  
           $AppLocal | Add-Member -type NoteProperty -name Status -value "Not Installed"  
      }  
      $AppLocal  

      
      Remove-Variable -Name AppLocal -Scope Local -Force  
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Desc -Scope Local -Force  
      Remove-Variable -Name IDLocal -Scope Local -Force  
      Remove-Variable -Name IDNumber -Scope Local -Force  
      Remove-Variable -Name Uninstaller -Scope Local -Force 
 
 } 
 
 RenameWindow "Product Name and GUID"  
 GetProductName "Office Professional Plus"  
 GetProductName "Microsoft Lync 2013"  
 GetProductName "Adobe Reader"  
 GetProductName "Microsoft Visio Professional"  