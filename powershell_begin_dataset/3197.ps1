function Get-UACSetting {

[CmdletBinding()]
    param(
        [Parameter( 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0
        )][string[]]$ComputerName = $env:COMPUTERNAME,
        [switch]$RevertToDefault,
        [validaterange(0,1)][int]$FilterAdministratorTokenD = 0,
        [validaterange(0,1)][int]$EnableUIADesktopToggleD = 0,
        [validaterange(0,5)][int]$ConsentPromptBehaviorAdminD = 5,
        [validaterange(0,3)][int]$ConsentPromptBehaviorUserD = 3,
        [validaterange(0,1)][int]$EnableInstallerDetectionD = 1,
        [validaterange(0,1)][int]$ValidateAdminCodeSignaturesD = 0,
        [validaterange(0,1)][int]$EnableSecureUIAPathsD = 1,
        [validaterange(0,1)][int]$EnableLUAD = 1,
        [validaterange(0,1)][int]$PromptOnSecureDesktopD = 1,
        [validaterange(0,1)][int]$EnableVirtualizationD = 1
    )
    Begin {

        function quote-list {$args}

        
        $key = "Software\Microsoft\Windows\CurrentVersion\Policies\System"
    
        
        $values = quote-list FilterAdministratorToken EnableUIADesktopToggle ConsentPromptBehaviorAdmin 
        $values += quote-list ConsentPromptBehaviorUser EnableInstallerDetection ValidateAdminCodeSignatures
        $values += quote-list EnableSecureUIAPaths EnableLUA PromptOnSecureDesktop EnableVirtualization

    }
    Process{
        
        foreach($computer in $ComputerName){

            
            if(Test-connection $computer -quiet -count 2 -buffersize 16){

                
                $results = @()

                try{
                    
                    $OpenRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$computer)
    
                    
                    foreach($value in $values) {
        
                        
                        $subkey = $OpenRegistry.OpenSubKey($key,$true)
                        $data = $subkey.GetValue($value)
                        New-Variable -Name "$value" -Value $data -force
        
                        
                        $dataD = (Get-Variable -Name "$value`D").value

                        
                        $obj = "" | select ComputerName, Value, existingData, defaultData, isDefault
                        $obj.ComputerName = $computer
                        $obj.Value = "$value"
                        $obj.existingData = "$data"
                        $obj.defaultData = "$dataD"
                        $obj.isDefault = 1
        
                        
                        if($data -ne $dataD){
            
                            
                            $obj.isDefault = 0

                            
                            if($RevertToDefault){
                                $Subkey.SetValue("$value",$dataD)
                                $obj | Add-Member -MemberType NoteProperty -name newData -Value $dataD -Force
                            }
                        }

                        
                        $results += $obj
                    }
        
                    
                    $properties = quote-list ComputerName Value existingData defaultData
    
                    if($RevertToDefault){
                        
                        $properties += "newData"    
                    } 
                    else{
                        
                        $properties += "isDefault"
                    }

                    
                    $results | select -Property $properties
                }
                Catch{
                    Write-Error "Error pulling UAC settings from $computer"
                }
            }
        }
    }
}