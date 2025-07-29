### This function lists all drives other than 0, and asks for which drive the user would like to manage
### For example, this might return 1
function Get-WantedDrive($actionPrompt) {
    if ($IsMacOS) {
        Get-MacWantedDrive
    } else {
        if ($IsLinux) {
            Write-Host "Linux not supported yet!"
        } else {
            Get-WinWantedDrive
        }
    }
}

### This function handles checking a drive
### This will check the formatting of the drive and give a success value
### This might return 0 (fail) or 1 (success)
function Show-CheckMenu {
    if ($IsMacOS) {
        Show-MacCheckMenu
    } else {
        if ($IsLinux) {
            Write-Host "Linux not supported yet!"
        } else {
            Show-WinCheckMenu
        }
    }
}

### This function handles formatting a drive
### This will format the drive, resulting in loss of data
### This will return either a success value, either 0 (fail) or 1 (success)
function Show-FormatMenu {
    if ($IsMacOS) {
        Show-MacFormatMenu
    } else {
        if ($IsLinux) {
            Write-Host "Linux not supported yet!"
        } else {
            Show-WinFormatMenu
        }
    }
}

### This function handles renaming a partition
### This will ask for a drive, a new partition name, and renames the 1st partition
function Show-RenameMenu {
    if ($IsMacOS) {
        Show-MacRenameMenu
    } else {
        if ($IsLinux) {
            Write-Host "Linux not supported yet!"
        } else {
            Show-WinRenameMenu
        }
    }
}