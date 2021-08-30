function Get-ADDirectReports
{
    
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory)]
        [String[]]$Identity,
        [Switch]$Recurse
    )
    BEGIN
    {
        TRY
        {
            IF (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction 'Stop' -Verbose:$false }
        }
        CATCH
        {
            Write-Verbose -Message "[BEGIN] Something wrong happened"
            Write-Verbose -Message $Error[0].Exception.Message
        }
    }
    PROCESS
    {
        foreach ($Account in $Identity)
        {
            TRY
            {
                IF ($PSBoundParameters['Recurse'])
                {
                    
                    Write-Verbose -Message "[PROCESS] Account: $Account (Recursive)"
                    Get-Aduser -identity $Account -Properties directreports |
                    ForEach-Object -Process {
                        $_.directreports | ForEach-Object -Process {
                            
                            Get-ADUser -Identity $PSItem -Properties * | Select-Object -Property *, @{ Name = "ManagerAccount"; Expression = { (Get-Aduser -identity $psitem.manager).samaccountname } }
                            
                            Get-ADDirectReports -Identity $PSItem -Recurse
                        }
                    }
                }
                IF (-not ($PSBoundParameters['Recurse']))
                {
                    Write-Verbose -Message "[PROCESS] Account: $Account"
                    
                    Get-Aduser -identity $Account -Properties directreports | Select-Object -ExpandProperty directReports |
                    Get-ADUser -Properties * | Select-Object -Property *, @{ Name = "ManagerAccount"; Expression = { (Get-Aduser -identity $psitem.manager).samaccountname } }
                }
            }
            CATCH
            {
                Write-Verbose -Message "[PROCESS] Something wrong happened"
                Write-Verbose -Message $Error[0].Exception.Message
            }
        }
    }
    END
    {
        Remove-Module -Name ActiveDirectory -ErrorAction 'SilentlyContinue' -Verbose:$false | Out-Null
    }
}
