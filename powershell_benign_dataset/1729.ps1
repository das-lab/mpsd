function New-ServiceNowChangeRequest {
    

    [CmdletBinding(DefaultParameterSetName, SupportsShouldProcess)]
    Param(
        [parameter(Mandatory = $true)]
        [string]$Caller,

        [parameter(Mandatory = $true)]
        [string]$ShortDescription,

        [parameter(Mandatory = $false)]
        [string]$Description,

        [parameter(Mandatory = $false)]
        [string]$AssignmentGroup,

        [parameter(Mandatory = $false)]
        [string]$Comment,

        [parameter(Mandatory = $false)]
        [string]$Category,

        [parameter(Mandatory = $false)]
        [string]$Subcategory,

        [parameter(Mandatory = $false)]
        [string]$ConfigurationItem,

        [parameter(Mandatory = $false)]
        [hashtable]$CustomFields,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection,

        
        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    begin { }
    process {
        Try {
            
            $DefinedChangeRequestParameters = @('AssignmentGroup', 'Caller', 'Category', 'Comment', 'ConfigurationItem', 'Description', 'ShortDescription', 'Subcategory')
            $TableEntryValues = @{ }
            ForEach ($Parameter in $DefinedChangeRequestParameters) {
                If ($null -ne $PSBoundParameters.$Parameter) {
                    
                    $KeyToAdd = Switch ($Parameter) {
                        AssignmentGroup   {'assignment_group'; break}
                        Caller            {'caller_id'; break}
                        Category          {'category'; break}
                        Comment           {'comments'; break}
                        ConfigurationItem {'cmdb_ci'; break}
                        Description       {'description'; break}
                        ShortDescription  {'short_description'; break}
                        Subcategory       {'subcategory'; break}
                    }
                    $TableEntryValues.Add($KeyToAdd, $PSBoundParameters.$Parameter)
                }
            }

            
            If ($null -ne $PSBoundParameters.CustomFields) {
                $DuplicateTableEntryValues = ForEach ($Key in $CustomFields.Keys) {
                    If (($TableEntryValues.ContainsKey($Key) -eq $False)) {
                        
                        $TableEntryValues.Add($Key, $CustomFields[$Key])
                    }
                    Else {
                        
                        $Key
                    }
                }
            }

            
            If ($null -ne $DuplicateTableEntryValues) {
                $DuplicateKeyList = $DuplicateTableEntryValues -join ","
                Throw "Ticket fields may only be used once:  $DuplicateKeyList"
            }

            
            $newServiceNowTableEntrySplat = @{
                Table  = 'change_request'
                Values = $TableEntryValues
            }

            
            If ($null -ne $PSBoundParameters.Connection) {
                $newServiceNowTableEntrySplat.Add('Connection', $Connection)
            }
            ElseIf ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL) {
                $newServiceNowTableEntrySplat.Add('ServiceNowCredential', $ServiceNowCredential)
                $newServiceNowTableEntrySplat.Add('ServiceNowURL', $ServiceNowURL)
            }

            
            If ($PSCmdlet.ShouldProcess($Uri, $MyInvocation.MyCommand)) {
                $Result = New-ServiceNowTableEntry @newServiceNowTableEntrySplat

                
                If ($PSBoundParameters.ContainsKey('Passthru')) {
                    $Result
                }
            }
        }
        Catch {
            Write-Error $PSItem
        }
    }
    end { }
}
