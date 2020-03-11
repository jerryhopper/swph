#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
#set -e
#SCRIPT_FILENAME="Automation_Custom_Script"
#echo "Automation_Custom_Script.sh has started">>/boot/log.txt

curl -sSL https://raw.githubusercontent.com/jerryhopper/osbox/master/advanced/installation.sh | bash

osbox install


# A function to clone a repo
#make_repo() {
#    # Set named variables for better readability
#    local directory="${1}"
#    local remoteRepo="${2}"
#    # The message to display when this function is running
#    str="Clone ${remoteRepo} into ${directory}"
#    # Display the message and use the color table to preface the message with an "info" indicator
#    printf "  %b %s..." "${INFO}" "${str}"
#    # If the directory exists,
#    if [[ -d "${directory}" ]]; then
#        # delete everything in it so git can clone into it
#        rm -rf "${directory}"
#    fi
#    # Clone the repo and return the return code from this command
#    git clone -q --depth 20 "${remoteRepo}" "${directory}" &> /dev/null || return $?
#    # Show a colored message showing it's status
#    printf "%b  %b %s\\n" "${OVER}" "${TICK}" "${str}"
#    # Always return 0? Not sure this is correct
#    return 0
#}

#if [ ! -d /usr/local/osblackbox ]; then
#  make_repo /usr/local/osblackbox https://
#fi

#if [ -f "/etc/blackbox/blackbox.conf" ]; then
#  source "/etc/blackbox/blackbox.conf"
#  echo "/etc/blackbox/blackbox.conf exists">>/boot/log.txt
#  if [ ! -f "/usr/sbin/blackbox" ]; then
#    #if [ "$DEVMODE" == "1"]; then
#    echo "Creating symbolic link /usr/sbin blackbox">>/boot/log.txt
#    ln -s /boot/installsrc/usr/sbin/blackbox /usr/sbin
#    chmod +x /boot/installsrc/usr/sbin/blackbox
#    fi
#  fi
#  echo "Running /usr/sbin/blackbox">>/boot/log.txt
#  /usr/sbin/blackbox install
#else
#  echo "/etc/blackbox/blackbox.conf doesnot exist ">>/boot/log.txt
#fi
#echo "Automation_Custom_Script.sh has ended">>/boot/log.txt
#exit 0
