
function New-Permission {
    
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Plugin,

        [parameter(Position = 2)]
        [string]$Description
    )

    if ($pluginVersions = $Bot.PluginManager.Plugins[$Plugin]) {

        
        $latestPluginVersion = @($pluginVersions.Keys | Sort-Object -Descending)[0]

        
        $permission = [Permission]::New($Name, $Plugin)
        $permission.Adhoc = $true
        if ($PSBoundParameters.ContainsKey('Description')) {
            $permission.Description = $Description
        }

        if ($pv = $pluginVersions[$latestPluginVersion]) {
            
            $Bot.RoleManager.AddPermission($permission)
            $pv.AddPermission($permission)
            $Bot.PluginManager.Savestate()

            if ($p = $Bot.RoleManager.GetPermission($permission.ToString())) {
                New-PoshBotCardResponse -Type Normal -Text "Permission [$($permission.ToString())] created." -ThumbnailUrl $thumb.success
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Permission [$($permission.ToString())] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Unable to get latest version of plugin [$Plugin]."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
    }
}
