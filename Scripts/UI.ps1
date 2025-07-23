### This function asks what to call a FAT partition
### This may return something like "Y-7"
function Get-FatPartName {
    Param (
        [Parameter(Mandatory=$false)] [String]$partition = "",
        [Parameter(Mandatory=$false)] [String]$oldName = ""
    )

    Clear-Host

    # Info about partition selected and old name
    if ($partition) {
        Write-Host "You have selected partition/drive `"$partition`""
    }
    if ($oldName) {
        Write-Host "You are renaming partition `"$oldName`""
    }

    if ($partition -or $oldName) {
        Write-Host ""
    }

    # Prompt for new name with notes
    if ($partition -or $oldName) {
        Write-Host "What would you like to rename the partition to?"
    } else {
        Write-Host "What would you like to name the partition?"
    }
    Write-Host "Note: This will be truncated to 11 characters"
    Write-Host "Note: This will be converted to all uppercase"
    Write-Host ""
    Write-Host "> " -NoNewline

    # Get user input
    $newName = Read-Colonless

    # Process input - truncation
    if ($newName.Length -gt 11) {
        $newName = $newName.Substring(0, 11)
        Write-Host "[INFO]: Name truncated to $newName"
    }

    # Process input - uppercase
    $newName = $newName.ToUpper()

    Write-Host "[INFO]: Name changed case to $newName"

    return $newName
}