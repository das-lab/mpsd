







function show-object
{


param(
    
    [Parameter(ValueFromPipeline = $true)]
    $InputObject
)

Set-StrictMode -Version 3

Add-Type -Assembly System.Windows.Forms




$rootVariableName = Get-ChildItem variable:\* -Exclude InputObject,Args |
    Where-Object {
        $_.Value -and
        ($_.Value.GetType() -eq $InputObject.GetType()) -and
        ($_.Value.GetHashCode() -eq $InputObject.GetHashCode())
}


$rootVariableName = $rootVariableName| ForEach-Object Name | Select-Object -First 1


if(-not $rootVariableName)
{
    $rootVariableName = "InputObject"
}


function PopulateNode($node, $object)
{
    
    if(-not $object) { return }

    
    
    if([System.Management.Automation.LanguagePrimitives]::GetEnumerator($object))
    {
        
        
        
        $isOnlyEnumerable = $object.GetHashCode() -eq $object[0].GetHashCode()

        
        $count = 0
        foreach($childObjectValue in $object)
        {
            
            
            $newChildNode = New-Object Windows.Forms.TreeNode
            $newChildNode.Text = "$($node.Name)[$count] = $childObjectValue : " +
                $childObjectValue.GetType()

            
            
            
            
            
            if($isOnlyEnumerable)
            {
                $newChildNode.Name = "@"
            }

            $newChildNode.Name += "[$count]"
            $null = $node.Nodes.Add($newChildNode)

            
            
            
            AddPlaceholderIfRequired $newChildNode $childObjectValue

            $count++
        }
    }
    else
    {
        
        
        foreach($child in $object.PSObject.Properties)
        {
            
            
            $childObject = $child.Value
            $childObjectType = $null
            if($childObject)
            {
                $childObjectType = $childObject.GetType()
            }

            
            
            $childNode = New-Object Windows.Forms.TreeNode
            $childNode.Text = $child.Name + " = $childObject : $childObjectType"
            $childNode.Name = $child.Name
            $null = $node.Nodes.Add($childNode)

            
            
            
            AddPlaceholderIfRequired $childNode $childObject
        }
    }
}





function AddPlaceholderIfRequired($node, $object)
{
    if(-not $object) { return }

    if([System.Management.Automation.LanguagePrimitives]::GetEnumerator($object) -or
        @($object.PSObject.Properties))
    {
        $null = $node.Nodes.Add( (New-Object Windows.Forms.TreeNode "...") )
    }
}


function OnAfterSelect
{
    param($Sender, $TreeViewEventArgs)

    
    $nodeSelected = $Sender.SelectedNode

    
    
    $nodePath = GetPathForNode $nodeSelected

    
    
    $resultObject = Invoke-Expression $nodePath
    $outputPane.Text = $nodePath

    
    
    if($resultObject)
    {
        $members = Get-Member -InputObject $resultObject | Out-String
        $outputPane.Text += "`n" + $members
    }
}


function OnBeforeExpand
{
    param($Sender, $TreeViewCancelEventArgs)

    
    $selectedNode = $TreeViewCancelEventArgs.Node

    
    
    if($selectedNode.FirstNode -and
        ($selectedNode.FirstNode.Text -eq "..."))
    {
        $selectedNode.Nodes.Clear()
    }
    else
    {
        return
    }

    
    
    $nodePath = GetPathForNode $selectedNode

    
    
    Invoke-Expression "`$resultObject = $nodePath"

    
    PopulateNode $selectedNode $resultObject
}




function OnKeyPress
{
    param($Sender, $KeyPressEventArgs)

    
    if($KeyPressEventArgs.KeyChar -eq 3)
    {
        $KeyPressEventArgs.Handled = $true

        
        $node = $Sender.SelectedNode
        $nodePath = GetPathForNode $node
        [System.Windows.Forms.Clipboard]::SetText($nodePath)

        $form.Close()
    }
}



function GetPathForNode
{
    param($Node)

    $nodeElements = @()

    
    
    while($Node)
    {
        $nodeElements = ,$Node + $nodeElements
        $Node = $Node.Parent
    }

    
    $nodePath = ""
    foreach($Node in $nodeElements)
    {
        $nodeName = $Node.Name

        
        
        if($nodeName.StartsWith('@'))
        {
            $nodeName = $nodeName.Substring(1)
            $nodePath = "@(" + $nodePath + ")"
        }
        elseif($nodeName.StartsWith('['))
        {
            
            
        }
        elseif($nodePath)
        {
            
            $nodePath += "."
        }

        
        $nodePath += $nodeName
    }

    
    $nodePath
}



$treeView = New-Object Windows.Forms.TreeView
$treeView.Dock = "Top"
$treeView.Height = 500
$treeView.PathSeparator = "."
$treeView.Add_AfterSelect( { OnAfterSelect @args } )
$treeView.Add_BeforeExpand( { OnBeforeExpand @args } )
$treeView.Add_KeyPress( { OnKeyPress @args } )



$outputPane = New-Object System.Windows.Forms.TextBox
$outputPane.Multiline = $true
$outputPane.ScrollBars = "Vertical"
$outputPane.Font = "Consolas"
$outputPane.Dock = "Top"
$outputPane.Height = 300



$root = New-Object Windows.Forms.TreeNode
$root.Text = "$InputObject : " + $InputObject.GetType()
$root.Name = '$' + $rootVariableName
$root.Expand()
$null = $treeView.Nodes.Add($root)



PopulateNode $root $InputObject


$form = New-Object Windows.Forms.Form
$form.Text = "Browsing " + $root.Text
$form.Width = 1000
$form.Height = 800
$form.Controls.Add($outputPane)
$form.Controls.Add($treeView)
$null = $form.ShowDialog()
$form.Dispose()
}