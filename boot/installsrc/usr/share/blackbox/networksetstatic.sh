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


PIHOLE_INTERFACE="eth0"
IP=$1
SUBNET=$2
GATEWAY=$3
SIZE=$4


IPV4_ADDRESS="$1/$4"



setStaticIPv4() {
    # Local, named variables
    local IFCFG_FILE
    local CONNECTION_NAME

    # If a static interface is already configured, we are done.
    if [[ -r "/etc/sysconfig/network/ifcfg-${PIHOLE_INTERFACE}" ]]; then
        if grep -q '^BOOTPROTO=.static.' "/etc/sysconfig/network/ifcfg-${PIHOLE_INTERFACE}"; then
            return 0
        fi
    fi
    # For the Debian family, if dhcpcd.conf exists,
    if [[ -f "/etc/dhcpcd.conf" ]]; then
        # configure networking via dhcpcd
        setDHCPCD
        return 0
    fi
    # If a DHCPCD config file was not found, check for an ifcfg config file based on interface name
    if [[ -f "/etc/sysconfig/network-scripts/ifcfg-${PIHOLE_INTERFACE}" ]];then
        # If it exists,
        IFCFG_FILE=/etc/sysconfig/network-scripts/ifcfg-${PIHOLE_INTERFACE}
        setIFCFG "${IFCFG_FILE}"
        return 0
    fi
    # if an ifcfg config does not exists for the interface name, try the connection name via network manager
    if is_command nmcli && nmcli general status &> /dev/null; then
        CONNECTION_NAME=$(nmcli dev show "${PIHOLE_INTERFACE}" | grep 'GENERAL.CONNECTION' | cut -d: -f2 | sed 's/^System//' | xargs | tr ' ' '_')
        if [[ -f "/etc/sysconfig/network-scripts/ifcfg-${CONNECTION_NAME}" ]];then
            # If it exists,
            IFCFG_FILE=/etc/sysconfig/network-scripts/ifcfg-${CONNECTION_NAME}
            setIFCFG "${IFCFG_FILE}"
            return 0
        fi
    fi
    # If previous conditions failed, show an error and exit
    printf "  %b Warning: Unable to locate configuration file to set static IPv4 address\\n" "${INFO}"
    exit 1
}



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


echo "$IP BlackBox">/etc/pihole/local.list
echo "$IP pi.hole">>/etc/pihole/local.list
echo "$IP blackbox.surfwijzer.nl">>/etc/pihole/local.list

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

# $PIHOLE_INTERFACE;
