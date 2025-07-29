# Check if script is running from a file or from pipeline (like irm | iex)
if (-not $MyInvocation.MyCommand.Path) {
    # Running from pipeline, load dependencies from internet

    $baseUrl = "https://raw.githubusercontent.com/Logan-Meyers/Drive-Formatter/refs/heads/main/Scripts"
    $scriptsToLoad = @(
        "UI.ps1",
        "WindowsFunctions.ps1",
        "MacFunctions.ps1",
        "LinuxFunctions.ps1",
        "MainFunctions.ps1"
    )

    foreach ($script in $scriptsToLoad) {
        $scriptUrl = "$baseUrl/$script"
        Write-Host "Loading $script from internet..."
        $content = Invoke-RestMethod -Uri $scriptUrl -UseBasicParsing
        Invoke-Expression $content
        
        Write-Host "Press enter to continue..." -NoNewline
        $UserInput = $Host.UI.ReadLine()
        $UserInput
    }
}
else {
    # Running from local file, optionally dot-source local scripts
    # Import UI functions
    . "$PSScriptRoot/Scripts/UI.ps1"
    # Import OS-specific functions
    . "$PSScriptRoot/Scripts/WindowsFunctions.ps1"
    . "$PSScriptRoot/Scripts/MacFunctions.ps1"
    . "$PSScriptRoot/Scripts/LinuxFunctions.ps1"
    . "$PSScriptRoot/Scripts/MainFunctions.ps1"
}

# run main menu
Show-MainMenu