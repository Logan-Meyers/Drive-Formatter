### This function lists all drives other than 0, and asks for which drive the user would like to manage
### For example, this might return 1
function Get-WinWantedDrive($actionPrompt) {
    Write-Host "Loading drives..."
    
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

        Write-Host "ARROW KEYS: change which drive you'd like to $actionPrompt"
        Write-Host "ENTER: select the drive and continue"
        Write-Host "ESCAPE: return back to the main menu"
        Write-Host ""

        $cur = 0
        foreach ($disk in $disks) {
            $cur += 1

            $shortDesc = "Drive $($disk.Number) | $($disk.FriendlyName): $([math]::round($disk.Size / 1GB, 2)) GB"
            Write-Host "$(if ($cur -eq $selected) { '> ' } else { '  ' })$shortDesc"
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
function Show-WinCheckMenu {
    $chosenDrive = Get-WantedDrive("check")

    # exit if no valid drive selected (< 1 or null)
    if (-not $chosenDrive) {
        return
    }

    Clear-Host

    # Get the first partition of the chosen drive
    $firstPartition = Get-Partition -DiskNumber $chosenDrive | Select-Object -First 1

    # debugging ntfs
    # Write-Host $firstPartition

    # Exit if no partitions on the drive (no first partition)
    if (-not $firstPartition) {
        Write-Host "The USB Drive has no partitions! You'll need to format it."
        Return 0
    }

    # Get the partition type and offset
    $partitionType = $firstPartition.Type  # For GPT partitions
    $partitionOffset = $firstPartition.Offset  # Offset in bytes
    $partitionSize = $firstPartition.Size  # Size in bytes

    $twoGB = 2 * 1024 * 1024 * 1024
    $eightMb = 8 * 1024 * 1024

    $correctlyFormatted = 1

    # Partition type: Either Windows_FAT_16 or DOS_FAT_16
    if ($partitionType -ne "XINT13" -and $partitionType -ne "Logical") {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong partition type! ($($firstPartInfo["Partition Type"]))"
    }

    # Offset of 1024
    if ($partitionOffset -ne 1048576) {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong partition offset! ($partitionOffsetBytes)"
    }

    # Size < 2GB and > 8MB
    if ($partitionSize -gt $twoGB -or $partitionSize -lt $eightMB) {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong size! ($diskSizeBytes)"
    }

    # Final results
    if ($correctlyFormatted -gt 0) {
        Write-Host "-- The partition is correctly formatted! --"
    } else {
        Write-Host ""
        Write-Host ">> This drive will need to be formatted! <<"
    }

    Write-Host ""
    Write-Host "Press enter to continue back to main menu..."
    Read-Host
    Clear-Host
}

### This function handles formatting a drive
### This will format the drive, resulting in loss of data
### This will return either a success value, either 0 (fail) or 1 (success)
function Show-WinFormatMenu {
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

    $name = Get-FatPartName

    # 1. Clear disk
    Write-Host "Clearing disk..."
    Clear-Disk -Number $chosenDrive -RemoveData -Confirm:$false

    # 2. Initialize with MBR
    Write-Host "Setting to MBR format..."
    Set-Disk -Number $chosenDrive -PartitionStyle MBR

    # 3. Create a new partition with the calculated size
    Write-Host "Creating partition..."
    $usableSizeBytes = $disk.Size - 1MB
    $maxSizeBytes = 2GB
    $partitionSizeBytes = if ($usableSizeBytes -lt $maxSizeBytes) { $usableSizeBytes } else { $maxSizeBytes }

    $newPartition = New-Partition -DiskNumber $chosenDrive -Size $partitionSizeBytes -Offset 1MB -AssignDriveLetter

    # 4. Format partition - TEMP DEBUGGING
    Write-Host "Formatting partition..."
    Format-Volume -DriveLetter $newPartition.DriveLetter -FileSystem FAT -NewFileSystemLabel $name -Confirm:$false

    # 5. Open in explorer
    Write-Host "Opening in Explorer..."
    Start-Process "explorer.exe" "$($newPartition.DriveLetter):\"

    Clear-Host
    Write-Host "Successfully formatted drive! It is all ready to be used with the CNC Machines."
}

### This function handles renaming a partition
### This will ask for a drive, a new partition name, and renames the 1st partition
function Show-WinRenameMenu {
    $chosenDriveNumber = Get-WantedDrive "rename"

    if (-not $chosenDriveNumber) {
        Clear-Host
        return
    }

    Clear-Host

    # Get the first partition on the chosen disk (lowest partition number)
    $firstPartition = Get-Partition -DiskNumber $chosenDriveNumber | Sort-Object PartitionNumber | Select-Object -First 1

    if (-not $firstPartition) {
        Write-Host "Sorry, there are no partitions on this disk! You'll need to format it first."
        return
    }

    # Get the volume associated with this partition
    $volume = Get-Volume -Partition $firstPartition

    if (-not $volume) {
        Write-Host "No volume found on the first partition. Cannot rename."
        return
    }

    $oldName = $volume.FileSystemLabel

    $newName = Get-FatPartName -partition $chosenDrive -oldName $oldName

    # Rename the volume
    try {
        Set-Volume -DriveLetter $volume.DriveLetter -NewFileSystemLabel $newName -ErrorAction Stop
        Write-Host "Successfully renamed volume from '$oldName' to '$newName'."
    } catch {
        Write-Host "Failed to rename volume: $_"
    }
}