Function Update-ServiceNowNumber {
    

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        
        [Parameter(Mandatory=$true)]
        [string]$Number,

        
        [Parameter(Mandatory=$true)]
        [string]$Table,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection,

        
        [parameter(Mandatory=$false)]
        [hashtable]$Values,

        
        [parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    begin {}
    process {
        Try {
            
            $getServiceNowTableEntry = @{
                Table         = $Table
                MatchExact    = @{number = $number}
                ErrorAction   = 'Stop'
            }

            
            Switch ($PSCmdlet.ParameterSetName) {
                'SpecifyConnectionFields' {
                    $getServiceNowTableEntry.Add('ServiceNowCredential',$Credential)
                    $getServiceNowTableEntry.Add('ServiceNowURL',$ServiceNowURL)
                    $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
                    break
                }
                'UseConnectionObject' {
                    $getServiceNowTableEntry.Add('Connection',$Connection)
                    $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
                    $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
                    $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
                    break
                }
                Default {
                    If ((Test-ServiceNowAuthIsSet)) {
                        $Credential = $Global:ServiceNowCredentials
                        $ServiceNowURL = $Global:ServiceNowRESTURL
                    }
                    Else {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            
            $SysID = Get-ServiceNowTableEntry @getServiceNowTableEntry | Select-Object -Expand sys_id

            
            $Body = $Values | ConvertTo-Json
            $utf8Bytes = [System.Text.Encoding]::Utf8.GetBytes($Body)

            
            $Uri = $ServiceNowURL + "/table/$Table/$SysID"
            $invokeRestMethodSplat = @{
                Uri         = $uri
                Method      = 'Patch'
                Credential  = $Credential
                Body        = $utf8Bytes
                ContentType = 'application/json'
            }

            If ($PSCmdlet.ShouldProcess("$Table/$SysID",$MyInvocation.MyCommand)) {
                
                $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

                
                If ($PSBoundParameters.ContainsKey('Passthru')) {
                    $Result
                }
            }
        }
        Catch {
            Write-Error $PSItem
        }
    }
    end {}
}
