

Configuration SQLStandalone
{
    param(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$SetupCredential,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('sxs$')]
		[string]$WindowsServerSource,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServerInstallSource,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$SysAdminAccount
    )
    
    Import-DscResource -Module xSQLServer

    
    Node $AllNodes.NodeName
    {
        
        WindowsFeature "NET-Framework-Core"
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
            Source = $WindowsServerSource
        }

        
        
        xSqlServerSetup 'SqlServerSetup'
        {
            DependsOn = "[WindowsFeature]NET-Framework-Core"
            SourcePath = $SqlServerInstallSource
            SetupCredential = $SetupCredential
            InstanceName = 'MSSQLSERVER'
            Features = 'SQLENGINE,FULLTEXT,RS,AS,IS'
            SQLSysAdminAccounts = $SysAdminAccount
        }

        
        xSqlServerFirewall 'SqlFirewall'
        {
            DependsOn = '[xSqlServerSetup]SqlServerSetup'
            SourcePath = $SqlServerInstallSource
            InstanceName = 'MSSQLSERVER'
            Features = 'SQLENGINE,FULLTEXT,RS,AS,IS'
        }
    }
}

if (-not (Get-Module -Name xSqlServer -ListAvailable)) {
	Install-Module -Name 'xSqlServer' -Confirm:$false
}

SQLStandAlone -SetupCredential (Get-Credential) -WindowServerSource '' -SqlServerInstallSource '' -SysAdminAccount '' -ConfigurationData '.\ConfiguraitonData.psd1'
Start-DscConfiguration –Wait –Force –Path '.\SQLStandalone' –Verbose