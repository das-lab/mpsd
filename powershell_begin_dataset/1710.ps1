Function Get-ServiceNowAttachmentDetail {
    

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName)]
    Param(
        
        [Parameter(Mandatory=$true)]
        [string]$Number,

        
        [Parameter(Mandatory=$true)]
        [string]$Table,

        
        [parameter(Mandatory=$false)]
        [string[]]$FileName,

        
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
        Try {
            
            $getServiceNowTableEntry = @{
                Table         = $Table
                MatchExact    = @{number = $number}
                ErrorAction   = 'Stop'
            }

            
            Switch ($PSCmdlet.ParameterSetName) {
                'SpecifyConnectionFields' {
                    $getServiceNowTableEntry.Add('Credential', $Credential)
                    $getServiceNowTableEntry.Add('ServiceNowURL', $ServiceNowURL)
                    break
                }
                'UseConnectionObject' {
                    $getServiceNowTableEntry.Add('Connection', $Connection)
                    break
                }
                Default {
                    If (-not (Test-ServiceNowAuthIsSet)) {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            $TableSysID = Get-ServiceNowTableEntry @getServiceNowTableEntry | Select-Object -Expand sys_id

            
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
                    If ((Test-ServiceNowAuthIsSet)) {
                        $Credential = $Global:ServiceNowCredentials
                        $ApiUrl = $Global:ServiceNowRESTURL + '/attachment'
                    }
                    Else {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            
            $Body = @{'sysparm_limit' = 500; 'table_name' = $Table; 'table_sys_id' = $TableSysID}
            $Body.sysparm_query = 'ORDERBYfile_name^ORDERBYDESC'

            
            $Uri = $ApiUrl

            $invokeRestMethodSplat = @{
                Uri         = $Uri
                Body        = $Body
                Credential  = $Credential
                ContentType = 'application/json'
            }
            $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

            
            If ($FileName) {
                $Result = $Result | Where-Object {$PSItem.file_name -match ($FileName -join '|')}
            }

            $Result | Update-ServiceNowDateTimeField
        }
        Catch {
            Write-Error $PSItem
        }
    }
	end {}
}
