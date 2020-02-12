#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "automation_custom_script.sh has started">>/boot/log.txt
# Custom Script (post-networking and post-DietPi install)
# - Allows you to automatically execute a custom script at the end of DietPi install.
# - Option 0 = Copy your script to /boot/Automation_Custom_Script.sh and it will be executed automatically.
# - Option 1 = Host your script online, then use e.g. AUTO_SETUP_CUSTOM_SCRIPT_EXEC=https://myweb.com/myscript.sh and it will be downloaded and executed automatically.
# - Executed script log: /var/tmp/dietpi/logs/dietpi-automation_custom_script.log

telegram()
{
   local VARIABLE=${1}
   apiToken=447794744:AAGrNj3vyDgH5BU_dxQqfDQjgIgeN250Q04
   chatId=-1001402917482
   curl -s -X POST https://api.telegram.org/bot$apiToken/sendMessage -d text="Automation_Custom_Script.sh : $VARIABLE" -d chat_id=$chatId >/dev/null
}
telegram() "Check"





#echo  $HARDWAREHASH>/var/log/sinit.log
#echo  $POSTDATA>/boot/blackbox/hardware.json
#echo  $HARDWAREHASH>/boot/blackbox/hardware.hash


FILE=/boot/blackbox/hardware.json
if [ -f "$FILE" ]; then
    # the file exists!
    # this means the hardware-detect has already run.
    # we need to register the hardware in our product db
    bash /boot/blackbox/2_registerhardware.sh
fi
