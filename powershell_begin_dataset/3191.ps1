Function ConvertTo-FlatObject {
    
    [cmdletbinding()]
    param(

        [parameter( Mandatory = $True,
                    ValueFromPipeline = $True)]
        [PSObject[]]$InputObject,

        [string[]]$Exclude = "",

        [bool]$ExcludeDefault = $True,

        [string[]]$Include = $null,

        [string[]]$Value = $null,

        [int]$MaxDepth = 10
    )
    Begin
    {
        

            
            Function IsIn-Include {
                param($prop)
                if(-not $Include) {$True}
                else {
                    foreach($Inc in $Include)
                    {
                        if($Prop -like $Inc)
                        {
                            $True
                        }
                    }
                }
            }

            
            Function IsIn-Value {
                param($val)
                if(-not $Value) {$True}
                else {
                    foreach($string in $Value)
                    {
                        if($val -like $string)
                        {
                            $True
                        }
                    }
                }
            }

            Function Get-Exclude {
                [cmdletbinding()]
                param($obj)

                
                    if($ExcludeDefault)
                    {
                        Try
                        {
                            $DefaultTypeProps = @( $obj.gettype().GetProperties() | Select -ExpandProperty Name -ErrorAction Stop )
                            if($DefaultTypeProps.count -gt 0)
                            {
                                Write-Verbose "Excluding default properties for $($obj.gettype().Fullname):`n$($DefaultTypeProps | Out-String)"
                            }
                        }
                        Catch
                        {
                            Write-Verbose "Failed to extract properties from $($obj.gettype().Fullname): $_"
                            $DefaultTypeProps = @()
                        }
                    }

                    @( $Exclude + $DefaultTypeProps ) | Select -Unique
            }

            
            Function Recurse-Object {
                [cmdletbinding()]
                param(
                    $Object,
                    [string[]]$path = '$Object',
                    [psobject]$Output,
                    $depth = 0
                )

                
                    Write-Verbose "Working in path $Path at depth $depth"
                    Write-Debug "Recurse Object called with PSBoundParameters:`n$($PSBoundParameters | Out-String)"
                    $Depth++

                
                    $ExcludeProps = @( Get-Exclude $object )

                
                    $Children = $object.psobject.properties | Where {$ExcludeProps -notcontains $_.Name }
                    Write-Debug "Working on properties:`n$($Children | select -ExpandProperty Name | Out-String)"

                
                foreach($Child in @($Children))
                {
                    $ChildName = $Child.Name
                    $ChildValue = $Child.Value

                    Write-Debug "Working on property $ChildName with value $($ChildValue | Out-String)"
                    
                        if($ChildName -match '[^a-zA-Z0-9_]')
                        {
                            $FriendlyChildName = "'$ChildName'"
                        }
                        else
                        {
                            $FriendlyChildName = $ChildName
                        }

                    
                        if((IsIn-Include $ChildName) -and (IsIn-Value $ChildValue) -and $Depth -le $MaxDepth)
                        {
                            $ThisPath = @( $Path + $FriendlyChildName ) -join "."
                            $Output | Add-Member -MemberType NoteProperty -Name $ThisPath -Value $ChildValue
                            Write-Verbose "Adding member '$ThisPath'"
                        }

                    
                        if($ChildValue -eq $null)
                        {
                            Write-Verbose "Skipping NULL $ChildName"
                            continue
                        }

                    
                        if(
                            (
                                $ChildValue.GetType() -eq $Object.GetType() -and
                                $ChildValue -is [datetime]
                            ) -or
                            (
                                $ChildName -eq "SyncRoot" -and
                                -not $ChildValue
                            )
                        )
                        {
                            Write-Verbose "Skipping $ChildName with type $($ChildValue.GetType().fullname)"
                            continue
                        }

                     
                        if (($ChildValue.GetType()).basetype.Name -eq "Array") {
                            $IsArray = $true
                        }
                        else {
                            $IsArray = @($ChildValue).count -gt 1
                        }

                        $count = 0

                    
                        $CurrentPath = @( $Path + $FriendlyChildName ) -join "."

                    
                        $ExcludeProps = @( Get-Exclude $ChildValue )

                    
                        $ChildrensChildren = $ChildValue.psobject.properties | Where {$ExcludeProps -notcontains $_.Name }
                        $HashKeys = if($ChildValue.Keys -notlike $null -and $ChildValue.Values)
                        {
                            $ChildValue.Keys
                        }
                        else
                        {
                            $null
                        }
                        Write-Debug "Found children's children $($ChildrensChildren | select -ExpandProperty Name | Out-String)"

                    
                    if(
                        (@($ChildrensChildren).count -ne 0 -or $HashKeys) -and
                        $Depth -lt $MaxDepth
                    )
                    {
                        
                            if($HashKeys)
                            {
                                Write-Verbose "Working on hashtable $CurrentPath"
                                foreach($key in $HashKeys)
                                {
                                    Write-Verbose "Adding value from hashtable $CurrentPath['$key']"
                                    $Output | Add-Member -MemberType NoteProperty -name "$CurrentPath['$key']" -value $ChildValue["$key"]
                                    $Output = Recurse-Object -Object $ChildValue["$key"] -Path "$CurrentPath['$key']" -Output $Output -depth $depth
                                }
                            }
                        
                            else
                            {
                                if($IsArray)
                                {
                                    foreach($item in @($ChildValue))
                                    {
                                        Write-Verbose "Recursing through array node '$CurrentPath'"
                                        $Output = Recurse-Object -Object $item -Path "$CurrentPath[$count]" -Output $Output -depth $depth
                                        $Count++
                                    }
                                }
                                else
                                {
                                    Write-Verbose "Recursing through node '$CurrentPath'"
                                    $Output = Recurse-Object -Object $ChildValue -Path $CurrentPath -Output $Output -depth $depth
                                }
                            }
                        }
                    }

                $Output
            }

        
    }
    Process
    {
        Foreach($Object in $InputObject)
        {
            
                Recurse-Object -Object $Object -Output $( New-Object -TypeName PSObject )
        }
    }
}
