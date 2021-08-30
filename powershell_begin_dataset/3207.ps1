Function Get-AzureRmVmPublicIP {

    [cmdletbinding()]
    param(
        [string[]]$ResourceGroupName,
        [string[]]$VMName,
        [switch]$IncludeObjects,
        [switch]$VMStatus
    )

    foreach($ResourceGroup in $ResourceGroupName)
    {

        
        
        
        Try
        {
            $AllVMs = @( Get-AzureRMVm -ResourceGroupName $ResourceGroup -ErrorAction Stop )
        }
        Catch
        {
            Write-Error $_
            Write-Error "Could not extract VMs from resource group '$ResourceGroup'"
            continue
        }
        Try
        {
            $NICS = @( Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -ErrorAction Stop )
        }
        Catch
        {
            Write-Error $_
            Write-Error "Could not extract network interfaces from resource group '$ResourceGroup'"
            continue
        }
        Try
        {
            $PublicIPS = @( Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroup -ErrorAction Stop)
        }
        Catch
        {
            Write-Error $_
            Write-Error "Could not extract public IPs from resource group '$ResourceGroup'"
            continue
        }

        
        $TheseVMs = foreach($VM in $AllVMs)
        {
            if($VMName)
            {
                foreach($Name in $VMName)
                {
                    if($VM.Name -like $Name)
                    {
                        $VM
                    }
                }
            }
            else
            {
                $VM
            }
        }
        $TheseVMs = @( $TheseVMs | Sort Name -Unique )

        
        Foreach($nic in $nics)
        {
            $VMs = $null   
            $VMs = $TheseVMs.Where({$_.Id -eq $nic.virtualmachine.id})
            $PIPS = $null
            $PIPS = $PublicIPS.Where({$_.Id -eq $nic.IpConfigurations.publicipaddress.id})
            foreach($VM in $VMs)
            {
                if($VMStatus)
                {
                    Try
                    {
                        $VMDetail = Get-AzureRMVm -ResourceGroupName $ResourceGroup -Status -Name $VM.Name -ErrorAction stop
                    }
                    Catch
                    {
                        Write-Error $_
                        Write-Error "Could not extract '-Status' details from $($VM.Name) in resource group $ResourceGroup. Falling back to non detailed"
                        $VMDetail = $VM
                    }
                    if(-not $IncludeObjects)
                    {
                        $IncludeObjects = $True
                    }
                }
                else
                {
                    $VMDetail = $VM
                }

                foreach($PIP in $PIPS)
                {
                    
                    $Output = [ordered]@{
                        ResourceGroupName = $ResourceGroup
                        VMName = $VM.Name
                        NICName = $nic.Name
                        PublicIP = $PIP.IpAddress
                    }

                    if($IncludeObjects)
                    {
                        $Output.Add('VM', $VMDetail)
                        $Output.Add('NIC', $NIC)
                        $Output.Add('PIP', $PIP)
                    }

                    [pscustomobject]$Output
                }
            }
        }
    }
}