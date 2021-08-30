function Get-NetFrameworkTypeAccelerator
{

    [Alias('Get-Acceletrator')]
    PARAM ()
    [System.Management.Automation.PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get
}