

class Person {

    [string]$Id

    
    [string]$ClientId

    [string]$Nickname
    [string]$FirstName
    [string]$LastName
    [string]$FullName

    [string]ToString() {
        return "$($this.id):$($this.NickName):$($this.FullName)"
    }

    [hashtable]ToHash() {
        $hash = @{}
        (Get-Member -InputObject $this -MemberType Property).foreach({
            $hash.Add($_.Name, $this.($_.name))
        })
        return $hash
    }
}
