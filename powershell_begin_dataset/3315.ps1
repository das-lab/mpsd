
function Update-RoleDescription {
    
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Description
    )

    if ($r = $Bot.RoleManager.GetRole($Name)) {
        try {
            $Bot.RoleManager.UpdateRoleDescription($Name, $Description)
            New-PoshBotCardResponse -Type Normal -Text "Role [$Name] description is now [$Description]" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to update role [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
