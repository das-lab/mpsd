
class Room {

    [string]$Id

    
    [string]$Name

    
    [string]$Topic

    
    [bool]$Exists

    
    [bool]$Joined

    [hashtable]$Members = @{}

    Room() {}

    [string]Join() {
        throw 'Must Override Method'
    }

    [string]Leave() {
        throw 'Must Override Method'
    }

    [string]Create() {
        throw 'Must Override Method'
    }

    [string]Destroy() {
        throw 'Must Override Method'
    }

    [string]Invite([string[]]$Invitees) {
        throw 'Must Override Method'
    }
}
