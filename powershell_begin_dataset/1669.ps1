











function Get-Lines ([string]$file) {
    begin {
        $file = (Resolve-Path $file).ToString()

        if (!(Test-Path $file)) {
            Throw "File not found: $file"
        }

        try {
            
            $stream = [System.IO.File]::OpenText($file)
        } catch {
            Throw $_
        }
    }

    process {
        while (!$stream.EndOfStream) {
            $stream.ReadLine()
        }
        $stream.Close()
        rv stream
    }
}
