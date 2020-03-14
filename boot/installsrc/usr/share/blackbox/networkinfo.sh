#!/bin/bash

if [  -f '/usr/share/blackbox/func/networktools.sh' ] ; then
  source /usr/share/blackbox/func/networktools.sh
else
  source /boot/installsrc/usr/share/blackbox/func/networktools.sh
fi


PRIM=$(ip addr show eth0|grep "scope global"|awk  '{print $2}')
SEC=$(ip addr show eth0|grep "scope global secondary"|awk  '{print $2}')



find_IPv4_information


echo "$PRIM,$SEC|$IPv4gw"
