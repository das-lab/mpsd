function Get-ADGroupMembers {
    	
    [cmdletbinding()]
    Param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
            [string[]]$group = 'Domain Admins',
            
            [bool]$Recurse = $true   
    )

    Begin {
        
            $type = 'System.DirectoryServices.AccountManagement'
            Try{
                Add-Type -AssemblyName $type -ErrorAction Stop
            }
            Catch {
                Throw "Could not load $type`: Confirm .NET 3.5 or later is installed"
                Break
            }

        
        
        
            $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    }

    Process {
        
            foreach($GroupName in $group){
                Try { 
                    $grp = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($ct,$GroupName)
                    
                    
                        if($grp){
                            $grp.GetMembers($Recurse)
                        }
                        else{
                            Write-Warning "Could not find group '$GroupName'"
                        }
                }
                Catch {
                    Write-Error "Could not obtain members for $GroupName`: $_"
                    Continue
                }
            }
    }
    End{
        
            $ct = $grp = $null
    }
}