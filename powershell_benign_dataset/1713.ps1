function Update-ServiceNowRequestItem {
    

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([void],[System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param (
        
        [Parameter(mandatory=$true)]
        [string]$SysId,

         
        [Parameter(mandatory=$true)]
        [hashtable]$Values,

         
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection,

        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $updateServiceNowTableEntrySplat = @{
        SysId  = $SysId
        Table  = 'sc_req_item'
        Values = $Values
    }

    
    If ($null -ne $PSBoundParameters.Connection) {
        $updateServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    ElseIf ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
         $updateServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $updateServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    If ($PSCmdlet.ShouldProcess("$Table/$SysID",$MyInvocation.MyCommand)) {
        
        $Result = Update-ServiceNowTableEntry @updateServiceNowTableEntrySplat

        
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Result
        }
    }
}
