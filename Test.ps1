function Show-MainMenu {
    do {
        if ($IsMacOS) { Write-Host "You're on Mac!" }
        else {
            if ($isLinux) { Write-Host "You're on Linux!" }
            else { Write-Host "You're on Windows!" }
        }

        Write-Host "Welcome! Enter 'Q' to quit!"
        $choiceKey = [System.Console]::ReadKey($true)

        Clear-Host

        switch ($choiceKey.Key) {
            'Q' {Exit}
        }
    } while ($true)
}

Show-MainMenu
