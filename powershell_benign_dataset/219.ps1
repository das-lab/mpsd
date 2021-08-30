function Get-ParentGroup
{

    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory = $true)]
        [String[]]$Name
    )
    BEGIN
    {
        TRY{
            if(-not(Get-Module Activedirectory -ErrorAction Stop)){
                Write-Verbose -Message "[BEGIN] Loading ActiveDirectory Module"
                Import-Module ActiveDirectory -ErrorAction Stop}
        }
        CATCH
        {
            Write-Warning -Message "[BEGIN] An Error occured"
            Write-Warning -Message $error[0].exception.message
        }
    }
    PROCESS
    {
        TRY
        {
            FOREACH ($Obj in $Name)
            {
                
                $ADObject = Get-ADObject -LDAPFilter "(|(anr=$obj)(distinguishedname=$obj))" -Properties memberof -ErrorAction Stop
                IF($ADObject)
                {
                    
                    if ($ADObject.count -gt 1){Write-Warning -Message "More than one object found with the $obj request"}

                    FOREACH ($Account in $ADObject)
                    {
                        Write-Verbose -Message "[PROCESS] $($Account.name)"
                        $Account | Select-Object -ExpandProperty memberof | ForEach-Object -Process {

                            $CurrentObject = Get-Adobject -LDAPFilter "(|(anr=$_)(distinguishedname=$_))" -Properties Samaccountname


                            Write-Output $CurrentObject | Select-Object Name,SamAccountName,ObjectClass, @{L="Child";E={$Account.samaccountname}}

                            Write-Verbose -Message "Inception - $($CurrentObject.distinguishedname)"
                            Get-ParentGroup -OutBuffer $CurrentObject.distinguishedname

                        }
                    }
                }
                ELSE {
                    
                }
            }
        }
        CATCH{
            Write-Warning -Message "[PROCESS] An Error occured"
            Write-Warning -Message $error[0].exception.message }
    }
    END
    {
        Write-Verbose -Message "[END] Get-NestedMember"
    }
}