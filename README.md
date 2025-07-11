# Drive-Formatter

Simple command-line ui (in Powershell) for managing USB drives and formatting as necessary

![Usb Drive icon](USB_Icon.ico)

# Requirements

- A Windows computer to run this on
- A copy of this repository (downloaded as a zip from GitHub)
- Access to Powershell as Administrator (required for formatting drives)

# How to Use

1. Use Windows Search to search for "Powershell"
2. Right click the result and Run As Administrator
3. Download this repository's contents from GitHub:
    - Either go the website [https://github.com/Logan-Meyers/Drive-Formatter](https://github.com/Logan-Meyers/Drive-Formatter) and use Code -> Download ZIP
    - Or click this direct download link: [https://github.com/Logan-Meyers/Drive-Formatter/archive/refs/heads/main.zip](https://github.com/Logan-Meyers/Drive-Formatter/archive/refs/heads/main.zip)
4. Find the downloaded zip in your files and extract them
5. Now, with Powershell and the folder open side by side, click and drag `DriveFormatter.ps1` into the Powershell window
6. In the Powershell Window, press enter and the program's instructions to manage your drives as needed.

# Functionality

Top-level (user) functionality:
- Check if a USB Drive is connected is formatted properly for use in a CNC Machine
- Format a USB Drive properly with a custom name

Low-level (script) functionality
- Use the Windows Powershell module Storage to manage drives
- can create a partition of 2GB on any drive, but no less or more (hard-coded)

# Future Plans

- Allow custom 1st partition size (Up to 2GB, free space available, or user-specified)
- Allow creating a partition of the remaining size for other use
- Allow renaming of a partition
- Allow copying all files off of partition before formatting, and move back after formatting
- Make cross-platform (Windows & MacOS)
