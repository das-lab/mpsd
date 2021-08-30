
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Specify the name of the variable used in CustomSettings.ini for dynamic Application installations. Default is 'APPLICATIONS'.")]
    [ValidateNotNullOrEmpty()]
    [string]$RuleVariableName = "APPLICATIONS",

    [parameter(Mandatory=$false, HelpMessage="Specify the name of the base variable referenced in the Install Applications Task Sequence step. Default is 'COALESCEDAPPS'.")]
    [ValidateNotNullOrEmpty()]
    [string]$BaseVariableName = "COALESCEDAPPS",

    [parameter(Mandatory=$false, HelpMessage="Specify the suffix number length of the rule variable from e.g. CustomSettings.ini. Value of 3 should be used when the suffix is e.g. 001. Default is '3'.")]
    [ValidateNotNullOrEmpty()]
    [string]$Length = 3
)
Begin {
    
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }

    
    $TSEnvironmentVariables = $TSEnvironment.GetVariables()
}
Process {
    
    function Write-CMLogEntry {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity
	    )
	    
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath "DynamicApplicationsList.log"

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DynamicApplicationsList"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to smsts.log file"
        }
    }

    
    Write-CMLogEntry -Value "Start reconstruction of TSEnvironment variables matching '$($RuleVariableName)' rule variable name" -Severity 1

    
    $RuleVariableList = New-Object -TypeName System.Collections.ArrayList

    
    if ($TSEnvironmentVariables -ne $null) {
        foreach ($TSEnvironmentVariable in $TSEnvironmentVariables) {
            if ($TSEnvironmentVariable.SubString(0, $TSEnvironmentVariable.Length - $Length) -like $RuleVariableName) {
                Write-CMLogEntry -Value "Matched '$($TSEnvironmentVariable)' TSEnvironment variable, adding to BaseVariable array list for reconstruction" -Severity 1
                $RuleVariableList.Add(@{$TSEnvironmentVariable = $TSEnvironment.Value($TSEnvironmentVariable)}) | Out-Null
            }
        }
    }
    else {
        Write-CMLogEntry -Value "Unable to retrieve TSEnvironment variables" -Severity 3 ; exit 1
    }

    
    $BaseCount = 1
    
    
    if ($RuleVariableList.Count -ge 1) {
        
        $BaseVariableList = New-Object -TypeName System.Collections.ArrayList

        
        foreach ($BaseVariable in $RuleVariableList) {
            
            $NewBaseVariableName = -join @($BaseVariableName, ("{0:00}" -f $BaseCount))
            Write-CMLogEntry -Value "Constructed new base variable '$($NewBaseVariableName)'" -Severity 1
            $BaseVariableList.Add(@{$NewBaseVariableName = $TSEnvironment.Value($BaseVariable.Keys)}) | Out-Null

            
            $BaseCount++
        }
    }
    else {
        Write-CMLogEntry -Value "No matches found for specified RuleVariableName" -Severity 3 ; exit 1
    }

    
    if ($BaseVariableList.Count -ge 1) {
        foreach ($BaseVariable in $BaseVariableList) {
            
            Write-CMLogEntry -Value "Setting TSEnvironment base variable '$($BaseVariable.Keys)' with value '$($BaseVariable.Values)'" -Severity 1
            $TSEnvironment.Value("$($BaseVariable.Keys)") = "$($BaseVariable.Values)"
        }
    }
    else {
        Write-CMLogEntry -Value "Unable to determine reconstructed base variables" -Severity 3 ; exit 1
    }
}