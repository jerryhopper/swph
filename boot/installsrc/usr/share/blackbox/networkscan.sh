#!/bin/bash

if [  -f '/usr/share/blackbox/func/networktools.sh' ] ; then
  source /usr/share/blackbox/func/networktools.sh
else
  source /boot/installsrc/usr/share/blackbox/func/networktools.sh
fi


find_IPv4_information

nmap -sn $IPV4_ADDRESS -oG -|grep Host|awk '{print $2}'

