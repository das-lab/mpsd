
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