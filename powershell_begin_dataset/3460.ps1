














function Test-GetDataFactoriesInSubscription
{	
    $dfname1 = Get-DataFactoryName + "df1"
    $dfname2 = Get-DataFactoryName + "df2"
    $rgname1 = Get-ResourceGroupName + "rg1"
    $rgname2 = Get-ResourceGroupName + "rg2"
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname1 -Location $rglocation -Force
    New-AzResourceGroup -Name $rgname2 -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname1 -Name $dfname1 -Location $dflocation -Force
        Set-AzDataFactoryV2 -ResourceGroupName $rgname2 -Name $dfname2 -Location $dflocation -Force
        $fetcheFactories = Get-AzDataFactoryV2

        Assert-NotNull $fetcheFactories
        $foundDf1 = $false
        $foundDf2 = $false
        $fetcheFactories|ForEach-Object {If ($_.DataFactoryName -eq $dfname1) {$foundDf1 = $true} Else {If ($_.DataFactoryName -eq $dfname2) {$foundDf2 = $true}}}
        Assert-True { $foundDf1 }
        Assert-True { $foundDf2 }
    }
    finally
    {
        CleanUp $rgname1 $dfname1
        CleanUp $rgname2 $dfname2
    }
}


function Test-GetNonExistingDataFactory
{	
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force
    
    Assert-ThrowsContains { Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname } "NotFound"   
}


function Test-CreateDataFactory
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $actual = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $expected = Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname

		ValidateFactoryProperties $expected $actual
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-DeleteDataFactoryWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force        
    Remove-AzDataFactoryV2 -InputObject $df -Force
}


function Test-DataFactoryPiping
{	
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

    Get-AzDataFactoryV2 -ResourceGroupName $rgname | Remove-AzDataFactoryV2 -Force

    
    Assert-ThrowsContains { Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname } "NotFound"  
}


function Test-GetFactoryByNameParameterSet
{	
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

    Assert-ThrowsContains { Get-AzDataFactoryV2 -DataFactoryName $dfname } "ResourceGroupName"
}


function Test-UpdateDataFactory
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
		Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $actual = Update-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Tag @{newTag = "NewTagValue"}
        $expected = Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname

		ValidateFactoryProperties $expected $actual
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function ValidateFactoryProperties ($expected, $actual)
{
    Assert-AreEqualObjectProperties $expected $actual
}


function Test-CreateDataFactoryV2WithVSTSRepoConfig
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $actual = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force -AccountName  "an" -RepositoryName "rn" -CollaborationBranch "cb" -RootFolder  "rf" -LastCommitId "lci" -ProjectName "pn" 
        $expected = Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname

		ValidateFactoryProperties $expected $actual
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-CreateDataFactoryV2WithGitHubRepoConfig
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $actual = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force -AccountName  "an" -RepositoryName "rn" -CollaborationBranch "cb" -RootFolder  "rf" -LastCommitId "lci" -HostName "hn" 
        $expected = Get-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname

		ValidateFactoryProperties $expected $actual
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}

