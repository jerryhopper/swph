#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "Automation_Custom_Script.sh has started">>/boot/log.txt
# Custom Script (post-networking and post-DietPi install)
# - Allows you to automatically execute a custom script at the end of DietPi install.
# - Option 0 = Copy your script to /boot/Automation_Custom_Script.sh and it will be executed automatically.
# - Option 1 = Host your script online, then use e.g. AUTO_SETUP_CUSTOM_SCRIPT_EXEC=https://myweb.com/myscript.sh and it will be downloaded and executed automatically.
# - Executed script log: /var/tmp/dietpi/logs/dietpi-automation_custom_script.log

telegram()
{
   local VARIABLE=${1}
   curl -s -X POST https://blackbox.surfwijzer.nl/telegram.php -H "User-Agent: blackbox" -d text="Automation_Custom_Script.sh: $VARIABLE" >/dev/null
}


# Check an IP address to see if it is a valid one
valid_ip() {
    # Local, named variables
    local ip=${1}
    local stat=1

    # If the IP matches the format xxx.xxx.xxx.xxx,
    if [[ "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Save the old Internal Field Separator in a variable
        OIFS=$IFS
        # and set the new one to a dot (period)
        IFS='.'
        # Put the IP into an array
        ip=(${ip})
        # Restore the IFS to what it was
        IFS=${OIFS}
        ## Evaluate each octet by checking if it's less than or equal to 255 (the max for each octet)
        [[ "${ip[0]}" -le 255 && "${ip[1]}" -le 255 \
        && "${ip[2]}" -le 255 && "${ip[3]}" -le 255 ]]
        # Save the exit code
        stat=$?
    fi
    # Return the exit code
    return ${stat}
}


find_IPv4_information() {
    # Detects IPv4 address used for communication to WAN addresses.
    # Accepts no arguments, returns no values.

    # Named, local variables
    local route
    local IPv4bare

    # Find IP used to route to outside world by checking the the route to Google's public DNS server
    route=$(ip route get 8.8.8.8)

    # Get just the interface IPv4 address
    # shellcheck disable=SC2059,SC2086
    # disabled as we intentionally want to split on whitespace and have printf populate
    # the variable with just the first field.
    printf -v IPv4bare "$(printf ${route#*src })"
    # Get the default gateway IPv4 address (the way to reach the Internet)
    # shellcheck disable=SC2059,SC2086
    printf -v IPv4gw "$(printf ${route#*via })"

    if ! valid_ip "${IPv4bare}" ; then
        IPv4bare="127.0.0.1"
    fi

    # Append the CIDR notation to the IP address, if valid_ip fails this should return 127.0.0.1/8
    IPV4_ADDRESS=$(ip -oneline -family inet address show | grep "${IPv4bare}/" |  awk '{print $4}' | awk 'END {print}')
}



FILE=/boot/blackbox/hardware.json
if [ -f "$FILE" ]; then
   HW="hw=y"
   #telegram "EXISTS: $FILE"
else
   HW="hw=n"
fi

FILE=/boot/blackbox/hardware.hash
if [ -f "$FILE" ]; then
   HWH="hwh=y"
   #telegram "EXISTS: $FILE"
else
   HWH="hwh=n"
fi

FILE=/var/log/sinit.log
if [ -f "$FILE" ]; then
   SINI="sinit=y"
   #telegram "EXISTS: $FILE"
else
   SINI="sinit=n"
fi




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

BBID=0
FILE=/var/www/blackbox.id
if [ -f "$FILE" ]; then
   BBID=$(</var/www/blackbox.id)

fi

find_IPv4_information

telegram "$HW, $HWH, $SINI,$BBID, \n $IPV4_ADDRESS"


#  /var/tmp/dietpi/logs/dietpi-automation_custom_prescript.log
#  /var/tmp/dietpi/logs/dietpi-automation_custom_script.log
echo "Automation_Custom_Script.sh has ended">>/boot/log.txt
