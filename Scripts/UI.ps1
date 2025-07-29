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

    Clear-Host

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

# Colonless Read function
function Read-Colonless($prompt) {
    Write-Host "$prompt" -NoNewline
    $UserInput = $Host.UI.ReadLine()
    $UserInput
}

# Main menu
function Show-MainMenu {
    Clear-Host
    do {
        Write-Host "Welcome! Please select an option below by typing a number:"
        Write-Host ""
        Write-Host "1. Check a Drive"
        Write-Host "2. Format a Drive"
        Write-Host "3. Rename a partition"
        Write-Host "4. Exit"
        Write-Host ""
        Write-Host "Enter your choice (1-4): " -NoNewLine
        $choiceKey = [System.Console]::ReadKey($true)

        Clear-Host

        switch ($choiceKey.Key) {
            'D1'     { Show-CheckMenu  }
            '1'      { Show-CheckMenu  }
            'D2'     { Show-FormatMenu }
            '2'      { Show-FormatMenu }
            'D3'     { Show-RenameMenu }
            '3'      { Show-RenameMenu }
            'D4'     { Exit }
            '4'      { Exit }
            'Escape' { Exit }
            default {
                Write-Host "Please choose a number in the range 1-4"
            }
        }
    }  while ($true)
}