function Get-Member
{

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        [Parameter(ValueFromPipeline=$true, ParameterSetName = 'Default')]
        [Parameter(ValueFromPipeline=$true, ParameterSetName = 'Private')]
        [System.Management.Automation.PSObject]
        $InputObject,

        [Parameter(Position=0, ParameterSetName = 'Default')]
        [Parameter(Position=0, ParameterSetName = 'Private')]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,

        [Parameter(ParameterSetName = 'Default')]
        [Alias('Type')]
        [System.Management.Automation.PSMemberTypes]
        $MemberType,
        
        [Parameter(ParameterSetName = 'Private')]
        [System.Reflection.MemberTypes]
        $PrivateMemberType = [System.Reflection.MemberTypes]::All,

        [Parameter(ParameterSetName = 'Default')]
        [System.Management.Automation.PSMemberViewTypes]
        $View,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Private')]
        [Switch]
        $Static,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Private')]
        [Switch]
        $Force,
        
        [Parameter(ParameterSetName = 'Private')]
        [Switch]
        $Private
    )

    BEGIN
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Get-Member', [System.Management.Automation.CommandTypes]::Cmdlet)
            
            $null = $PSBoundParameters.Add('OutVariable', 'out')
            
            if ($PSBoundParameters['Private']) {
                $null = $PSBoundParameters.Remove('Private')
                $Private = $True
            }
            if ($PSBoundParameters['PrivateMemberType']) {
                $PrivateMemberType = $PSBoundParameters['PrivateMemberType']
                $null = $PSBoundParameters.Remove('PrivateMemberType')
            }
            $scriptCmd = {& $wrappedCmd @PSBoundParameters | Out-Null }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
        }
    }

    PROCESS
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
        }
    }

    END
    {
        try {
            $steppablePipeline.End()
            if ($Private) {
            
                $Object = $PSBoundParameters['InputObject']
                if ($Object.GetType().FullName -ne 'System.RuntimeType') {
                    
                    
                    $Object = $Object.GetType()
                }
                
                if ($PSBoundParameters['Static']) {
                    $Flags = 'Static, NonPublic'
                    
                    
                    $Types = foreach ($Val in [Enum]::GetValues([System.Reflection.MemberTypes])) {
                        $Object.GetMembers($Flags) | Where-Object { ($_.MemberType -eq ($Val.value__ -band $PrivateMemberType)) -and ($Val -ne [System.Reflection.MemberTypes]::All) -and ($_.MemberType -ne 'Constructor') }
                    }
                    
                    
                    
                    $Types += $Object.GetConstructors('Static, NonPublic, Public')
                } else {
                    $Flags = 'Instance, NonPublic'
                    
                    
                    $Types = foreach ($Val in [Enum]::GetValues([System.Reflection.MemberTypes])) {
                        $Object.GetMembers($Flags) | Where-Object { ($_.MemberType -eq ($Val.value__ -band $PrivateMemberType)) -and ($Val -ne [System.Reflection.MemberTypes]::All) -and ($_.MemberType -ne 'Constructor') }
                    }
                    
                    
                    
                    $Types += $Object.GetConstructors('Instance, NonPublic, Public')
                }
                
                
                if (!$Force) {
                    $Types = $Types | Where-Object { !$_.IsSpecialName }
                }
                
                $TypeTable = @{}
                
                
                
                
                $Results = $Types | ForEach-Object {
                
                    $Type = $_
                    
                    switch ($Type.MemberType) {
                        'Constructor' {
                            $Parameters = ($Type.GetParameters() | % {$_.ParameterType.FullName}) -join ', '
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.Name)($($Parameters))"
                        }
                        'Field' {
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.FieldType)"
                        }
                        'Method' {
                            $Parameters = ($Type.GetParameters() | % {$_.ParameterType.FullName}) -join ', '
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.ReturnType) $($Type.Name)($($Parameters))"
                        }
                        'Property' {
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.PropertyType) $($Type.Name) {$(if ($Type.CanRead){'get;'})$(if ($Type.CanWrite){'set;'})}"
                        }
                        'NestedType' {
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.FullName) BaseType=$($Type.BaseType)"
                        }
                        'Event' {
                            $Parameters = ($Type.GetAddMethod().GetParameters() | % {$_.ParameterType.FullName}) -join ', '
                            $Definition = "$(if ($Type.IsStatic){'static '})$($Type.EventHandlerType) $($Type.Name)(System.Object, $($Parameters))"
                        }
                    }
                    
                    
                    $InternalMemberType = @{
                        TypeName = $Type.DeclaringType.FullName
                        Name = $Type.Name
                        MemberType = $Type.MemberType
                        Definition = $Definition
                    }
                    
                    New-Object PSObject -Property $InternalMemberType
                }
                
                
                $Results | ForEach-Object {
                    $TypeTable["$($_.Name)"] += @($_)
                }
                
                $Results = foreach ($Type in $TypeTable.Keys) {
                    $ReturnType = @{
                        TypeName = $TypeTable[$Type][0].TypeName
                        Name = $TypeTable[$Type][0].Name
                        MemberType = $TypeTable[$Type][0].MemberType
                        
                        
                        
                        Definition = ($TypeTable[$Type] | ForEach-Object { $_.Definition }) -join ', '
                    }
                    
                    $MemberDef = New-Object PSObject -Property $ReturnType
                    
                    $MemberDef.PSObject.TypeNames.Insert(0, 'Microsoft.PowerShell.Commands.MemberDefinition')
                    $MemberDef
                }
                
                
                if ($PSBoundParameters['Name']) {
                    $MemberNames = [String[]] $PSBoundParameters['Name']
                    
                    $Tmp = New-Object PSObject[](0)
                    
                    foreach ($MemberName in $MemberNames) {
                        $Tmp += $Results | Where-Object { $_.Name -eq $MemberName }
                    }
                    
                    $Results = $Tmp
                }
                
                
                if ($Results.Count) {
                    $Results | Sort-Object TypeName, MemberType, Name
                }
            } else {
                
                $out | Sort-Object TypeName, MemberType, Name
            }
        } catch {
        }
    }
}

