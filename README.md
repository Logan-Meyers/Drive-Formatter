# Drive-Formatter

Simple command-line ui (in Powershell) for managing USB drives and formatting as necessary

![Usb Drive icon](USB_Icon.ico)

# Requirements

- A Windows or Mac computer to run this on
- A copy of this repository (downloaded as a zip from GitHub)
- Access to Powershell as Administrator (required for formatting drives)

# How to Use

1. Use Windows Search to search for "Powershell"
2. Right click the result and Run As Administrator
3. Download this repository's contents from GitHub:
    - Either go the website [https://github.com/Logan-Meyers/Drive-Formatter](https://github.com/Logan-Meyers/Drive-Formatter) and use Code -> Download ZIP
    - Or click this direct download link: [https://github.com/Logan-Meyers/Drive-Formatter/archive/refs/heads/main.zip](https://github.com/Logan-Meyers/Drive-Formatter/archive/refs/heads/main.zip)
4. Find the downloaded zip in your files and extract them (if needed)
5. Now, with Powershell and the folder open side by side, click and drag `DriveFormatter.ps1` into the Powershell window
6. In the Powershell Window, press enter and the program's instructions to manage your drives as needed.

# Functionality

Top-level (user) functionality:
- Cross-platform (may be run on a Windows machine or Mac)
- Check formatting: Checks if a given USB drive if formatted correctly for use in a CNC machine
- Format a USB Drive properly with a custom name
- Can rename a partition

Low-level (script) functionality
- Uses the Windows Powershell module Storage or Mac's inbuilt `diskutil` tools to manage drive partitions
- can create a partition of 2GB on any drive, but no less or more (hard-coded)

# Future Plans

- Allow custom 1st partition size (Up to 2GB, free space available, or user-specified)
- Allow creating a partition of the remaining size for other use
- Allow copying all files off of partition before formatting, and move back after formatting
- Batch format drives?
- Better progress output
- Better Listing of drives (include partition names found on that drive)
- Better UI flow
- Better Error handling
- Abstract diskutil and Storage functions used often
- Consistent UI feel and UX format
