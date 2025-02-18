#! /bin/bash

# ...................... Variables ......................

# Pass flag variable into FLAG variable
FLAG=$1

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
    echo "  -h      Show current help message"
    echo "  -u      Show current active logged in users"
    echo "  -s      Show software name and version, including outdated software"
    echo "  -ssh    Show SSH Logins"
    echo "  -usb    Show USB Logs"
    echo "  -e      Full Analysis Mode"
    
}

everything() {
    users
    sshlogins
    processes
    software
    usbactivity
}

sshlogins () {

    head "SSH Logins:"
    # Show SSH logins on the current day

    if [[ $DISTRIBUTION == "debian" ]]
        then sshlogins=$(journalctl -u ssh --no-pager | grep "$(date "+%b %d")")
        # Check if output of command has any characters
        if [[ -n "$sshlogins" ]]
            then echo $sshlogins
        else
            # If no output from command then there are no SSH Logins
            echo "None"
        fi
    fi
}

users () {
    head "Current logged in users:"
    if [[ $DISTRIBUTION == "debian" ]]
        # Get current active users logged in
        then who | awk '{print $1}'
    fi
}

software() {

    head "Software Installed:"

    if [[ $DISTRIBUTION == "debian" ]]
        # Print package name and version for installed deb packages
        then dpkg -l --no-pager | awk '{print $2 " " $3}'
    fi

    if [[ $DISTRIBUTION == "rhelold" ]]
        # Test the one below still
        then yum list installed | awk '{print $1}'
    fi

    head "Outdated Software:"

    if [[ $DISTRIBUTION == "debian" ]]
        then apt list --upgradable
    fi

    if [[ $DISTRIBUTION == "rhelold" ]]
        # Test the one below still
        then yum check-update
    fi


}

processes () {
    head "Processes:"
    if [[ $DISTRIBUTION == "debian" ]]; then
        ps -auxf
    fi
}

usbactivity () {
    head "USB Activity:"
    if [[ $DISTRIBUTION == "debian" ]]; then
       journalctl -k | grep -i usb 
    fi
}

# ...................... Main ......................

# Give default flag to run everything mode if no flags given
if [[ "$FLAG" == "" ]]; then
    FLAG="-e"
fi

# If not help flag then
if [[ "$FLAG" != "-h" ]]; then

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

    head "Name:"
    echo "User's and Software detection script"
    head "Identified Distribution: "
    echo $DISTRIBUTION

fi

# gathers CLI argument and runs specified function
case $FLAG in
        "-h")   help;;
        "-u")   users;;
        "-s")   software;;
        "-ssh") sshlogins;;
        "-e")   everything;;
        "-p")   processes;;
        "-usb") usbactivity;;
esac