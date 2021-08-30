














function Test-AzDtlVMsPerLabPolicy
{
    
    $policy = Set-AzDtlVMsPerLabPolicy -MaxVMs 5 -LabName $labName -ResourceGroupName $rgname
    $readBack = Get-AzDtlVMsPerLabPolicy -LabName $labName -ResourceGroupName $rgname

    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual "5" $x.Threshold
    }
}


function Test-AzDtlVMsPerUserPolicy
{
    $policy = Set-AzDtlVMsPerUserPolicy -MaxVMs 5 -LabName $labName -ResourceGroupName $rgname
    $readBack = Get-AzDtlVMsPerUserPolicy -LabName $labName -ResourceGroupName $rgname
    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual "5" $x.Threshold
    }
}


function Test-AzDtlAllowedVMSizesPolicy
{
    $policy = Set-AzDtlAllowedVMSizesPolicy -Enable -LabName $labName -ResourceGroupName $rgname -VmSizes Standard_A3, Standard_A0
    $readBack = Get-AzDtlAllowedVMSizesPolicy -LabName $labName -ResourceGroupName $rgname
    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual '["Standard_A3","Standard_A0"]' $x.Threshold
    }
}


function Test-AzDtlAutoShutdownPolicy
{
    $policy = Set-AzDtlAutoShutdownPolicy -Time "13:30:00" -LabName $labName -ResourceGroupName $rgname
    $readBack = Get-AzDtlAutoShutdownPolicy -LabName $labName -ResourceGroupName $rgname
    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual "1330" $x.DailyRecurrence.Time
    }
}


function Test-AzDtlAutoStartPolicy
{
    $policy = Set-AzDtlAutoStartPolicy -Time "13:30:00" -LabName $labName -ResourceGroupName $rgname
    $readBack = Get-AzDtlAutoStartPolicy -LabName $labName -ResourceGroupName $rgname
    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual "1330" $x.WeeklyRecurrence.Time
    }

    $policy = Set-AzDtlAutoStartPolicy -Time "13:30:00" -LabName $labName -ResourceGroupName $rgname -Days Monday, Tuesday
    $readBack = Get-AzDtlAutoStartPolicy -LabName $labName -ResourceGroupName $rgname
    Invoke-For-Both $policy $readBack `
    {
        Param($x)
        Assert-AreEqual "Enabled" $x.Status
        Assert-AreEqual "1330" $x.WeeklyRecurrence.Time
        Assert-AreEqualArray ([System.DayOfWeek]::Monday, [System.DayOfWeek]::Tuesday) $x.WeeklyRecurrence.Weekdays
    }
}
