#! /bin/bash

# ...................... Variables ......................



# ...................... Functions ......................

# Function to color code echo
head () {
    echo -e "\e[1;34m$1\e[0m"
}

# Fucntion to return true if a command exists
distribution_check () {
    if [[ $(command -v "$1")  ]]
        then echo "true"
    fi
}

# Function to display info about the script
help () {
    echo
    head "Description:"
    echo "Bash Script to gather active users, software, outdated software, and identify USB history"
    echo
    head "Options:"
    echo "  -h  Show current help message"
    echo 
}

users () {

    if [[ DISTRIBUTION == "debian" ]] {
        # Get current active users logged in
        who | awk '{print $1}'
    }
    
}


# ...................... Main ......................


# If not help flag then
if [[ "$1" != "-h" ]]; then

    # If user running as root continue
    if [ "$EUID" -ne 0 ]; then
        echo "Run as root, please!"
        exit 1
    fi

    # Identify Linux Distro
    if [[ $(distribution_check "apt-get") == "true" ]]
        then DISTRIBUTION="debian"
    elif [[ $(distribution_check "yum") == "true" ]]
        then DISTRIBUTION="rhelold"
    elif [[ $(distribution_check "dnf") == "true" ]]
        then DISTRIBUTION="rhelnew"
    elif [[ $(distribution_check "pacman") == "true" ]]
        then DISTRIBUTION="arch"
    fi

    echo
    head "Name:"
    echo "User's and Software detection script"
    head "Identified Distribution: "
    echo $DISTRIBUTION
    echo

fi

# gathers CLI argument and runs specified function
case $1 in
        "-h")   help;;
        "-u")   users;;
        "-s")   software;;
esac