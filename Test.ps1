function Show-MainMenu {
    do {
        if ($IsMacOS) { Write-Host "You're on Mac!" }
        if ($IsWindows) { Write-Host "You're on Windows!" }

        Write-Host "Welcome! Enter 'Q' to quit!"
        $choiceKey = [System.Console]::ReadKey($true)

        Clear-Host

        switch ($choiceKey.Key) {
            'Q' {Exit}
        }
    } while ($true)
}

Show-MainMenu
