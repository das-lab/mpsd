function Connect-Office365
{

    [CmdletBinding()]
    PARAM (

    )
    BEGIN
    {
        TRY
        {
            
            IF (-not (Get-Module -Name MSOnline -ListAvailable))
            {
                Write-Verbose -Message "BEGIN - Import module Azure Active Directory"
                Import-Module -Name MSOnline -ErrorAction Stop -ErrorVariable ErrorBeginIpmoMSOnline
            }

            IF (-not (Get-Module -Name LyncOnlineConnector -ListAvailable))
            {
                Write-Verbose -Message "BEGIN - Import module Lync Online"
                Import-Module -Name LyncOnlineConnector -ErrorAction Stop -ErrorVariable ErrorBeginIpmoLyncOnline
            }
        }
        CATCH
        {
            Write-Warning -Message "BEGIN - Something went wrong!"
            IF ($ErrorBeginIpmoMSOnline)
            {
                Write-Warning -Message "BEGIN - Error while importing MSOnline module"
            }
            IF ($ErrorBeginIpmoLyncOnline)
            {
                Write-Warning -Message "BEGIN - Error while importing LyncOnlineConnector module"
            }

            Write-Warning -Message $error[0].exception.message
        }
    }
    PROCESS
    {
        TRY
        {

            
            Write-Verbose -Message "PROCESS - Ask for Office365 Credential"
            $Credential = Get-Credential -ErrorAction continue -ErrorVariable ErrorCredential -Credential "$env:USERNAME@$env:USERDNSDOMAIN"


            
            Write-Verbose -Message "PROCESS - Connect to Azure Active Directory"
            Connect-MsolService -Credential $Credential

            
            Write-Verbose -Message "PROCESS - Create session to Exchange online"
            $ExchangeURL = "https://ps.outlook.com/powershell/"
            $O365PS = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeURL -Credential $Credential -Authentication Basic -AllowRedirection -ErrorAction Stop -ErrorVariable ErrorConnectExchange

            Write-Verbose -Message "PROCESS - Open session to Exchange online (Prefix: Cloud)"
            Import-PSSession -Session $O365PS –Prefix ExchCloud

            
            Write-Verbose -Message "PROCESS - Create session to Lync online"
            $LyncSession = New-CsOnlineSession –Credential $Credential -ErrorAction Stop -ErrorVariable ErrorConnectExchange
            Import-PSSession -Session $LyncSession -Prefix LyncCloud

            
            
        }
        CATCH
        {
            Write-Warning -Message "PROCESS - Something went wrong!"
            IF ($ErrorCredential)
            {
                Write-Warning -Message "PROCESS - Error while gathering credential"
            }
            IF ($ErrorConnectMSOL)
            {
                Write-Warning -Message "PROCESS - Error while connecting to Azure AD"
            }
            IF ($ErrorConnectExchange)
            {
                Write-Warning -Message "PROCESS - Error while connecting to Exchange Online"
            }
            IF ($ErrorConnectLync)
            {
                Write-Warning -Message "PROCESS - Error while connecting to Lync Online"
            }

            Write-Warning -Message $error[0].exception.message
        }
    }
}
