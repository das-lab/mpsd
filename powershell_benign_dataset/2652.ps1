function Set-SQLStartupParameters{
    [cmdletbinding(SupportsShouldProcess=$true)]
    param([parameter(ValueFromPipeline,Mandatory=$true)][string[]] $ServerInstance
        ,[string[]] $StartupParameters
    )
    [bool]$SystemPaths = $false
    BEGIN{
        If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”))
        {
            Write-Warning “Get-SqlStartupParameters must be run with elevated privileges.”
            break
        }

        
        if($StartupParameters.Count -eq 1){
            $StartupParameters = $StartupParameters -split ','
        }

    }

    PROCESS{
        
        foreach($i in $ServerInstance){
            
            $HostName = ($i.Split('\'))[0]
            $InstanceName = ($i.Split('\'))[1]

            
            $ServiceName = if($InstanceName){"MSSQL`$$InstanceName"}else{'MSSQLSERVER'}

            
            $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $HostName
            $wmisvc = $smowmi.Services | Where-Object {$_.Name -eq $ServiceName}

            Write-Verbose "Old Parameters for $i :"
            Write-Verbose $wmisvc.StartupParameters

            
            $oldparams = $wmisvc.StartupParameters -split ';'
            $newparams = @()
            foreach($param in $StartupParameters){
                if($param.Substring(0,2) -match '-d|-e|-l'){
                    $checkpath = 
                    $SystemPaths = $true
                    $newparams += $param
                    $oldparams = $oldparams | Where-Object {$_.Substring(0,2) -ne $param.Substring(0,2)}
                }
                else{
                    $newparams += $param
                }
            }

            $newparams += $oldparams | Where-Object {$_.Substring(0,2) -match '-d|-e|-l'}
            $paramstring = ($newparams | Sort-Object) -join ';'

            Write-Verbose "New Parameters for $i :"
            Write-Verbose $paramstring

            
            if($PSCmdlet.ShouldProcess($i,$paramstring)){
                $wmisvc.StartupParameters = $paramstring
                $wmisvc.Alter()

                Write-Warning "Startup Parameters for $i updated. You will need to restart the service for these changes to take effect."
                If($SystemPaths){Write-Warning "You have changed the system paths for $i. Please make sure the paths are valid before restarting the service"}
            }
        }
    }
}

function Get-SqlStartupParameters{
    [cmdletbinding()]
    param([parameter(ValueFromPipeline,Mandatory=$true)][string[]] $ServerInstance
    )
    BEGIN{
        If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”))
        {
            Write-Warning “Get-SqlStartupParameters must be run with elevated privileges.”
            break
        }
        $return = @()
    }
    PROCESS{
        
        foreach($i in $ServerInstance){
            $HostName = ($i.Split('\'))[0]
            $InstanceName = ($i.Split('\'))[1]

            
            $ServiceName = if($InstanceName){"MSSQL`$$InstanceName"}else{'MSSQLSERVER'}

            
            $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $HostName
            $wmisvc = $smowmi.Services | Where-Object {$_.Name -eq $ServiceName}

            $params = $wmisvc.StartupParameters -split ';'
            $returnhash = [ordered]@{'Instance'= $i;'Parameters'= $params;'ParameterString'=$($wmisvc.StartupParameters)}
            $return += New-Object psobject -Property $returnhash
        }
    }
    END{
        return $return
    }
}