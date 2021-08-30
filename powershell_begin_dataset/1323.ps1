
function ConvertTo-CPropagationFlag
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        
		[Alias('ContainerInheritanceFlags')]
        $ContainerInheritanceFlag
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Flags = [Security.AccessControl.PropagationFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::InheritOnly;
        'Leaves' =                                     $Flags::InheritOnly;
        'ChildContainers' =                           ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ChildLeaves' =                               ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ContainerAndSubContainers' =                  $Flags::None;
        'ContainerAndLeaves' =                         $Flags::None;
        'SubContainersAndLeaves' =                     $Flags::InheritOnly;
        'ContainerAndChildContainers' =                $Flags::NoPropagateInherit;
        'ContainerAndChildLeaves' =                    $Flags::NoPropagateInherit;
        'ContainerAndChildContainersAndChildLeaves' =  $Flags::NoPropagateInherit;
        'ContainerAndSubContainersAndLeaves' =         $Flags::None;
        'ChildContainersAndChildLeaves' =             ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
    }
    $key = $ContainerInheritanceFlag.ToString()
    if( $map.ContainsKey( $key ) )
    {
        return $map[$key]
    }
    
    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlag) 
}

Set-Alias -Name 'ConvertTo-PropagationFlags' -Value 'ConvertTo-CPropagationFlag'

