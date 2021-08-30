function Get-LocalAdministratorBuiltin
{


    [CmdletBinding()]
    param (
        [Parameter()]
        $ComputerName = $env:computername
    )
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            Try
            {
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement
                $PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $Computer)
                $UserPrincipal = New-Object -TypeName System.DirectoryServices.AccountManagement.UserPrincipal($PrincipalContext)
                $Searcher = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalSearcher
                $Searcher.QueryFilter = $UserPrincipal
                $Searcher.FindAll() | Where-Object { $_.Sid -Like "*-500" }
            }
            Catch
            {
                Write-Warning -Message "$($_.Exception.Message)"
            }
        }
    }
}