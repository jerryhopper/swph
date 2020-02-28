#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

SCRIPT_FILENAME="Automation_Custom_Script"

#
#  /etc/blackbox/ dir with options.
#
#  /usr/lib/blackbox    Executable
#  /usr/sbin/blackbox   Executable
#  /usr/share/blackbox/ Dir with libraries
#

echo "Automation_Custom_Script.sh has started">>/boot/log.txt
# Custom Script (post-networking and post-DietPi install)
# - Allows you to automatically execute a custom script at the end of DietPi install.
# - Option 0 = Copy your script to /boot/Automation_Custom_Script.sh and it will be executed automatically.
# - Option 1 = Host your script online, then use e.g. AUTO_SETUP_CUSTOM_SCRIPT_EXEC=https://myweb.com/myscript.sh and it will be downloaded and executed automatically.
# - Executed script log: /var/tmp/dietpi/logs/dietpi-automation_custom_script.log

source "/etc/blackbox/blackbox.conf"

echo "2" > $BB_STATE

source "/usr/share/blackbox/func/devicelog.sh"
source "/usr/share/blackbox/func/telegram.sh"
source "/usr/share/blackbox/func/valid_ip.sh"
source "/usr/share/blackbox/func/find_ip4_information.sh"


#devicelog "Automation_Custom_Script.sh start."


# FILE=/boot/blackbox/hardware.json
# check if hardwaredata exists, then register.
if [ -f "$BB_JSON" ]; then
    # the file exists!
    echo "run 2_registerhardware" > $BB_STATE
    # this means the hardware-detect has already run.
    # we need to register the hardware in our product db
    bash /usr/share/blackbox/2_registerhardware.sh
    # remove the helper files.
else
    #telegram "EXISTS: $FILE"
    echo "no bbjson" > $BB_STATE
fi


if [[ $DEVMODE = 0 ]] ; then
  devicelog "info,rm -f /usr/share/blackbox/2_registerhardware.sh"
  rm -f /usr/share/blackbox/2_registerhardware.sh
fi




BBID=0
if [ -f "$BB_HASH" ]; then
   #telegram "EXISTS: $FILE"
   BBID=$(<$BB_HASH)
fi

find_IPv4_information

devicelog "info,$BBID,$IPV4_ADDRESS"

#  /var/tmp/dietpi/logs/dietpi-automation_custom_prescript.log
#  /var/tmp/dietpi/logs/dietpi-automation_custom_script.log

#devicelog "Automation_Custom_Script.sh end."
echo "Automation_Custom_Script.sh has ended">>/boot/log.txt


exit 0
