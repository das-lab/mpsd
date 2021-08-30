



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesScriptsPath = Get-AllUsersScriptsPath 
    $script:MyDocumentsScriptsPath = Get-CurrentUserScriptsPath 
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery

    Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force

    if($PSEdition -ne 'Core')
    {
        $script:userName = "PSGetUser"
        $password = "Password1"
        $null = net user $script:userName $password /add
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $script:credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $script:userName, $secstr
    }

    $script:assertTimeOutms = 20000
    
    
    $script:TempSavePath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempSavePath -ItemType Directory -Force

    $script:AddedAllUsersInstallPath    = Set-PATHVariableForScriptsInstallLocation -Scope AllUsers
    $script:AddedCurrentUserInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        RemoveItem $script:moduleSourcesFilePath
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force

    if($PSEdition -ne 'Core')
    {
        
        net user $script:UserName /delete | Out-Null
        
        $userProfile = (Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.LocalPath -match $script:UserName})
        if($userProfile)
        {
            RemoveItem $userProfile.LocalPath
        }
    }
    RemoveItem $script:TempSavePath


    if($script:AddedAllUsersInstallPath)
    {
        Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers
    }

    if($script:AddedCurrentUserInstallPath)
    {
        Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
    }
}

$ScriptFileInfoProperties = @{
	Version='1.2.3.4'
	Author='john@fabrikam.com'
	Guid='cb0ec9a8-b1a8-4701-8b85-3e9a8341eba4'
	Description='Test Script Description'
	PrivateData='ScriptControlInfo=1.2.3.4.5abcd'
	CompanyName='Fabrikam'
	Copyright='@R'
	RequiredModules='PowerShellGet'
	ExternalModuleDependencies='PowerShellGet'
	RequiredScripts='Fabrikam-ServerScript2'
	ExternalScriptDependencies='Fabrikam-ServerScript2'
	Tags='Tag1','Tag2'
	ProjectUri='https://www.fabrikam-psprojects.com/'
	LicenseUri='https://www.fabrikam-pslicense.com/'
	IconUri='https://www.fabrikam-psicon.com/'
	ReleaseNotes='Test Script version 1.2.3.4'
}

Describe "Update Existing Script Info" -tag CI {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    }

    
    
    
    
    
    
 
    It "UpdateScriptFileInfo" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -Scope AllUsers
		$Script = Get-InstalledScript -Name $scriptName
		$ScriptFilePath = Join-Path -Path $script.InstalledLocation -ChildPath "$scriptName.ps1"

        Update-ScriptFileInfo -Path $ScriptFilePath @ScriptFileInfoProperties
		$ScriptFileInfo = Test-ScriptFileInfo -Path $ScriptFilePath
		foreach ($Prop in $ScriptFileInfoProperties.Keys)
		{
            $ScriptFileInfo.$Prop | Should be $ScriptFileInfoProperties[$Prop]
		}
    }
}
