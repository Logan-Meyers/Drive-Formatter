### This function lists all drives other than 0, and asks for which drive the user would like to manage
### For example, this might return 1
function Get-WantedDrive($actionPrompt) {
    # list of disks
    $disks = Get-Disk | Where-Object { $_.Number -ne 0 }
    
    # count disks
    $maxSelection = 1

    foreach ($disk in $disks) { $maxSelection += 1 }

    # clear screen and init selection variables
    $selected = 1

    Clear-Host

    while ($true) {
        Clear-Host

        Write-Host "Use arrow keys to change which drive you'd like to $actionPrompt"
        Write-Host "Press enter to select the drive and continue"
        Write-Host "Press escape to go back to the main menu"
        Write-Host ""

        $cur = 0
        foreach ($disk in $disks) {
            $cur += 1

            Write-Host "$(if ($cur -eq $selected) { '> ' } else { '  ' })Drive $($disk.Number) | $($disk.FriendlyName) | $([math]::round($disk.Size / 1GB, 2)) GB)"
        }

        Write-Host "$(if ($selected -eq $maxSelection) { '> ' } else { '  ' })Re-scan for drives"
        
        # Get input from user
        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($selected -gt 1) {
                    $selected -= 1
                }
            }
            'DownArrow' {
                if ($selected -lt $maxSelection) {
                    $selected += 1
                }
            }
            'Enter' {
                if ($selected -eq $maxSelection) {
                    $disks = Get-Disk | Where-Object { $_.Number -ne 0 }
                    $maxSelection = 1
                    foreach ($disk in $disks) { $maxSelection += 1 }
                    $selected = $maxSelection
                } else {
                    return $selected
                }
            }
            'Escape' {
                return $null
            }
        }
    }

    $selected
}

### This function handles checking a drive
### This will check the formatting of the drive and give a success value
### This might return 0 (fail) or 1 (success)
function Show-CheckMenu {
    $chosenDrive = Get-WantedDrive("check")

    # exit if no valid drive selected (< 1 or null)
    if (-not $chosenDrive) {
        return
    }

    Clear-Host

    # Get the first partition of the chosen drive
    $firstPartition = Get-Partition -DiskNumber $chosenDrive | Select-Object -First 1

    # Check if the partition exists
    if ($firstPartition) {
        # Get the partition type and offset
        $partitionType = $firstPartition.Type  # For GPT partitions
        $partitionOffset = $firstPartition.Offset  # Offset in bytes

        # Check for FAT type (0E) and offset of 1024
        if ($partitionType -eq 'XINT13' -and $partitionOffset -eq 1048576) {
            Write-Host "Formatted correctly!"
        } else {
            Write-Host "Not formatted correctly!"
            Write-Host "You'll need to format this drive from the main menu."
            Write-Host ""

            # debugging / additional info
            if ($partitionType -ne "XINT13") {Write-Host "- Wrong partition type: $partitionType"}
            if ($partitionOffset -ne 1048576) {Write-Host "- Wrong Offset: $partitionOffset"}
        }
    } else {
        Write-Host "No partitions found on the selected drive."
    }

    Write-Host ""
    Write-Host "Press enter to continue back to main menu..."
    Read-Colonless
    Clear-Host
}

### This function handles formatting a drive
### This will format the drive, resulting in loss of data
### This will return either a success value, either 0 (fail) or 1 (success)
function Show-FormatMenu {
    $chosenDrive = Get-WantedDrive("format")

    if (-not $chosenDrive) {
        Clear-Host
        return
    }

    Clear-Host

    $disk = Get-Disk | Where-Object { $_.Number -eq $chosenDrive}

    if (-not $disk) {
        Clear-Host
        Write-Host "That drive does not exist anymore! Try again."
        Write-Host ""
        return
    }

    # Confirm user wants to format
    Write-Host "You have selected Drive $($chosenDrive) - $($disk.FriendlyName)"
    Write-Host "Are you sure you want to format this disk?"
    Write-Host "This will DELETE ALL DATA. Backup important files if needed."
    Write-Host ""
    Write-Host "(y/N): " -NoNewLine
    $confirmation = [System.Console]::ReadKey($true)

    if ($confirmation.Key -ne 'y') {
        Clear-Host
        Write-Host "Formatting Cancelled."
        Write-Host ""
        return
    }

    Clear-Host

    Write-Host "Please enter a name, for what you'd like to call this drive"
    Write-Host "(Less than or equal to 8 characters)"
    Write-Host "(Will automatically be converted to all caps)"
    Write-Host ""
    Write-Host "> " -NoNewline
    $name = Read-Colonless

    # 1. Clear disk
    Clear-Disk -Number $chosenDrive -RemoveData -Confirm:$false

    # 2. Initialize with MBR
    Set-Disk -Number $chosenDrive -PartitionStyle MBR

    # 3. Create a new partition with whole disk
    $newPartition = New-Partition -DiskNumber $chosenDrive -Size 2GB -Offset 1MB -AssignDriveLetter

    # 4. Format partition - TEMP DEBUGGING
    Format-Volume -DriveLetter $newPartition.DriveLetter -FileSystem FAT -NewFileSystemLabel $name -Confirm:$false

    # 5. Open in explorer
    Start-Process "explorer.exe" "$($newPartition.DriveLetter):\"

    Clear-Host
    Write-Host "Successfully formatted drive! It is all ready to be used with the CNC Machines."
}

### This function handles renaming a partition
### This will ask for a drive, a new partition name, and renames the 1st partition
function Show-RenameMenu {
    Write-Host "Windows not supported for this function!"
}