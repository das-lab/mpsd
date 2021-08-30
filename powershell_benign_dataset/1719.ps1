Function Get-ServiceNowAttachment {
    

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

        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('file_name')]
        [string]$FileName,

        
        [parameter(Mandatory=$false)]
        [ValidateScript({
            Test-Path $_
        })]
        [string]$Destination = $PWD.Path,

        
        [parameter(Mandatory=$false)]
        [switch]$AllowOverwrite,

        
        [parameter(Mandatory=$false)]
        [switch]$AppendNameWithSysID,

        
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

            
            $Uri = $ApiUrl + '/' + $SysID + '/file'

            If ($True -eq $PSBoundParameters.ContainsKey('AppendNameWithSysID')) {
                $FileName = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($FileName),
                $SysID,[io.path]::GetExtension($FileName)
            }
            $OutFile = $Null
            $OutFile = Join-Path $Destination $FileName

            If ((Test-Path $OutFile) -and -not $PSBoundParameters.ContainsKey('AllowOverwrite')) {
                $ThrowMessage = "The file [{0}] already exists.  Please choose a different name, use the -AppendNameWithSysID switch parameter, or use the -AllowOverwrite switch parameter to overwrite the file." -f $OutFile
                Throw $ThrowMessage
            }

            $invokeRestMethodSplat = @{
                Uri         = $Uri
                Credential  = $Credential
                OutFile     = $OutFile
            }

            If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
                Invoke-RestMethod @invokeRestMethodSplat
            }
        }
        Catch {
            Write-Error $PSItem
        }

    }
	end {}
}
