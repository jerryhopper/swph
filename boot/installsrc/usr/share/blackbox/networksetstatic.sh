#!/usr/bin/bash

source /usr/share/blackbox/func/valid_ip.sh
# set ip static

set -e

if  ! valid_ip "$1" ; then
  echo "invalid ip ($1)"
  exit 1
fi

if  ! valid_ip "$2" ; then
  echo "invalid subnet ($2)"
  exit 1
fi

if  ! valid_ip "$3" ; then
  echo "invalid gateway ($3)"
  exit 1
fi

IP=$1
SUBNET=$2
GATEWAY=$3
SIZE=$4


IPV4_ADDRESS="$1/$4"

piholesetupvarsconf(){
    echo "PIHOLE_INTERFACE=eth0" >/etc/pihole/setupVars.conf
    #echo "IPV4_ADDRESS=10.0.1.207/24" >>/etc/pihole/setupVars.conf
    echo "IPV4_ADDRESS=$IPV4_ADDRESS" >>/etc/pihole/setupVars.conf
    echo "IPV6_ADDRESS=" >>/etc/pihole/setupVars.conf
    echo "PIHOLE_DNS_1=8.8.8.8" >>/etc/pihole/setupVars.conf
    echo "PIHOLE_DNS_2=8.8.4.4" >>/etc/pihole/setupVars.conf
    echo "QUERY_LOGGING=false" >>/etc/pihole/setupVars.conf
    echo "INSTALL_WEB_SERVER=true" >>/etc/pihole/setupVars.conf
    echo "INSTALL_WEB_INTERFACE=true" >>/etc/pihole/setupVars.conf
    echo "LIGHTTPD_ENABLED=true" >>/etc/pihole/setupVars.conf
    echo "BLOCKING_ENABLED=true" >>/etc/pihole/setupVars.conf
    echo "DNSMASQ_LISTENING=single" >>/etc/pihole/setupVars.conf
    echo "DNS_FQDN_REQUIRED=true" >>/etc/pihole/setupVars.conf
    echo "DNS_BOGUS_PRIV=true" >>/etc/pihole/setupVars.conf
    #echo "DNSSEC=true" >>/etc/pihole/setupVars.conf
    echo "TEMPERATUREUNIT=C" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING=true" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_IP=10.0.1.1" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_DOMAIN=localdomain" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_REVERSE=1.0.10.in-addr.arpa" >>/etc/pihole/setupVars.conf
    echo "WEBPASSWORD=84ea6bece4df810e8a3d53ba0e6c5ff9cdc5c25ddd2d8b6ad5c5e009015c3e54" >>/etc/pihole/setupVars.conf

}





echo "$IP">/etc/blackbox/.staticip

piholesetupvarsconf
#echo "$1 $2 $3"

#exit 0

echo  "# Location: /etc/network/interfaces ">/etc/network/interfaces
echo  "# Please modify network settings via: dietpi-config">>/etc/network/interfaces
echo  "# Or create your own drop-ins in: /etc/network/interfaces.d/">>/etc/network/interfaces
echo  " ">>/etc/network/interfaces
echo  "# Drop-in configs">>/etc/network/interfaces
echo  "source interfaces.d/*">>/etc/network/interfaces
echo  " ">>/etc/network/interfaces
echo  "# Loopback">>/etc/network/interfaces
echo  "auto lo">>/etc/network/interfaces
echo  "iface lo inet loopback">>/etc/network/interfaces
echo  " ">>/etc/network/interfaces
echo  "# Ethernet">>/etc/network/interfaces
echo  "allow-hotplug eth0">>/etc/network/interfaces
echo  "iface eth0 inet static">>/etc/network/interfaces
echo  "address $IP">>/etc/network/interfaces
echo  "netmask $SUBNET">>/etc/network/interfaces
echo  "gateway $GATEWAY">>/etc/network/interfaces
echo  "#dns-nameservers 8.8.8.8 8.8.4.4">>/etc/network/interfaces
echo  " ">>/etc/network/interfaces
echo  "# WiFi">>/etc/network/interfaces
echo  "#allow-hotplug wlan0">>/etc/network/interfaces
echo  "iface wlan0 inet dhcp">>/etc/network/interfaces
echo  "address 192.168.0.100">>/etc/network/interfaces
echo  "netmask 255.255.255.0">>/etc/network/interfaces
echo  "gateway 192.168.0.1">>/etc/network/interfaces
echo  "wireless-power off">>/etc/network/interfaces
echo  "wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf">>/etc/network/interfaces
echo  "#dns-nameservers 8.8.8.8 8.8.4.4">>/etc/network/interfaces



echo "ok"
