function Invoke-SMBScanner {

    
    [CmdletBinding()] Param(
        [Parameter(Mandatory = $False,ValueFromPipeline=$True)]
        [String] $ComputerName,

        [parameter(Mandatory = $True)]
        [String] $UserName,

        [parameter(Mandatory = $True)]
        [String] $Password,

        [parameter(Mandatory = $False)]
        [Switch] $NoPing
    )

    Begin {
        Set-StrictMode -Version 2
        
        Try {Add-Type -AssemblyName System.DirectoryServices.AccountManagement}
        Catch {Write-Error $Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage}
    }

    Process {

        $ComputerNames = @()

        
        if(-not $ComputerName){
            Write-Verbose "Querying the domain for active machines."
            "Querying the domain for active machines."

            $ComputerNames = [array] ([adsisearcher]'objectCategory=Computer').Findall() | ForEach {$_.properties.cn}

            Write-Verbose "Retrived $($ComputerNames.Length) systems from the domain."
        }
        else {
            $ComputerNames = @($ComputerName)
        }

        foreach ($Computer in $ComputerNames){     

            Try {
                
                Write-Verbose "Checking: $Computer"

                $up = $true
                if(-not $NoPing){
                    $up = Test-Connection -count 1 -Quiet -ComputerName $Computer 
                }
                if($up){

                    if ($Username.contains("\\")) {
                        
                        $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
                    }
                    else{
                        
                        $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
                    }

                    $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType, $Computer)
                
                    $Valid = $PrincipalContext.ValidateCredentials($Username, $Password).ToString()
                    
                    If ($Valid) {
                        Write-Verbose "SUCCESS: $Username works with $Password on $Computer"

                        $out = new-object psobject
                        $out | add-member Noteproperty 'ComputerName' $Computer
                        $out | add-member Noteproperty 'Username' $Username
                        $out | add-member Noteproperty 'Password' $Password
                        $out
                    }
                
                    Else {
                        Write-Verbose "FAILURE: $Username did not work with $Password on $ComputerName"
                    }
                }
            }

            Catch {Write-Error $($Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage)}
        }
    }
}