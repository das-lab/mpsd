
function Remove-MrUserVariable {



    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if ($StartupVars) {
        $UserVars = Get-Variable -Exclude $StartupVars -Scope Global
        
        foreach ($var in $UserVars){
            try {
                Remove-Variable -Name $var.Name -Force -Scope Global -ErrorAction Stop
                Write-Verbose -Message "Variable '$($var.Name)' has been successfully removed."
            }
            catch {
                Write-Warning -Message "An error has occured. Error Details: $($_.Exception.Message)"
            }            
            
        }
        
    }
    else {
        Write-Warning -Message '$StartupVars has not been added to your PowerShell profile'
    }    

}