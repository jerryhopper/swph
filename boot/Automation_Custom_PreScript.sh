#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e
echo "automation_custom_prescript has started">>/boot/log.txt

# Custom Script (pre-networking and pre-DietPi install)
# - Allows you to automatically execute a custom script before network is up on first boot.
# - Copy your script to /boot/Automation_Custom_PreScript.sh and it will be executed automatically.
# - Executed script log: /var/tmp/dietpi/logs/dietpi-automation_custom_prescript.log

FILE=/boot/blackbox/1_hardwaredetect.sh
if [ -f "$FILE" ]; then
    # the file exists!
    # run hardware detection and create hardware.json & hardware.hash
    #echo "$FILE exist"
    bash /boot/blackbox/1_hardwaredetect.sh
    # after the hardwaretest, remove the script.
    rm -f /boot/blackbox/1_hardwaredetect.sh
fi

echo "automation_custom_prescript has ended">>/boot/log.txt

