enum DiscordPremiumType {
    
    NitroClassic = 1

    
    Nitro = 2
}

enum DiscordVisibilityType {
    
    None = 0

    
    Everyone = 1
}

class DiscordUser : Person {
    
    [string]$Discriminator

    
    
    [string]$Avatar

    
    [bool]$IsBot

    
    [bool]$IsMfaEnabled

    
    [string]$Locale

    
    [bool]$IsVerified

    
    [string]$Email

    
    
    [int]$Flags

    
    
    [int]$PremiumType
}
