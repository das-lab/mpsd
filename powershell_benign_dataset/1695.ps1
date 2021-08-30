



filter sortprop {
    $obj = $_
    $props = $obj | gm -m *property | % {$_.name} | sort
    $obj | select $props
}
