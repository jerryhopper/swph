#!/usr/bin/bash

# set network to dhcp
echo "ok"
exit 0

# dhcpd

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
echo  "iface eth0 inet dhcp">>/etc/network/interfaces
echo  "address 192.168.0.100">>/etc/network/interfaces
echo  "netmask 255.255.255.0">>/etc/network/interfaces
echo  "gateway 192.168.0.1">>/etc/network/interfaces
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


