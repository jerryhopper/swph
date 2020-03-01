#!/bin/bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken

set -e


generate_post_data()
{
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
  POSTDATA = cat <<EOF
{"MID":"$MID","MAC":"$MAC","MEA":"$MEA","MEU":"$MEU","SDS":"$SDS","FPU":"$FPU","FSU":"$FSU","CPH":"$CPH","CPI":"$CPI","CPP":"$CPP","CPA":"$CPA","DTE":"$DTE","CPR":"$CPR"}
EOF
}

echo "automation_custom_prescript has started">/boot/log.txt

if [ -f "/etc/blackbox/blackbox.conf" ]; then
  source "/etc/blackbox/blackbox.conf"
  echo "$POSTDATA">/etc/blackbox/hardware.json
  echo $(echo -n "$POSTDATA"|openssl dgst -sha256|cut -d' ' -f 2) >/etc/blackbox/blackbox.id
  echo "1" > /etc/blackbox/blackbox.state
else
  echo "0" > /etc/blackbox/blackbox.state
  echo "/etc/blackbox/blackbox.conf doesnt exist.">>/boot/log.txt
fi


echo "automation_custom_prescript has ended">/boot/log.txt
