param([ValidateSet('Dev','Stage','QA','Prod')][string] $Environment)


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;



$IspacPath = switch($Environment){
    'Dev'{'C:\TFS2013\Dev\SSIS\TestDev.ispac'}
    'Stage'{'C:\TFS2013\Dev\SSIS\TestStage.ispac'}
    'QA'{'C:\TFS2013\Dev\SSIS\TestQA.ispac'}
    'Prod'{'C:\TFS2013\Dev\SSIS\TestProd.ispac'}
}


$Server = switch($Environment){
    'Dev'{'TestDev'}
    'Stage'{'TestStage'}
    'QA'{'TestQA'}
    'Prod'{'TestProd'}
}


Write-Host "Connecting to server ..."


$sqlConnectionString = "Data Source=$Server ;Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString


$integrationServices = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
$catalog = $integrationServices.Catalogs["SSISDB"]


Write-Host "SSIS folder $FolderName already exists; skipping create"
Write-Host "Deploying " $ProjectName " project ..."
$folder = $catalog.Folders[$FolderName]
$project = $folder.Projects[$ProjectName]



Set-ItemProperty $IspacPath -IsReadOnly $false





[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($IspacPath_TestDev )

$folder.DeployProject($ProjectName, $projectFile)
Write-Host $project.Name "was deployed with"
Write-Host "Description: " $project.Description
Write-Host "ProjectID: " $project.ProjectID
Write-Host "All done."