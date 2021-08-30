function Get-PropertyType {
    
    param (
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$true)]
        [psobject]$InputObject,

        [string[]]$property = $null
    )

    Begin {

        
        Function Get-PropertyOrder {
            
            [cmdletbinding()]
             param(
                [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromRemainingArguments=$false)]
                    [PSObject]$InputObject,

                [validateset("AliasProperty", "CodeProperty", "Property", "NoteProperty", "ScriptProperty",
                    "Properties", "PropertySet", "Method", "CodeMethod", "ScriptMethod", "Methods",
                    "ParameterizedProperty", "MemberSet", "Event", "Dynamic", "All")]
                [string[]]$MemberType = @( "NoteProperty", "Property", "ScriptProperty" ),

                [string[]]$ExcludeProperty = $null
            )

            begin {

                if($PSBoundParameters.ContainsKey('inputObject')) {
                    $firstObject = $InputObject[0]
                }
            }
            process{

                
                $firstObject = $InputObject
            }
            end{

                
                $firstObject.psobject.properties |
                    Where-Object { $memberType -contains $_.memberType } |
                    Select -ExpandProperty Name |
                    Where-Object{ -not $excludeProperty -or $excludeProperty -notcontains $_ }
            }
        } 

        $Output = @{}
    }

    Process {

        
        foreach($obj in $InputObject){
    
            
            $props = @( Get-PropertyOrder -InputObject $obj | Where { -not $Property -or $property -contains $_ } )

            
            foreach($prop in $props){
                   
                
                Try{
                    $type = $obj.$prop.gettype().FullName
                }
                Catch {
                    $type = $null
                }

                
                if(-not $Output.ContainsKey($prop)){

                    
                    $List = New-Object System.Collections.ArrayList
                    [void]$List.Add($type)
                    $Output.Add($prop, $List)
            
                }
                else{
                    if($Output[$prop] -notcontains $type){
                    
                        
                        [void]$output[$prop].Add($type)
                    }
                }
            }
        }
    }
    End {
        
        $Output
    }
}