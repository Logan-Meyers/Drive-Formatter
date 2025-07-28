### This function lists all drives external and physical, and asks for which drive the user wants to manage
### For example, this might return /dev/disk3
function Get-WantedDrive($actionPrompt) {
    function Get-ExternalDisks {
        $diskList = diskutil list | Out-String
        $blocks = $diskList -split "(/dev/disk\d+)" | Where-Object { $_ -match "^/dev/disk\d+" }
        $disks = @()

        foreach ($block in $blocks) {
            if ($block -match "^(/dev/disk\d+)") {
                $diskId = $matches[1]

                # Get info for this disk
                $info = diskutil info $diskId

                # Parse the relevant information manually
                $infoDict = @{}
                $info.Split("`n") | ForEach-Object {
                    $line = $_.Trim()
                    if ($line -match "^(.+?):\s*(.+)$") {
                        $key = $matches[1].Trim()
                        $value = $matches[2].Trim()
                        $infoDict[$key] = $value
                    }
                }

                # Only keep external drives
                if ($infoDict['Device Location'] -eq 'External') {
                    # Simplify size: capture only the number and unit (e.g., "2.0 GB")
                    $size = $infoDict['Disk Size'] -replace '\s+\(\S*\)', ''
                    $disks += [PSCustomObject]@{
                        Id = $diskId
                        Description = "Drive $diskId | $size"
                    }
                }
            }
        }
        return $disks
    }

    Write-Host "Loading drives..."

    # list of disks
    $disks = Get-ExternalDisks
    
    # count disks
    $maxSelection = $disks.Count + 1

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

            $shortDesc = $disk.Description -split '\(' | Select-Object -First 1
            $shortDesc = $shortDesc.Trim()
            Write-Host "$(if ($cur -eq $selected) { '> ' } else { '  ' })$($shortDesc)"
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
                    Write-Host ""
                    Write-Host "Re-scanning drives..."
                    
                    $disks = Get-ExternalDisks
                    $maxSelection = $disks.Count + 1
                    $selected = 1
                } else {
                    return $disks[$selected - 1].Id
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
        Clear-Host
        Write-Host "No drive selected, returning to main menu..."
        Write-Host ""
        return
    }

    Clear-Host

    # Get disk partition details using diskutil info
    $diskList = diskutil list $chosenDrive | Out-String

    # Write-Host $diskList

    $partitions = $diskList | Where-Object { $_ -match "disk\ds\d+"} | ForEach-Object {
        if ($_ -match "(disk\ds\d+)") { $matches[1] }
    }

    $partitionCount = $partitions.Count

    # Write-Host "Partitions found: $partitionCount"
    # Write-Host "Partition list: $($partitions -join ', ')"


    # Exit if the drive has no partitions
    if ($partitionCount -lt 1) {
        Write-Host "The USB Drive has no partitions! You'll need to format it."
        Return 0
    }

    # Get info about first partition (disk#s1)
    $firstPartInfo = @{}

    $firstPartKeys = @(
        "Volume Name",
        "Partition Type",
        "Partition Offset",
        "Disk Size"
    )
    
    $firstPartOutput = diskutil info $("$($chosenDrive)s1")

    foreach ($line in $firstPartOutput) {
        foreach ($key in $firstPartKeys) {
            # match lines with keys
            if ($line -match "^\s*$key\s*:\s*(.+)$") {
                $firstPartInfo[$key] = $matches[1].Trim()
            }
        }
    }

    # Function to extract the first number before "Bytes" and convert to int64
    function Get-BytesValue($text) {
        if ($text -match "([\d,]+)\s*Bytes") {
            # Remove commas if any, then convert to int64
            $num = $matches[1] -replace ",", ""
            return [int64]$num
        }
        return $null
    }

    # Extract numeric byte values
    $partitionOffsetBytes = Get-BytesValue $firstPartInfo['Partition Offset']
    $diskSizeBytes = Get-BytesValue $firstPartInfo['Disk Size']

    $twoGB = 2 * 1024 * 1024 * 1024
    $eightMb = 8 * 1024 * 1024

    # Write-Host "Partition Offset (bytes): $partitionOffsetBytes"
    # Write-Host "Disk Size (bytes): $diskSizeBytes"

    $correctlyFormatted = 1

    if ($firstPartInfo["Partition Type"] -ne "Windows_FAT_16" -and $firstPartInfo["Partition Type"] -ne "DOS_FAT_16") {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong partition type! ($($firstPartInfo["Partition Type"]))"
    }

    if ($partitionOffsetBytes -ne 1048576) {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong partition offset! ($partitionOffsetBytes)"
    }

    if ($diskSizeBytes -gt $twoGB -or $diskSizeBytes -lt $eightMB) {
        $correctlyFormatted = 0
        Write-Host "!! The partition has the wrong size! ($diskSizeBytes)"
    }

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
function Show-FormatMenu {
    $chosenDrive = Get-WantedDrive "format"

    if (-not $chosenDrive) {
        Clear-Host
        return
    }

    Clear-Host

    Write-Host "You have selected drive $chosenDrive"
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

    # Unmount the disk first
    Write-Host "Unmounting disk $chosenDrive..."
    diskutil unmountDisk $chosenDrive | Out-Null

    # Erase the disk with MBR partition scheme and create a single FAT16 partition
    # Note: diskutil does not allow specifying offset, but it will create a valid partition
    Write-Host "Erasing and formatting disk $chosenDrive..."
    $sizeGB = 2000
    $sizeArg = "${sizeGB}m"
    diskutil partitionDisk $chosenDrive MBR "MS-DOS FAT16" $name $sizeArg

    Write-Host ""

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to format the disk."
    } else {
        Write-Host "Successfully formatted drive! It is ready to be used with the CNC Machines."

        # Optionally open the volume in Finder
        $mountPoint = "/Volumes/$name"
        if (Test-Path $mountPoint) {
            Start-Process open $mountPoint
        }
    }

    Write-Host ""
    Write-Host "Press enter to continue back to main menu..."
    Read-Host
    Clear-Host
}

### This function handles renaming a partition
### This will ask for a drive, a new partition name, and renames the 1st partition
function Show-RenameMenu {
    $chosenDrive = Get-WantedDrive "rename"

    if (-not $chosenDrive) {
        Clear-Host
        return
    }

    Write-Host $chosenDrive

    $output = diskutil info "$($chosenDrive)s1"
    $oldName = ""

    foreach ($line in $output) {
        if ($line -match "^\s*Volume Name\s*:\s*(.+)$") {
            $oldName = $matches[1].Trim()
            break
        }
    }

    Clear-Host

    $newName = Get-FatPartName -partition $chosenDrive -oldName $oldName

    # Unmount the disk first
    # Write-Host "Unmounting disk $chosenDrive..."
    # diskutil unmountDisk $chosenDrive | Out-Null

    $diskList = diskutil list $chosenDrive | Out-String

    $partitions = $diskList | Where-Object { $_ -match "disk\ds\d+"} | ForEach-Object {
        if ($_ -match "(disk\ds\d+)") { $matches[1] }
    }

    $partitionCount = $partitions.Count

    Write-Host "Partitions found: $partitionCount"
    Write-Host "Partition list: $($partitions -join ', ')"

    if ($partitionCount -lt 1) {
        Write-Host "Sorry, there are no partition on this device! You'll need to format it first."
        return 0
    }

    diskutil rename "$($chosenDrive)s1" $newName
}