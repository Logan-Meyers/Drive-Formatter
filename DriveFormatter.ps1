# Import UI functions
. "$PSScriptRoot/Scripts/UI.ps1"

# import the correct functions based on operating system
if ($IsMacOS) {
    . "$PSScriptRoot/Scripts/MacFunctions.ps1"
} else {
    if ($IsLinux) {
        . "$PSScriptRoot/Scripts/LinuxFunctions.ps1"
    } else {
        . "$PSScriptRoot/Scripts/WindowsFunctions.ps1"
    }
}

# Colonless Read function
function Read-Colonless($prompt) {
    Write-Host "$prompt" -NoNewline
    $UserInput = $Host.UI.ReadLine()
    $UserInput
}

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

# run main menu
Show-MainMenu