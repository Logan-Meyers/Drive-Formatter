import curses
import diskpart_funcs
import os
import sys
import ctypes

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAdmin() == 1
    except:
        return False

def run_as_admin():
    if not is_admin():
        # Relaunch the script with admin privileges
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)

def main():
    run_as_admin()

    curses.wrapper(main_menu)

def main_menu(stdscr: curses.window):
    stdscr.clear()

    menu = ["1. View Drives", "2. Format Drive", "3. Exit"]

    curses.curs_set(0)

    while True:
        # clear screen
        stdscr.clear()

        # Menu text and options
        stdscr.addstr(0, 0, "----- Main Menu -----")
        stdscr.addstr(1, 0, "Please enter a number:")

        for idx, option in enumerate(menu):
            stdscr.addstr(idx+3, 0, option)
        
        stdscr.refresh()

        # Get user input
        key = stdscr.getch()

        if key == ord('1'):
            view_drives_window(stdscr)
        elif key == ord('2'):
            option_window(stdscr, "Format Drive")
        elif key == ord('3'):
            quit()

def view_drives_window(stdscr: curses.window):
    stdscr.addstr(0, 0, "Drives connected:")
    
    drives = diskpart_funcs.list_disks()

    if drives:
        for num in range(len(drives)):
            stdscr.addstr(num+2, 0, f"{drives[0]["Disk Number"]}")
    else:
        stdscr.addstr(2, 0, "No drives!")
    
    stdscr.addstr(4, 0, "Press any key to go back.")

    _ = stdscr.getch()
        

def option_window(stdscr, option):
    stdscr.clear()
    stdscr.addstr(0, 0, f"You selected {option}. Press any key to return to the menu.")
    stdscr.refresh()
    stdscr.getch()  # Wait for user input

if __name__ == "__main__":
    main()