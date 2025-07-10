#!/bin/bash

# Function to read user input without a newline
read_colonless() {
    read -p "$1" user_input
    echo "$user_input"
}

# Function to get the wanted drive
get_wanted_drive() {
    action_prompt=$1
    drives=($(diskutil list | grep '^/dev/' | awk '{print $1}'))  # Get list of drives
    max_selection=${#drives[@]}

    if [ $max_selection -eq 0 ]; then
        echo "No drives found."
        return 1
    fi

    selected=0

    while true; do
        clear
        echo "Use arrow keys to change which drive you'd like to $action_prompt"
        echo "Press enter to select the drive and continue"
        echo "Press escape to go back to the main menu"
        echo ""

        for i in "${!drives[@]}"; do
            if [ $i -eq $selected ]; then
                echo "> ${drives[$i]}"
            else
                echo "  ${drives[$i]}"
            fi
        done

        # Read user input
        read -rsn1 key  # Read a single character
        case "$key" in
            $'\e[A')  # Up arrow
                if [ $selected -gt 0 ]; then
                    selected=$((selected - 1))
                fi
                ;;
            $'\e[B')  # Down arrow
                if [ $selected -lt $((max_selection - 1)) ]; then
                    selected=$((selected + 1))
                fi
                ;;
            '')  # Enter key
                echo "${drives[$selected]}"
                return 0
                ;;
            $'\e')  # Escape key
                return 1
                ;;
        esac
    done
}

# Function to check the drive
show_check_menu() {
    chosen_drive=$(get_wanted_drive "check")
    if [ $? -ne 0 ]; then
        return
    fi

    clear
    echo "You have selected Drive $chosen_drive"
    
    # Check the partition type and offset
    partition_info=$(diskutil info "$chosen_drive")
    partition_type=$(echo "$partition_info" | grep "File System Personality" | awk '{print $NF}')
    partition_offset=$(echo "$partition_info" | grep "Device Block Size" | awk '{print $NF}')

    # Check for FAT type and offset
    if [[ "$partition_type" == "FAT32" && "$partition_offset" == "1024" ]]; then
        echo "Formatted correctly!"
    else
        echo "Not formatted correctly!"
        echo "You'll need to format this drive from the main menu."
        echo ""
        if [[ "$partition_type" != "FAT32" ]]; then
            echo "- Wrong partition type: $partition_type"
        fi
        if [[ "$partition_offset" != "1024" ]]; then
            echo "- Wrong Offset: $partition_offset"
        fi
    fi

    echo ""
    read_colonless "Press enter to continue back to main menu..."
}

# Function to format the drive
show_format_menu() {
    chosen_drive=$(get_wanted_drive "format")
    if [ $? -ne 0 ]; then
        return
    fi

    clear
    echo "You have selected Drive $chosen_drive"
    echo "Are you sure you want to format this disk?"
    echo "This will DELETE ALL DATA. Backup important files if needed."
    echo ""
    read -p "(y/N): " confirmation

    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        clear
        echo "Formatting Cancelled."
        echo ""
        return
    fi

    # Clear the disk
    diskutil eraseDisk FAT32 NEWDRIVE "$chosen_drive"

    echo "Successfully formatted drive! It is all ready to be used."
    echo ""
    read_colonless "Press enter to continue back to main menu..."
}

# Main menu function
show_main_menu() {
    while true; do
        clear
        echo "Welcome! Please select an option below by typing a number:"
        echo ""
        echo "1. Check a Drive"
        echo "2. Format a Drive"
        echo "3. Exit"
        echo ""
        read -p "Enter your choice (1-3): " choice

        case "$choice" in
            1) show_check_menu ;;
            2) show_format_menu ;;
            3) exit ;;
            *) echo "Please choose a number in the range 1-3" ;;
        esac
    done
}

# Start the main menu
show_main_menu