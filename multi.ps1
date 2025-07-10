# Platform detection
$Is_Windows = $PSVersionTable.PSEdition -eq 'Desktop' -or $env:OS -eq "Windows_NT"
$Is_MacOS = $env:OSTYPE -like "*darwin*" -or $env:MACHTYPE -like "*apple*"

# ---------- Cross-Platform Disk Utilities ----------

function Get-PlatformDisks {
    if ($Is_Windows) {
        Import-Module Storage
        return Get-Disk | Where-Object { $_.Number -ne 0 }
    } elseif ($Is_MacOS) {
        $output = & diskutil list
        return $output
    }
}

function Format-DriveToFAT16 {
    param (
        [Parameter(Mandatory=$true)][int]$DiskNumber
    )

    if ($Is_Windows) {
        # Windows formatting
        Clear-Disk -Number $DiskNumber -RemoveData -Confirm:$false
        Set-Disk -Number $DiskNumber -PartitionStyle MBR
        $part = New-Partition -DiskNumber $DiskNumber -UseMaximumSize -Offset 1MB -AssignDriveLetter
        Format-Volume -DriveLetter $part.DriveLetter -FileSystem FAT -NewFileSystemLabel "NEWDRIVE" -Confirm:$false
        Start-Process "explorer.exe" "$($part.DriveLetter):\"
    } elseif ($Is_MacOS) {
        # WARNING: macOS identifies disks like disk2, disk3, not numbered like Windows
        $diskId = "disk$DiskNumber"

        # Erase disk with MBR, FAT16, label NEWDRIVE
        # The syntax is:
        # diskutil eraseDisk <format> <name> <scheme> <disk>
        # FAT16 format is "MS-DOS FAT16", MBR scheme is "MBR"
        & diskutil eraseDisk "MS-DOS FAT16" NEWDRIVE MBR /dev/$diskId
    }
}

function Check-PartitionFormat {
    param (
        [Parameter(Mandatory=$true)][int]$DiskNumber
    )

    if ($Is_Windows) {
        $partition = Get-Partition -DiskNumber $DiskNumber | Select-Object -First 1
        if (-not $partition) {
            Write-Host "No partition found."
            return
        }

        $type = $partition.Type
        $offset = $partition.Offset

        if ($type -eq 'XINT13' -and $offset -eq 1048576) {
            Write-Host "Formatted correctly (FAT16, 1MB offset)"
        } else {
            Write-Host "Incorrect format:"
            Write-Host "- Partition Type: $type"
            Write-Host "- Offset: $offset"
        }
    } elseif ($Is_MacOS) {
        $diskId = "disk$DiskNumber"
        $info = & diskutil info /dev/$diskId

        if ($info -match "File System:.*MS-DOS FAT16") {
            Write-Host "File system is FAT16"
        } else {
            Write-Host "File system is not FAT16"
        }

        if ($info -match "Partition Map Scheme:.*Master Boot Record") {
            Write-Host "Partition scheme is MBR"
        } else {
            Write-Host "Partition scheme is not MBR"
        }

        # macOS doesn't expose partition offset directly via diskutil
        Write-Host "(Note: Offset checking is not easily available on macOS)"
    }
}

# ---------- Shared UI and Menu Logic ----------

function Read-Colonless($prompt) {
    Write-Host "$prompt" -NoNewline
    return $Host.UI.ReadLine()
}

function Show-CheckMenu {
    $input = Read-Colonless "Enter disk number to check (e.g., 1 or 2): "
    if (-not $input) { return }
    [int]$diskNum = [int]$input
    Check-PartitionFormat -DiskNumber $diskNum
    Read-Colonless "Press Enter to return to menu..."
    Clear-Host
}

function Show-FormatMenu {
    $input = Read-Colonless "Enter disk number to FORMAT (this will DELETE ALL DATA): "
    if (-not $input) { return }
    [int]$diskNum = [int]$input

    Write-Host "Are you sure? (y/N): " -NoNewline
    $confirm = [System.Console]::ReadKey($true)
    if ($confirm.KeyChar -ne 'y') {
        Write-Host "`nCancelled."
        return
    }

    Format-DriveToFAT16 -DiskNumber $diskNum
    Write-Host "`nDrive formatted."
    Read-Colonless "Press Enter to return to menu..."
    Clear-Host
}

function Show-ListDrives {
    $drives = Get-PlatformDisks
    Write-Host "Detected drives:"
    if ($Is_Windows) {
        foreach ($disk in $drives) {
            Write-Host "Disk $($disk.Number): $($disk.FriendlyName), Size: $([math]::Round($disk.Size/1GB,2)) GB"
        }
    } elseif ($Is_MacOS) {
        Write-Host $drives
    }
    Write-Host ""
    Read-Colonless "Press Enter to continue..."
    Clear-Host
}

function Show-MainMenu {
    do {
        Write-Host "Cross-Platform Disk Formatter"
        Write-Host "1. List Drives"
        Write-Host "2. Check Partition Format"
        Write-Host "3. Format Drive to FAT16"
        Write-Host "4. Exit"
        Write-Host ""
        Write-Host "Enter your choice (1-4): " -NoNewline
        $choice = [System.Console]::ReadKey($true)

        Clear-Host

        switch ($choice.KeyChar) {
            '1' { Show-ListDrives }
            '2' { Show-CheckMenu }
            '3' { Show-FormatMenu }
            '4' { Exit }
            default { Write-Host "Invalid option." }
        }
    } while ($true)
}

Show-MainMenu
