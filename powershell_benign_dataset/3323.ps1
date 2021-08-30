
function Disable-Plugin {
    
    [PoshBot.BotCommand(
        Aliases = ('dp', 'disableplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Name]) {
            $pv = $null
            if ($p.Keys.Count -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $p.Keys -join ', ' | Out-String
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.DeactivatePlugin($pv.Name, $pv.Version)
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] deactivated. All commands in this plugin are now disabled." -Title 'Plugin deactivated' -ThumbnailUrl $thumb.success
                } catch {
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        return New-PoshBotCardResponse -Type Warning -Text "Sorry, builtin plugins can't be disabled. It's for your own good :)" -Title 'Ya no'
    }
}
