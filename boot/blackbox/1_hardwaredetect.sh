#!/bin/bash

# shellcheck disable=SC1090

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e


source "/boot/blackbox/blackbox.conf"





echo "1_hardwaredetect.sh has started">>/boot/log.txt
######## VARIABLES #########
# For better maintainability, we store as much information that can change in variables
# This allows us to make a change in one place that can propagate to all instances of the variable
# These variables should all be GLOBAL variables, written in CAPS
# Local variables will be in lowercase and will exist only within functions
# It's still a work in progress, so you may see some variance in this guideline until it is complete



### GET DEVICE/SETUP SPECIFIC VALUES ###
MID=$(cat /etc/machine-id)
MAC=$(ip addr show eth0|grep "ether"|cut -d' ' -f 6)
MEMALL=$(cat /proc/meminfo|grep -m 1 "MemTotal"|cut -d' ' -f 2-);
MEA=$(echo $MEMALL|cut -d' ' -f 1)
MEU=$(echo $MEMALL|cut -d' ' -f 2)
SDS=$(udevadm info --query=all --name=/dev/mmcblk0p1|grep ID_SERIAL|cut -d'=' -f 2)
FPU=$(udevadm info --query=all --name=/dev/mmcblk0p1|grep ID_PART_TABLE_UUID|cut -d'=' -f 2)
FSU=$(udevadm info --query=all --name=/dev/mmcblk0p1|grep -m 1 ID_FS_UUID|cut -d'=' -f 2)
CPH=$(cat /proc/cpuinfo |grep -m 1 "Hardware"|cut -d' ' -f 2)
CPI=$(cat /proc/cpuinfo |grep -m 1 "CPU implementer"|cut -d' ' -f 3)
CPP=$(cat /proc/cpuinfo |grep -m 1 "Processor"|cut -d' ' -f 2-6)
CPA=$(cat /proc/cpuinfo |grep -m 1 "CPU architecture"|cut -d' ' -f 3)
CPR=$(cat /proc/cpuinfo |grep -m 1 "CPU revision"|cut -d' ' -f 3)
DTE=$(date)


generate_post_data()
{
  cat <<EOF
{"MID":"$MID","MAC":"$MAC","MEA":"$MEA","MEU":"$MEU","SDS":"$SDS","FPU":"$FPU","FSU":"$FSU","CPH":"$CPH","CPI":"$CPI","CPP":"$CPP","CPA":"$CPA","DTE":"$DTE","CPR":"$CPR"}
EOF
}

### CREATE JSON ###
POSTDATA=$(generate_post_data)
### CREATE HASH OF THE JSON
HARDWAREHASH=$(echo -n "$POSTDATA"|openssl dgst -sha256|cut -d' ' -f 2)

# here we write the results of the hardwaretests to a file.
echo  $POSTDATA>$TMP_POSTDATA
echo  $HARDWAREHASH>$TMP_POSTDATAHASH

echo "1_hardwaredetect.sh has ended">>/boot/log.txt
