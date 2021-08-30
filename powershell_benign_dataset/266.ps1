function Connect-ExchangeOnline
{


    param
    (
        [system.string]$ConnectionUri = 'https://ps.outlook.com/powershell/',
        [Parameter(Mandatory)]
        $Credential
    )
    PROCESS
    {
        TRY
        {
            
            if ($Credential.username -notlike '*@*')
            {
                Write-Error 'Must be email format'
                break
            }

            $Splatting = @{
                ConnectionUri = $ConnectionUri
                ConfigurationName = 'microsoft.exchange'
                Authentication = 'Basic'
                AllowRedirection = $true
            }
            IF ($PSBoundParameters['Credential']) { $Splatting.Credential = $Credential }

            
            Import-PSSession -Session (New-pssession @Splatting -ErrorAction Stop) -ErrorAction Stop
        }
        CATCH
        {
            $Error[0]
        }
    }
}