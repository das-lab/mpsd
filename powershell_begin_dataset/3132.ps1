









function Get-IPv4Subnet
{
    [CmdletBinding(DefaultParameterSetName='CIDR')]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address which is in the subnet')]
        [IPAddress]$IPv4Address,

        [Parameter(
            ParameterSetName='CIDR',
            Position=1,
            Mandatory=$true,
            HelpMessage='CIDR like /24 without "/"')]
        [ValidateRange(0,31)]
        [Int32]$CIDR,

        [Parameter(
            ParameterSetName='Mask',
            Position=1,
            Mandatory=$true,
            Helpmessage='Subnetmask like 255.255.255.0')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else 
            {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"
            }
        })]
        [String]$Mask
    )

    Begin{
   
    }

    Process{
        
        switch($PSCmdlet.ParameterSetName)
        {
            "CIDR" {                          
                $Mask = (Convert-Subnetmask -CIDR $CIDR).Mask            
            }

            "Mask" {
                $CIDR = (Convert-Subnetmask -Mask $Mask).CIDR          
            }              
        }
        
        
        $CIDRAddress = [System.Net.IPAddress]::Parse([System.Convert]::ToUInt64(("1"* $CIDR).PadRight(32, "0"), 2))
    
        
        $NetworkID_bAND = $IPv4Address.Address -band $CIDRAddress.Address

        
        $NetworkID = [System.Net.IPAddress]::Parse([System.BitConverter]::GetBytes([UInt32]$NetworkID_bAND) -join ("."))
        
        
        $HostBits = ('1' * (32 - $CIDR)).PadLeft(32, "0")
        
        
        $AvailableIPs = [Convert]::ToInt64($HostBits,2)

        
        $NetworkID_Int64 = (Convert-IPv4Address -IPv4Address $NetworkID.ToString()).Int64

        
        $FirstIP = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + 1)).IPv4Address)

        
        $LastIP = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + ($AvailableIPs - 1))).IPv4Address)

        
        $Broadcast = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + $AvailableIPs)).IPv4Address)

        
        $AvailableIPs += 1

        
        $Hosts = ($AvailableIPs - 2)
            
        
        $Result = [pscustomobject] @{
            NetworkID = $NetworkID
            FirstIP = $FirstIP
            LastIP = $LastIP
            Broadcast = $Broadcast
            IPs = $AvailableIPs
            Hosts = $Hosts
        }

        
        $Result.PSObject.TypeNames.Insert(0,'Subnet.Information')

        $DefaultDisplaySet = 'NetworkID', 'Broadcast', 'IPs', 'Hosts'

        $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultDisplaySet)

        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)

        $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        
        
        $Result
    }

    End{

    }
}
