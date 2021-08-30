workflow Use-WorkflowCheckpointSample
{
    Write-Output "Before Checkpoint."
    start-sleep -s 20
	
    
    Checkpoint-Workflow

    
    Write-Output "After Checkpoint."
}