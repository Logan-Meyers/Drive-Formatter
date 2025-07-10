GitHub: https://github.com/MScholtes/PS2EXE

In Powershell, admin:
`Install-Module ps2exe`

To Convert my script:
`ps2exe .\DriveFormatter.ps1 .\DriveFormatter.exe -requireAdmin -iconFile "USB_Icon.ico" -x64 -MTA`