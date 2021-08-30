
function Add-CommandPermission {
    
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidatePattern('^.+:.+')]
        [Alias('Name')]
        [string]$Command,

        [parameter(Mandatory, Position = 1)]
        [ValidatePattern('^.+:.+')]
        [string]$Permission
    )

    if ($c = $Bot.PluginManager.Commands[$Command]) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {

            $c.AddPermission($p)
            $Bot.PluginManager.SaveState()

            New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to command [$Command]." -ThumbnailUrl $thumb.success
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Command [$Command] not found."
    }
}
