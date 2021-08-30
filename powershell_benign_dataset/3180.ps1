function Test-ForAdmin {

    [cmdletbinding()]
    param(
        [Parameter( 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0
        )][string[]]$username =$env:username

    )
    
    Process{
    
        foreach($user in $username){

            
            if($user -eq $env:username){
                write-verbose "Username parameter value matches username environment variable:  Don't check AD"
        
                $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
                $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
                $prp.IsInRole($adm)
            }

            else{
                
                Write-Verbose "Username parameter value does not match username environment variable:  Check AD"

                
                    $type = 'System.DirectoryServices.AccountManagement'
                    Try{
                        Add-Type -AssemblyName $type -ErrorAction Stop
                    }
                    Catch {
                        Throw "Could not load $type`: Confirm .NET 3.5 or later is installed"
                        Break
                    }

                
                    Try{
                        $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
                        $upn = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($ct,$user) | select -ExpandProperty UserPrincipalName
                    }
                    Catch{
                        Throw "Could not find user '$user': $_"
                    }

                
                    $wid = New-Object System.Security.Principal.WindowsIdentity($upn)

                
                    $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
                    $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
                    $prp.IsInRole($adm)
            }
        }
    }
}