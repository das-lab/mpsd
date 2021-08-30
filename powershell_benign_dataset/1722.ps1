Function Add-ServiceNowAttachment {
    

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        
        [Parameter(Mandatory=$true)]
        [string]$Number,

        
        [Parameter(Mandatory=$true)]
        [string]$Table,

        
        [parameter(Mandatory=$true)]
        [ValidateScript({
            Test-Path $_
        })]
        [string[]]$File,

        
        [Parameter(Mandatory=$false)]
        [string]$ContentType,

        
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
        [Hashtable]$Connection,

        
        [Parameter()]
        [switch]$PassThru
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

            ForEach ($Object in $File) {
                $FileData = Get-ChildItem $Object -ErrorAction Stop
                If (-not $ContentType) {
                    Add-Type -AssemblyName 'System.Web'
                    $ContentType = [System.Web.MimeMapping]::GetMimeMapping($FileData.FullName)
                }

                
                $Uri = "{0}/file?table_name={1}&table_sys_id={2}&file_name={3}" -f $ApiUrl,$Table,$TableSysID,$FileData.Name

                $invokeRestMethodSplat = @{
                    Uri        = $Uri
                    Headers    = @{'Content-Type' = $ContentType}
                    Method     = 'POST'
                    InFile     = $FileData.FullName
                    Credential = $Credential
                }

                If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
                    $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

                    If ($PassThru) {
                        $Result | Update-ServiceNowDateTimeField
                    }
                }
            }
        }
        Catch {
            Write-Error $PSItem
        }
    }
	end {}
}
