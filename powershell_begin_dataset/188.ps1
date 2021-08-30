function New-SCCMDeviceVariable
{
    
    [cmdletbinding()]
    PARAM (
        [parameter(Mandatory = $true)]
        [Alias('SiteServer')]
        [System.String]$ComputerName,

        [parameter(Mandatory = $true)]
        [System.String]$SiteCode,

        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [parameter(Mandatory = $true)]
        [int]$ResourceID,

        [parameter(Mandatory = $true)]
        [Alias("VariableName")]
        [System.String]$Name,

        [parameter(Mandatory = $true)]
        [Alias("VariableValue")]
        [System.String]$Value,

        [System.Boolean]$IsMasked = $false
    )
    PROCESS
    {
        TRY
        {
            Write-Verbose -Message "$ResourceID - Create splatting"
            $SCCM_Splatting = @{
                ComputerName = $ComputerName
                NameSpace = "root\sms\site_$SiteCode"
            }

            IF ($PSBoundParameters['Credential'])
            {
                $SCCM_Splatting.Credential = $Credential
            }

            Write-Verbose -Message "$ResourceID - Verify if machine settings exist"
            
            $MachineSettingsClass = Get-WmiObject @SCCM_Splatting -Query "SELECT ResourceID FROM SMS_MachineSettings WHERE ResourceID = '$ResourceID'"

            
            if ($MachineSettingsClass)
            {
                Write-Verbose -Message "$ResourceID - Machine Settings Exists"

                
                Write-Verbose -Message "$ResourceID - Create Variable"
                $MachineVariablesClass = Get-WmiObject -list @SCCM_Splatting -Class "SMS_MachineVariable"
                $NewMachineVariableInstance = $MachineVariablesClass.CreateInstance()

                
                $NewMachineVariableInstance.psbase.Properties['Name'].Value = $Name
                $NewMachineVariableInstance.psbase.Properties['Value'].Value = $Value
                $NewMachineVariableInstance.psbase.Properties['IsMasked'].Value = $IsMasked

                
                $MachineSettingsClass.get()


                
                Write-Verbose -Message "$ResourceID - Insert machine Variable into machine settings"
                $MachineSettingsClass.MachineVariables += $NewMachineVariableInstance

                
                Write-Verbose -Message "$ResourceID - Save Change"
                $MachineSettingsClass.Put()
            }
            else
            {
                Write-Verbose -Message "$ResourceID - Machine Settings does NOT Exists"

                
                Write-Verbose -Message "$ResourceID - Machine Settings - Creation"
                $MachineSettingsClass = Get-WmiObject @SCCM_Splatting -List -Class 'SMS_MachineSettings'
                $NewMachineSettingsClassInstance = $MachineSettingsClass.CreateInstance()

                
                $NewMachineSettingsClassInstance.psbase.properties["ResourceID"].value = $ResourceID
                $NewMachineSettingsClassInstance.psbase.properties["SourceSite"].value = $SiteCode

                
                Write-Verbose -Message "$ResourceID - Machine Variable - Creation"
                $MachineVariablesClass = Get-WmiObject -list @SCCM_Splatting -Class "SMS_MachineVariable"
                $NewMachineVariablesInstance = $MachineVariablesClass.CreateInstance()

                
                $NewMachineVariablesInstance.psbase.Properties['Name'].Value = $Name
                $NewMachineVariablesInstance.psbase.Properties['Value'].Value = $Value
                $NewMachineVariablesInstance.psbase.Properties['IsMasked'].Value = $IsMasked

                
                Write-Verbose -Message "$ResourceID - Insert machine Variable into machine settings"
                $NewMachineSettingsClassInstance.MachineVariables += $NewMachineVariablesInstance

                
                Write-Verbose -Message "$ResourceID - Save Change"
                $NewMachineSettingsClassInstance.Put()
            }
        }
        CATCH
        {
            Write-Warning -Message "$ResourceID - Issue while processing the Device"
            $Error[0]
        }
        FINALLY
        { }
    } 
}
