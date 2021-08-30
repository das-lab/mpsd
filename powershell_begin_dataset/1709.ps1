Function Remove-ServiceNowAttachment {
    

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('sys_id')]
        [string]$SysID,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

	begin {}
	process	{
		

        
        Switch ($PSCmdlet.ParameterSetName) {
            'SpecifyConnectionFields' {
                $ApiUrl = 'https://' + $ServiceNowURL + '/api/now/v1/attachment'
                break
            }
            'UseConnectionObject' {
                $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
                $ApiUrl = 'https://' + $Connection.ServiceNowUri + '/api/now/v1/attachment'
                break
            }
            Default {
                If (Test-ServiceNowAuthIsSet) {
                    $Credential = $Global:ServiceNowCredentials
                    $ApiUrl = $Global:ServiceNowRESTURL + '/attachment'
                }
                Else {
                    Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                }
            }
        }

        $Uri = $ApiUrl + '/' + $SysID
        Write-Verbose "URI:  $Uri"

        $invokeRestMethodSplat = @{
            Uri         = $Uri
            Credential  = $Credential
            Method      = 'Delete'
        }

        If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
            (Invoke-RestMethod @invokeRestMethodSplat).Result
        }
    }
	end {}
}
