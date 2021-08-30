

class Message {
    [string]$Id                 
    [MessageType]$Type = [MessageType]::Message
    [MessageSubtype]$Subtype = [MessageSubtype]::None    
    [string]$Text               
    [string]$To                 
    [string]$ToName             
    [string]$From               
    [string]$FromName           
    [datetime]$Time             
    [bool]$IsDM                 
    [hashtable]$Options         
    [pscustomobject]$RawMessage 

    [Message]Clone () {
        $newMsg = [Message]::New()
        foreach ($prop in ($this | Get-Member -MemberType Property)) {
            if ('Clone' -in ($this.$($prop.Name) | Get-Member -MemberType Method -ErrorAction Ignore).Name) {
                $newMsg.$($prop.Name) = $this.$($prop.Name).Clone()
            } else {
                $newMsg.$($prop.Name) = $this.$($prop.Name)
            }
        }
        return $newMsg
    }

    [hashtable] ToHash() {
        return @{
            Id         = $this.Id
            Type       = $this.Type.ToString()
            Subtype    = $this.Subtype.ToString()
            Text       = $this.Text
            To         = $this.To
            ToName     = $this.ToName
            From       = $this.From
            FromName   = $this.FromName
            Time       = $this.Time.ToUniversalTime().ToString('u')
            IsDM       = $this.IsDM
            Options    = $this.Options
            RawMessage = $this.RawMessage
        }
    }

    [string] ToJson() {
        return $this.ToHash() | ConvertTo-Json -Depth 10 -Compress
    }
}
