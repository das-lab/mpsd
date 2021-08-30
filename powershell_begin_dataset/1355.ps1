
function Set-CRegistryKeyValue
{
    
    [CmdletBinding(SupportsShouldPRocess=$true,DefaultParameterSetName='String')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true,ParameterSetName='String')]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        
        $String,
        
        [Parameter(ParameterSetName='String')]
        [Switch]
        
        $Expand,
        
        [Parameter(Mandatory=$true,ParameterSetName='Binary')]
        [byte[]]
        
        $Binary,
        
        [Parameter(Mandatory=$true,ParameterSetName='DWord')]
        [int]
        
        $DWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='DWordAsUnsignedInt')]
        [uint32]
        
        $UDWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='QWord')]
        [long]
        
        $QWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='QWordAsUnsignedInt')]
        [uint64]
        
        $UQWord,
        
        [Parameter(Mandatory=$true,ParameterSetName='MultiString')]
        [string[]]
        
        $Strings,
        
        [Switch]
        
        $Force,
        
        [Parameter(DontShow=$true)]
        [Switch]
        
        $Quiet
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSBoundParameters.ContainsKey('Quiet') )
    {
        Write-Warning ('Set-CRegistryKeyValue''s -Quiet switch is obsolete and will be removed in a future version of Carbon. Please remove usages.')
    }

    $value = $null
    $type = $pscmdlet.ParameterSetName
    switch -Exact ( $pscmdlet.ParameterSetName )
    {
        'String' 
        { 
            $value = $String 
            if( $Expand )
            {
                $type = 'ExpandString'
            }
        }
        'Binary' { $value = $Binary }
        'DWord' { $value = $DWord }
        'QWord' { $value = $QWord }
        'DWordAsUnsignedInt' 
        { 
            $value = $UDWord 
            $type = 'DWord'
        }
        'QWordAsUnsignedInt' 
        { 
            $value = $UQWord 
            $type = 'QWord'
        }
        'MultiString' { $value = $Strings }
    }
    
    Install-CRegistryKey -Path $Path
    
    if( $Force )
    {
        Remove-CRegistryKeyValue -Path $Path -Name $Name
    }

    if( Test-CRegistryKeyValue -Path $Path -Name $Name )
    {
        $currentValue = Get-CRegistryKeyValue -Path $Path -Name $Name
        if( $currentValue -ne $value )
        {
            Write-Verbose -Message ("[{0}@{1}] {2} -> {3}'" -f $Path,$Name,$currentValue,$value)
            Set-ItemProperty -Path $Path -Name $Name -Value $value
        }
    }
    else
    {
        Write-Verbose -Message ("[{0}@{1}]  -> {2}'" -f $Path,$Name,$value)
        $null = New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType $type
    }
}

